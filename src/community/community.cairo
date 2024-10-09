#[starknet::component]
pub mod CommunityComponent {
    // *************************************************************************
    //                            IMPORT
    // *************************************************************************
    use core::traits::TryInto;
    use starknet::{
        ContractAddress, get_caller_address, get_block_timestamp, contract_address_const, ClassHash,
        syscalls::deploy_syscall, SyscallResultTrait,
        storage::{
            StoragePointerWriteAccess, StoragePointerReadAccess, Map, StorageMapReadAccess,
            StorageMapWriteAccess
        }
    };
    use karst::interfaces::ICommunity::ICommunity;
    use karst::interfaces::ICommunityNft::{ICommunityNftDispatcher, ICommunityNftDispatcherTrait};
    use karst::base::constants::types::{
        CommunityDetails, GateKeepType, CommunityType, CommunityMember, CommunityGateKeepDetails
    };
    use karst::base::constants::errors::Errors::{ALREADY_MEMBER, NOT_COMMUNITY_OWNER, NOT_MEMBER, BANNED_MEMBER, UNAUTHORIZED, ONLY_PREMIUM_COMMUNITIES};


    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    pub struct Storage {
        community_owner: Map<u256, ContractAddress>, // map<owner_address, community_id>
        communities: Map<u256, CommunityDetails>, // map <community_id, community_details>
        member_community_id: Map<ContractAddress, u256>, // map <member address, community id>
        community_member: Map<(u256, ContractAddress), CommunityMember>, // map<(community_id, member address), Member_details>
        community_mod: Map<(u256, ContractAddress), bool>, // map <(community id, mod_address), bool>
        community_gate_keep: Map<u256, CommunityGateKeepDetails>, // map <community, CommunityGateKeepDetails>
        gate_keep_permissioned_addresses: Map<(u256, ContractAddress), bool>, // map <(u256, ContractAddress), bool>,
        community_nft_classhash: ClassHash,
        community_counter: u256,
    }

