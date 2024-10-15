#[starknet::component]
pub mod CommunityComponent {
    // *************************************************************************
    //                            IMPORT
    // *************************************************************************
    use core::traits::TryInto;
    use core::num::traits::zero::Zero;
    use starknet::{
        ContractAddress, get_caller_address, get_block_timestamp, contract_address_const, ClassHash,
        syscalls::deploy_syscall, SyscallResultTrait,
        storage::{
            StoragePointerWriteAccess, StoragePointerReadAccess, Map, StorageMapReadAccess,
            StorageMapWriteAccess
        }
    };
    use openzeppelin::access::ownable::OwnableComponent;

    use karst::jolt::jolt::JoltComponent;
    use karst::interfaces::{ 
        ICommunity::ICommunity, 
        IJolt::IJolt,
        IERC721::{IERC721Dispatcher, IERC721DispatcherTrait},
        ICommunityNft::{ ICommunityNftDispatcher, ICommunityNftDispatcherTrait }
    };
    use karst::base::constants::types::{
        CommunityDetails, GateKeepType, CommunityType, CommunityMember, CommunityGateKeepDetails, JoltParams, JoltType
    };
    use karst::base::constants::errors::Errors::{
        ALREADY_MEMBER, NOT_COMMUNITY_OWNER, NOT_COMMUNITY_MEMBER, NOT_COMMUNITY_MOD, BANNED_MEMBER, UNAUTHORIZED,
        ONLY_PREMIUM_COMMUNITIES, INVALID_LENGTH
    };

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    pub struct Storage {
        community_owner: Map<u256, ContractAddress>, // map<owner_address, community_id>
        communities: Map<u256, CommunityDetails>, // map <community_id, community_details>
        community_member: Map<
            (u256, ContractAddress), CommunityMember
        >, // map<(community_id, member address), Member_details>
        community_mod: Map<
            (u256, ContractAddress), bool
        >, // map <(community id, mod_address), bool>
        community_gate_keep: Map<
            u256, CommunityGateKeepDetails
        >, // map <community, CommunityGateKeepDetails>
        gate_keep_permissioned_addresses: Map<
            (u256, ContractAddress), bool
        >, // map <(community_id, permissioned_address), bool>,
        fee_address: Map<u256, ContractAddress>, // map <community_id, fee address>
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
        pub community_id: u256,
        pub transaction_executor: ContractAddress,
        pub token_id: u256,
        pub profile: ContractAddress,
        pub block_timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct LeftCommunity {
        pub community_id: u256,
        pub transaction_executor: ContractAddress,
        pub token_id: u256,
        pub profile: ContractAddress,
        pub block_timestamp: u64,
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
        TContractState, 
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl Jolt: JoltComponent::HasComponent<TContractState>,
        impl Ownable: OwnableComponent::HasComponent<TContractState>
    > of ICommunity<ComponentState<TContractState>> {
        /// @notice creates a new community
        fn create_comminuty(
            ref self: ComponentState<TContractState>
        ) -> u256 {
            let community_owner = get_caller_address();
            let community_nft_classhash = self.community_nft_classhash.read();
            let community_id = self.community_counter.read() + 1;

            // deploy community nft - use community_id as salt since its unique
            let community_nft_address = self
                ._deploy_community_nft(
                    community_id, community_nft_classhash, community_id.try_into().unwrap()
                );

            // create community nft
            self
                ._create_community(
                    community_owner, community_nft_address, community_id
                );

            community_id
        }

        /// @notice adds a new user to a community
        /// @param profile user who wants to join community
        /// @param community_id id of community to be joined
        fn join_community(ref self: ComponentState<TContractState>, community_id: u256) {
            let profile = get_caller_address();
            let community = self.communities.read(community_id);

            // check user is not already a member and wasn't previously banned
            let (is_community_member, _) = self.is_community_member(profile, community_id);
            let is_banned = self.get_ban_status(profile, community_id);
            assert(is_community_member != true, ALREADY_MEMBER);
            assert(is_banned != true, BANNED_MEMBER);

            // enforce gatekeeping rules
            self._enforce_gatekeeping(profile, community_id);

            // join community
            self._join_community(profile, community.community_nft_address, community_id);
        }

        /// @notice removes a member from a community
        /// @param profile user who wants to leave the community
        /// @param community_id id of community to be left
        fn leave_community(ref self: ComponentState<TContractState>, community_id: u256) {
            let profile_caller = get_caller_address();
            let community = self.communities.read(community_id);
            let community_member_details = self
                .community_member
                .read((community_id, profile_caller));

            let (is_community_member, _) = self.is_community_member(profile_caller, community_id);
            assert(is_community_member == true, NOT_COMMUNITY_MEMBER);

            self
                ._leave_community(
                    profile_caller,
                    community.community_nft_address,
                    community_id,
                    community_member_details.community_token_id
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

        /// @notice adds a new community mod
        /// @param community_id id of community to add moderator
        /// @param moderator address to be added as moderator
        fn add_community_mods(
            ref self: ComponentState<TContractState>,
            community_id: u256,
            moderators: Array<ContractAddress>
        ) {
            let community_owner = self.community_owner.read(community_id);
            assert(community_owner == get_caller_address(), NOT_COMMUNITY_OWNER);

            self._add_community_mods(community_id, community_owner, moderators);
        }

        /// @notice removes a new community mod
        /// @param community_id id of community to remove moderator
        /// @param moderator address to be removed as moderator
        fn remove_community_mods(
            ref self: ComponentState<TContractState>,
            community_id: u256,
            moderators: Array<ContractAddress>
        ) {
            let community_owner = self.community_owner.read(community_id);
            assert(community_owner == get_caller_address(), NOT_COMMUNITY_OWNER);

            self._remove_community_mods(community_id, community_owner, moderators);
        }

        /// @notice bans/unbans a user from a community
        /// @param community_id id of community
        /// @param ban_status determines wether to ban/unban
        fn set_ban_status(
            ref self: ComponentState<TContractState>,
            community_id: u256,
            profiles: Array<ContractAddress>,
            ban_statuses: Array<bool>
        ) {
            let caller = get_caller_address();
            let is_community_mod = self.community_mod.read((community_id, caller));
            let community_owner = self.community_owner.read(community_id);

            // check caller is mod or owner
            assert(is_community_mod == true || community_owner == caller, UNAUTHORIZED);

            // set ban_status
            self._set_ban_status(community_id, profiles, ban_statuses);
        }

        /// @notice sets the fee address which receives community-related payments
        /// @param _fee_address address to be set
        fn set_fee_address(ref self: ComponentState<TContractState>, community_id: u256, _fee_address: ContractAddress) {
            let community_owner = self.community_owner.read(community_id);
            assert(get_caller_address() == community_owner, UNAUTHORIZED);
            self.fee_address.write(community_id, _fee_address);
        }

        /// @notice upgrades a community
        /// @param community_id id of community
        /// @param upgrade_type community type to upgrade to
        fn upgrade_community(
            ref self: ComponentState<TContractState>,
            community_id: u256,
            upgrade_type: CommunityType,
            subscription_id: u256,
            renewal_status: bool,
            renewal_iterations: u256
        ) {
            // check community owner is caller
            let community_owner = self.communities.read(community_id).community_owner;
            assert(community_owner == get_caller_address(), NOT_COMMUNITY_OWNER);

            self._upgrade_community(
                community_id, 
                upgrade_type,
                subscription_id,
                renewal_status,
                renewal_iterations
            );
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
            paid_gating_details: (ContractAddress, u256),
        ) {
            // assert caller is community owner
            let community_owner = self.community_owner.read(community_id);
            assert(community_owner == get_caller_address(), NOT_COMMUNITY_OWNER);

            // check that only premium communities can do NFTGating or PaidGating
            let community_details = self.communities.read(community_id);
            if (gate_keep_type == GateKeepType::NFTGating
                || gate_keep_type == GateKeepType::PaidGating) {
                assert(
                    community_details.community_premium_status == true, ONLY_PREMIUM_COMMUNITIES
                );
            }

            let mut community_gate_keep_details = CommunityGateKeepDetails {
                community_id: community_id,
                gate_keep_type: gate_keep_type.clone(),
                gatekeep_nft_address: nft_contract_address,
                paid_gating_details: paid_gating_details
            };

            // permissioned gatekeeping
            if (gate_keep_type == GateKeepType::PermissionedGating) {
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
        ) -> (bool, CommunityMember) {
            let community_member = self.community_member.read((community_id, profile));
            if (community_member.community_id == community_id) {
                (true, community_member)
            } else {
                (false, community_member)
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

        /// @notice gets the fee address
        /// @param community_id id of community to get fee address for
        /// @returns the fee address for a community
        fn get_fee_address(self: @ComponentState<TContractState>, community_id: u256) -> ContractAddress {
            self.fee_address.read(community_id)
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

            if (gatekeep_details.gate_keep_type == GateKeepType::None) {
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
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl Jolt: JoltComponent::HasComponent<TContractState>,
        impl Ownable: OwnableComponent::HasComponent<TContractState>
    > of PrivateTrait<TContractState> {
        /// @notice initalizes community component
        /// @param community_nft_classhash classhash of community NFT
        fn _initializer(
            ref self: ComponentState<TContractState>, community_nft_classhash: felt252
        ) {
            self.community_counter.write(0);
            self.community_nft_classhash.write(community_nft_classhash.try_into().unwrap());
        }

        /// @notice internal function to create a community
        /// @param  community type of the new community
        fn _create_community(
            ref self: ComponentState<TContractState>,
            community_owner: ContractAddress,
            community_nft_address: ContractAddress,
            community_id: u256
        ) {
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
                gatekeep_nft_address: contract_address_const::<0>(),
                paid_gating_details: (contract_address_const::<0>(), 0)
            };

            self.communities.write(community_id, community_details);
            self.community_owner.write(community_id, community_owner);
            self.community_gate_keep.write(community_id, gate_keep_details);
            self.community_counter.write(community_id);

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

            // let the owner join the community by default
            self._join_community(community_owner, community_nft_address, community_id);
        }

        /// @notice internal function to join a community
        /// @param  profile of the new community member
        /// @param community_nft_classhash classhash of community NFT
        /// @param community_id  of community the new member is trying to join
        fn _join_community(
            ref self: ComponentState<TContractState>,
            profile: ContractAddress,
            community_nft_address: ContractAddress,
            community_id: u256
        ) {
            // mint a community token to new joiner
            let minted_token_id = self._mint_community_nft(profile, community_nft_address);

            let community_member = CommunityMember {
                profile_address: profile,
                community_id: community_id,
                total_publications: 0,
                community_token_id: minted_token_id,
                ban_status: false
            };

            // update storage
            self.community_member.write((community_id, profile), community_member);

            let community = self.communities.read(community_id);
            let community_total_members = community.community_total_members + 1;

            // update community details
            let updated_community = CommunityDetails {
                community_total_members: community_total_members, ..community
            };
            self.communities.write(community_id, updated_community);

            // emit event
            self
                .emit(
                    JoinedCommunity {
                        community_id: community_id,
                        transaction_executor: profile,
                        token_id: minted_token_id,
                        profile: profile,
                        block_timestamp: get_block_timestamp(),
                    }
                );
        }

        /// @notice internal function to leave a community
        /// @param  profile of the new community member
        /// @param community_nft_classhash classhash of community NFT
        /// @param community_id  of community the new member is trying to join
        fn _leave_community(
            ref self: ComponentState<TContractState>,
            profile_caller: ContractAddress,
            community_nft_address: ContractAddress,
            community_id: u256,
            community_token_id: u256
        ) {
            let community = self.communities.read(community_id);
            // burn user's community token
            self._burn_community_nft(community_nft_address, profile_caller, community_token_id);

            // remove member details and update storage
            let updated_member_details = CommunityMember {
                profile_address: contract_address_const::<0>(),
                community_id: 0,
                total_publications: 0,
                community_token_id: 0,
                ban_status: false
            };
            self.community_member.write((community_id, profile_caller), updated_member_details);
            let community_total_members = community.community_total_members - 1;
            let updated_community = CommunityDetails {
                community_total_members: community_total_members, ..community
            };
            self.communities.write(community_id, updated_community);

            // emit event
            self
                .emit(
                    LeftCommunity {
                        community_id: community_id,
                        transaction_executor: profile_caller,
                        token_id: community_token_id,
                        profile: profile_caller,
                        block_timestamp: get_block_timestamp(),
                    }
                );
        }

        /// @notice internal function to upgrade community
        /// @param community_id id of community to be upgraded
        /// @param upgrade_type
        fn _upgrade_community(
            ref self: ComponentState<TContractState>,
            community_id: u256,
            upgrade_type: CommunityType,
            subscription_id: u256,
            renewal_status: bool,
            renewal_iterations: u256
        ) {
            let community = self.communities.read(community_id);

            // jolt subscription
            let subscription_data = get_dep_component!(@self, Jolt).get_subscription_data(subscription_id);

            let jolt_params = JoltParams {
                jolt_type: JoltType::Subscription,
                recipient: contract_address_const::<0>(),
                memo: "Upgraded Community",
                amount: subscription_data.amount,
                expiration_stamp: 0,
                subscription_details: (subscription_id, renewal_status, renewal_iterations),
                erc20_contract_address: subscription_data.erc20_contract_address
            };

            // subscribe
            let mut jolt_comp = get_dep_component_mut!(ref self, Jolt);
            jolt_comp.jolt(jolt_params);

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
        fn _permissioned_gatekeeping(
            ref self: ComponentState<TContractState>,
            community_id: u256,
            permissioned_addresses: Array<ContractAddress>
        ) {
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

        fn _enforce_gatekeeping(
            ref self: ComponentState<TContractState>,
            profile: ContractAddress,
            community_id: u256
        ) {
            // get gatekeeping details
            let (_, gatekeep_details) = self.is_gatekeeped(community_id);

            match gatekeep_details.gate_keep_type {
                GateKeepType::None => {
                    return;
                },
                // enforce nft gatekeeping
                GateKeepType::NFTGating => {
                    let balance = IERC721Dispatcher { contract_address: gatekeep_details.gatekeep_nft_address }.balance_of(profile);
                    assert(balance.is_non_zero(), UNAUTHORIZED);
                },
                // enforce permissioned gatekeeping
                GateKeepType::PermissionedGating => {
                    let is_permissioned = self.gate_keep_permissioned_addresses.read((community_id, profile));
                    assert(is_permissioned, UNAUTHORIZED);
                },
                // enforce paid gatekeeping
                GateKeepType::PaidGating => {
                    let fee_address = self.fee_address.read(community_id);
                    let (erc20_contract_address, entry_fee) = gatekeep_details.paid_gating_details;

                    let jolt_params = JoltParams {
                        jolt_type: JoltType::Transfer,
                        recipient: fee_address,
                        memo: "Joined Community",
                        amount: entry_fee,
                        expiration_stamp: 0,
                        subscription_details: (0, false, 0),
                        erc20_contract_address: erc20_contract_address
                    };

                    // jolt entry fee to fee_address
                    let mut jolt_comp = get_dep_component_mut!(ref self, Jolt);
                    jolt_comp.jolt(jolt_params);
                }
            } 
        }

        /// @notice internal function for add community mod
        /// @param community_id id of community
        // @param moderator
        fn _add_community_mods(
            ref self: ComponentState<TContractState>,
            community_id: u256,
            community_owner: ContractAddress,
            moderators: Array<ContractAddress>
        ) {
            let length = moderators.len();
            let mut index: u32 = 0;

            while index < length {
                let moderator = *moderators.at(index);
                let (is_community_member, _) = self.is_community_member(moderator, community_id);
                assert(is_community_member == true, NOT_COMMUNITY_MEMBER);
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
                index += 1;
            };
        }

        /// @notice internal function for remove community mod
        /// @param community_id id of community
        // @param moderators to remove
        fn _remove_community_mods(
            ref self: ComponentState<TContractState>,
            community_id: u256,
            community_owner: ContractAddress,
            moderators: Array<ContractAddress>
        ) {
            let length = moderators.len();
            let mut index: u32 = 0;

            while index < length {
                let moderator = *moderators.at(index);
                let is_mod = self.is_community_mod(moderator, community_id);
                assert(is_mod == true, NOT_COMMUNITY_MOD);

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
                index += 1;
            };
        }

        /// @notice internal function for set ban status for members
        /// @param community_id id of community to be banned or unbanned
        /// @param profiles addresses
        /// @param ban_statuses bool values
        fn _set_ban_status(
            ref self: ComponentState<TContractState>,
            community_id: u256,
            profiles: Array<ContractAddress>,
            ban_statuses: Array<bool>
        ) {
            assert(profiles.len() == ban_statuses.len(), INVALID_LENGTH);
            // for permissioned gating update array of addresses
            let length = profiles.len();
            let mut index: u32 = 0;

            while index < length {
                let profile = *profiles[index];
                let ban_status = *ban_statuses[index];
                // check profile is a community member
                let (is_community_member, _) = self.is_community_member(profile, community_id);
                assert(is_community_member == true, NOT_COMMUNITY_MEMBER);

                // update storage
                let community_member = self.community_member.read((community_id, profile));
                let updated_member = CommunityMember { ban_status: ban_status, ..community_member };
                self.community_member.write((community_id, profile), updated_member);

                // emit event
                self
                    .emit(
                        CommunityBanStatusUpdated {
                            community_id: community_id,
                            transaction_executor: get_caller_address(),
                            profile: profile,
                            ban_status: ban_status,
                            block_timestamp: get_block_timestamp()
                        }
                    );
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
            profile: ContractAddress,
            token_id: u256
        ) {
            ICommunityNftDispatcher { contract_address: community_nft_address }
                .burn_nft(profile, token_id);
        }
    }
}