    // *************************************************************************
    //                            EVENT
    // *************************************************************************
    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        CommunityCreated: CommunityCreated,
        JoinedCommunity: JoinedCommunity,
        LeftCommunity: LeftCommunity,
        CommunityModAdded: CommunityModAdded,
        CommunityBanStatusUpdated: CommunityBanStatusUpdated,
        CommunityModRemoved: CommunityModRemoved,
        CommunityUpgraded: CommunityUpgraded,
        CommunityGatekeeped: CommunityGatekeeped,
        DeployedCommunityNFT: DeployedCommunityNFT
    }

    #[derive(Drop, starknet::Event)]
    pub struct CommunityCreated {
        pub community_id: u256,
        pub community_owner: ContractAddress,
        pub community_nft_address: ContractAddress,
        pub block_timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct JoinedCommunity {
        community_id: u256,
        transaction_executor: ContractAddress,
        token_id: u256,
        profile: ContractAddress,
        block_timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct LeftCommunity {
        community_id: u256,
        transaction_executor: ContractAddress,
        token_id: u256,
        profile: ContractAddress,
        block_timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct CommunityModAdded {
        pub community_id: u256,
        pub transaction_executor: ContractAddress,
        pub mod_address: ContractAddress,
        pub block_timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct CommunityModRemoved {
        pub community_id: u256,
        pub transaction_executor: ContractAddress,
        pub mod_address: ContractAddress,
        pub block_timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct CommunityBanStatusUpdated {
        pub community_id: u256,
        pub transaction_executor: ContractAddress,
        pub profile: ContractAddress,
        pub ban_status: bool,
        pub block_timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct CommunityUpgraded {
        pub community_id: u256,
        pub transaction_executor: ContractAddress,
        pub premiumType: CommunityType,
        pub block_timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct CommunityGatekeeped {
        pub community_id: u256,
        pub transaction_executor: ContractAddress,
        pub gatekeepType: GateKeepType,
        pub block_timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct DeployedCommunityNFT {
        pub community_id: u256,
        pub community_nft: ContractAddress,
        pub block_timestamp: u64,
    }

    // *************************************************************************
    //                            EXTERNAL FUNCTIONS
    // *************************************************************************
    #[embeddable_as(KarstCommunity)]
    impl CommunityImpl<
        TContractState, +HasComponent<TContractState>
    > of ICommunity<ComponentState<TContractState>> {
        // TODO: Enforce gatekeeping
        /// @notice creates a new community
        fn create_comminuty(ref self: ComponentState<TContractState>, community_type: CommunityType) -> u256 {
            let community_owner = get_caller_address();
            let community_counter = self.community_counter.read();
            let community_nft_classhash = self.community_nft_classhash.read();
            let community_id = community_counter + 1;

            let community_nft_address = self
                ._deploy_community_nft(community_id, community_nft_classhash, community_id.try_into().unwrap());  // use community_id as salt since its unique

            // write to storage
            let community_details = CommunityDetails {
                community_id: community_id,
                community_owner: community_owner,
                community_metadata_uri: "",
                community_nft_address: community_nft_address,
                community_premium_status: false,
                community_total_members: 0,
                community_type: CommunityType::Free,
            };

            let gate_keep_details = CommunityGateKeepDetails {
                community_id: community_id,
                gate_keep_type: GateKeepType::None,
                community_nft_address: contract_address_const::<0>(),
                entry_fee: 0
            };

            self.communities.write(community_id, community_details);
            self.community_owner.write(community_id, community_owner);
            self.community_gate_keep.write(community_id, gate_keep_details);
            self.community_counter.write(community_counter + 1);

            // upgrade if community type is not free
            if(community_type != CommunityType::Free) {
                self._upgrade_community(community_id, community_type);
            }

            // emit event
            self
                .emit(
                    CommunityCreated {
                        community_id: community_id,
                        community_owner: community_owner,
                        community_nft_address: community_nft_address,
                        block_timestamp: get_block_timestamp()
                    }
                );
            community_id
        }

        /// @notice adds a new user to a community
        /// @param profile user who wants to join community
        /// @param community_id id of community to be joined
        fn join_community(
            ref self: ComponentState<TContractState>, profile: ContractAddress, community_id: u256
        ) {
            let community = self.communities.read(community_id);

            // check user is not already a member and wasn't previously banned
            let is_community_member = self.is_community_member(profile, community_id);
            let is_banned = self.get_ban_status(profile, community_id);
            assert(is_community_member != true, ALREADY_MEMBER);
            assert(is_banned != true, BANNED_MEMBER);

            // mint a community token to new joiner
            let minted_token_id = self._mint_community_nft(profile, community.community_nft_address);

            let community_member = CommunityMember {
                profile_address: profile,
                community_id: community_id,
                total_publications: 0,
                community_token_id: minted_token_id,
                ban_status: false
            };

            // update storage
            self.community_member.write((community_id, profile), community_member);
            let community_total_members = community.community_total_members + 1;
            let updated_community = CommunityDetails {
                community_total_members: community_total_members, ..community
            };
            self.communities.write(community_id, updated_community);

            // emit event
            self.emit(
                JoinedCommunity {
                    community_id: community_id,
                    transaction_executor: get_caller_address(),
                    token_id: minted_token_id,
                    profile: profile,
                    block_timestamp: get_block_timestamp(),
                }
            );
        }

        /// @notice removes a member from a community
        /// @param profile user who wants to leave the community
        /// @param community_id id of community to be left
        fn leave_community(
            ref self: ComponentState<TContractState>, profile: ContractAddress, community_id: u256
        ) {
            let community = self.communities.read(community_id);
            let community_member_details = self.community_member.read((community_id, profile));

            let is_community_member = self.is_community_member(profile, community_id);
            assert(is_community_member == true, NOT_MEMBER);

            // remove member details and update storage
            let updated_member_details = CommunityMember {
                profile_address: contract_address_const::<0>(),
                community_id: 0,
                total_publications: 0,
                community_token_id: 0,
                ban_status: true
            };
            self.community_member.write((community_id, profile), updated_member_details);
            let community_total_members = community.community_total_members - 1;
            let updated_community = CommunityDetails {
                community_total_members: community_total_members, ..community
            };
            self.communities.write(community_id, updated_community);
            
            // burn user's community token
            self
                ._burn_community_nft(
                    community.community_nft_address, community_member_details.community_token_id
                );

            // emit event
            self.emit(
                LeftCommunity {
                    community_id: community_id,
                    transaction_executor: get_caller_address(),
                    token_id: community_member_details.community_token_id,
                    profile: profile,
                    block_timestamp: get_block_timestamp(),
                }
            );
        }

        /// @notice set community metadata uri
        /// @param community_id id of community to update metadata for
        /// @param metadata_uri uri to be set
        fn set_community_metadata_uri(
            ref self: ComponentState<TContractState>, community_id: u256, metadata_uri: ByteArray
        ) {
            let community_owner = self.community_owner.read(community_id);
            assert(community_owner == get_caller_address(), NOT_COMMUNITY_OWNER);

            let community_details = self.communities.read(community_id);
            let updated_community = CommunityDetails {
                community_metadata_uri: metadata_uri, ..community_details
            };
            self.communities.write(community_id, updated_community);
        }

        // TODO: MAKE IT RECEIVE AN ARRAY OF MODERATORS
        /// @notice adds a new community mod
        /// @param community_id id of community to add moderator
        /// @param moderator address to be added as moderator
        fn add_community_mods(
            ref self: ComponentState<TContractState>, community_id: u256, moderator: ContractAddress
        ) {
            let community_owner = self.community_owner.read(community_id);
            assert(community_owner == get_caller_address(), NOT_COMMUNITY_OWNER);

            // Mod must first be a member of the community
            let is_community_member = self.is_community_member(moderator, community_id);
            assert(is_community_member == true, NOT_MEMBER);

            // update storage
            self.community_mod.write((community_id, moderator), true);

            // emit event
            self
                .emit(
                    CommunityModAdded {
                        community_id: community_id,
                        transaction_executor: community_owner,
                        mod_address: moderator,
                        block_timestamp: get_block_timestamp()
                    }
                );
        }

        // TODO: MAKE IT RECEIVE AN ARRAY OF MODERATORS
        /// @notice removes a new community mod
        /// @param community_id id of community to remove moderator
        /// @param moderator address to be removed as moderator
        fn remove_community_mods(
            ref self: ComponentState<TContractState>, community_id: u256, moderator: ContractAddress
        ) {
            let community_owner = self.community_owner.read(community_id);
            assert(community_owner == get_caller_address(), NOT_COMMUNITY_OWNER);

            // update storage
            self.community_mod.write((community_id, moderator), false);

            // emit event
            self
                .emit(
                    CommunityModRemoved {
                        community_id: community_id,
                        mod_address: moderator,
                        transaction_executor: community_owner,
                        block_timestamp: get_block_timestamp()
                    }
                );
        }

        // TODO: MAKE IT RECEIVE AN ARRAY OF PROFILES
        /// @notice bans/unbans a user from a community
        /// @param community_id id of community
        /// @param ban_status determines wether to ban/unban
        fn set_ban_status(
            ref self: ComponentState<TContractState>,
            community_id: u256,
            profile: ContractAddress,
            ban_status: bool
        ) {
            let caller = get_caller_address();
            let is_community_mod = self.community_mod.read((community_id, caller));
            let community_owner = self.community_owner.read(community_id);

            // check caller is mod or owner
            assert(is_community_mod == true || community_owner == caller, UNAUTHORIZED);

            // check profile is a community member
            let is_community_member = self.is_community_member(profile, community_id);
            assert(is_community_member == true, NOT_MEMBER);

            // update storage
            let community_member = self.community_member.read((community_id, profile));
            let updated_member = CommunityMember { ban_status: ban_status, ..community_member };
            self.community_member.write((community_id, profile), updated_member);

            // emit event
            self
                .emit(
                    CommunityBanStatusUpdated {
                        community_id: community_id,
                        transaction_executor: caller,
                        profile: profile,
                        ban_status: ban_status,
                        block_timestamp: get_block_timestamp()
                    }
                );
        }

        /// @notice upgrades a community
        /// @param community_id id of community
        /// @param upgrade_type community type to upgrade to
        fn upgrade_community(
            ref self: ComponentState<TContractState>,
            community_id: u256,
            upgrade_type: CommunityType
        ) {
            // check community owner is caller
            let community_owner = self.communities.read(community_id).community_owner;
            assert(community_owner == get_caller_address(), NOT_COMMUNITY_OWNER);

            self._upgrade_community(community_id, upgrade_type);
        }

        /// @notice set the gatekeep rules for a community
        /// @param community_id id of community to set gatekeep rules
        /// @param gate_keep_type gatekeep rules for community
        /// @param nft_contract_address contract address of nft to be used in NFT gatekeeping
        /// @param permissioned_addresses array of addresses to set for permissioned gatekeeping
        /// @param entry_fee fee to be paid for paid gatekeeping
        fn gatekeep(
            ref self: ComponentState<TContractState>,
            community_id: u256,
            gate_keep_type: GateKeepType,
            nft_contract_address: ContractAddress,
            permissioned_addresses: Array<ContractAddress>,
            entry_fee: u256,
        ) {
            // assert caller is community owner
            let community_owner = self.community_owner.read(community_id);
            assert(community_owner == get_caller_address(), NOT_COMMUNITY_OWNER);

            // check that only premium communities can do NFTGating or PaidGating
            let community_details = self.communities.read(community_id);
            if(gate_keep_type == GateKeepType::NFTGating || gate_keep_type == GateKeepType::PaidGating){
                assert(community_details.community_premium_status == true, ONLY_PREMIUM_COMMUNITIES);
            }

            let mut community_gate_keep_details = CommunityGateKeepDetails {
                community_id: community_id,
                gate_keep_type: gate_keep_type.clone(),
                community_nft_address: nft_contract_address,
                entry_fee: entry_fee
            };

            // permissioned gatekeeping
            if(gate_keep_type == GateKeepType::PermissionedGating) {
                self._permissioned_gatekeeping(community_id, permissioned_addresses);
            }

            // write to storage
            self.community_gate_keep.write(community_id, community_gate_keep_details);

            // emit event
            self
                .emit(
                    CommunityGatekeeped {
                        community_id: community_id,
                        transaction_executor: get_caller_address(),
                        gatekeepType: gate_keep_type,
                        block_timestamp: get_block_timestamp()
                    }
                );
        }

        /// @notice gets a particular community details
        /// @param community_id id of community to be returned
        /// @return CommunityDetails details of the community
        fn get_community(
            self: @ComponentState<TContractState>, community_id: u256
        ) -> CommunityDetails {
            self.communities.read(community_id)
        }

        /// @notice gets a particular community metadata uri
        /// @param community_id id of community who's metadata is to be returned
        /// @return ByteArray metadata uri
        fn get_community_metadata_uri(
            self: @ComponentState<TContractState>, community_id: u256
        ) -> ByteArray {
            let community = self.communities.read(community_id);
            community.community_metadata_uri
        }

        /// @notice checks if a profile is a member of a community
        /// @param community_id id of community to check against
        /// @return bool true/false stating user's membership status
        fn is_community_member(
            self: @ComponentState<TContractState>, profile: ContractAddress, community_id: u256
        ) -> bool {
            let community_memeber = self.community_member.read((community_id, profile));
            if (community_memeber.community_id == community_id) {
                true
            } else {
                false
            }
        }

        /// @notice gets total members for a community
        /// @param community_id id of community to be returned
        /// @return u256 total members in the community
        fn get_total_members(self: @ComponentState<TContractState>, community_id: u256) -> u256 {
            let community = self.communities.read(community_id);
            community.community_total_members
        }

        /// @notice checks mod status for a profile
        /// @param community_id id of community to check against
        /// @return bool mod status (true/false)
        fn is_community_mod(
            self: @ComponentState<TContractState>, profile: ContractAddress, community_id: u256
        ) -> bool {
            let community_mod = self.community_mod.read((community_id, profile));

            if (community_mod) {
                true
            } else {
                false
            }
        }

        /// @notice gets ban status for a particular user
        /// @param profile profile to check ban status
        /// @param community_id id of community to be returned
        /// @return bool ban status (true/false)
        fn get_ban_status(
            self: @ComponentState<TContractState>, profile: ContractAddress, community_id: u256
        ) -> bool {
            let community_member = self.community_member.read((community_id, profile));
            community_member.ban_status
        }

        /// @notice checks if a community is upgraded or a free one
        /// @param community_id id of community to check
        /// @return (bool, communityType) premium status, and upgrade type
        fn is_premium_community(
            self: @ComponentState<TContractState>, community_id: u256
        ) -> (bool, CommunityType) {
            let community = self.communities.read(community_id);
            (community.community_premium_status, community.community_type)
        }

        /// @notice checks if a community is gatekeeped
        /// @param community_id id of community to check
        /// @return (bool, GateKeepType) gatekeep status and Gatekeep Type
        fn is_gatekeeped(
            self: @ComponentState<TContractState>, community_id: u256
        ) -> (bool, CommunityGateKeepDetails) {
            let gatekeep_details = self.community_gate_keep.read(community_id);

            if(gatekeep_details.gate_keep_type == GateKeepType::None){
                return (false, gatekeep_details);
            }

            (true, gatekeep_details)
        }
    }

    // *************************************************************************
    //                            PRIVATE FUNCTIONS
    // *************************************************************************
    #[generate_trait]
    pub impl Private<
        TContractState, +HasComponent<TContractState>
    > of PrivateTrait<TContractState> {
        /// @notice initalizes community component
        /// @param community_nft_classhash classhash of community NFT
        fn _initializer(ref self: ComponentState<TContractState>, community_nft_classhash: felt252) {
            self.community_counter.write(0);
            self.community_nft_classhash.write(community_nft_classhash.try_into().unwrap());
        }

        // TODO: JOLT UPGRADE SUBSCRIPTION
        /// @notice internal function to upgrade community
        /// @param community_id id of community to be upgraded
        /// @param upgrade_type 
        fn _upgrade_community(ref self: ComponentState<TContractState>, community_id: u256, upgrade_type: CommunityType) {
            let community = self.communities.read(community_id);

            // update storage
            let updated_community = CommunityDetails {
                community_type: upgrade_type, community_premium_status: true, ..community
            };
            self.communities.write(community_id, updated_community);

            // emit event
            let new_community_type = self.communities.read(community_id).community_type;
            self
                .emit(
                    CommunityUpgraded {
                        community_id: community_id,
                        transaction_executor: get_caller_address(),
                        premiumType: new_community_type,
                        block_timestamp: get_block_timestamp()
                    }
                );
        }

        /// @notice internal function for permissioned gatekeeping
        /// @param community_id id of community to be gatekeeped 
        fn _permissioned_gatekeeping(ref self: ComponentState<TContractState>, community_id: u256,
            permissioned_addresses: Array<ContractAddress>) {
            // for permissioned gating update array of addresses
            let length = permissioned_addresses.len();
            let mut index: u32 = 0;

            while index < length {
                self
                    .gate_keep_permissioned_addresses
                    .write((community_id, *permissioned_addresses.at(index)), true);
                index += 1;
            };
        }

        /// @notice internal function to deploy a community nft
        /// @param community_id id of community
        /// @param salt for randomization 
        fn _deploy_community_nft(
            ref self: ComponentState<TContractState>,
            community_id: u256,
            community_nft_impl_class_hash: ClassHash,
            salt: felt252
        ) -> ContractAddress {
            let mut constructor_calldata: Array<felt252> = array![
                community_id.low.into(), community_id.high.into()
            ];

            let (account_address, _) = deploy_syscall(
                community_nft_impl_class_hash, salt, constructor_calldata.span(), true
            )
                .unwrap_syscall();

            self
                .emit(
                    DeployedCommunityNFT {
                        community_id: community_id,
                        community_nft: account_address,
                        block_timestamp: get_block_timestamp()
                    }
                );
            account_address
        }

        /// @notice internal function to mint a community nft
        /// @param profile profile to be minted to
        /// @param community_nft_address address of community nft
        fn _mint_community_nft(
            ref self: ComponentState<TContractState>,
            profile: ContractAddress,
            community_nft_address: ContractAddress
        ) -> u256 {
            let token_id = ICommunityNftDispatcher { contract_address: community_nft_address }
                .mint_nft(profile);
            token_id
        }

        /// @notice internal function to burn a community nft
        /// @param community_nft_address address of community nft
        /// @param token_id to burn
        fn _burn_community_nft(
            ref self: ComponentState<TContractState>,
            community_nft_address: ContractAddress,
            token_id: u256
        ) {
            ICommunityNftDispatcher { contract_address: community_nft_address }
                .burn_nft(get_caller_address(), token_id);
        }
    }
}
