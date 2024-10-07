#[starknet::component]
pub mod CommunityComponent {
    // *************************************************************************
    //                            IMPORT
    // *************************************************************************
    use core::{traits::TryInto, result::ResultTrait};
    use core::num::traits::zero::Zero;
    use starknet::{
        ContractAddress, get_caller_address, get_block_timestamp, ClassHash,
        syscalls::deploy_syscall, SyscallResultTrait,
        storage::{
            StoragePointerWriteAccess, StoragePointerReadAccess, Map, StorageMapReadAccess,
            StorageMapWriteAccess, Vec, VecTrait, MutableVecTrait
        }
    };
    use karst::interfaces::ICommunity::ICommunity;
    use karst::interfaces::ICommunityNft::{ICommunityNftDispatcher, ICommunityNftDispatcherTrait};


    use karst::base::constants::types::{
        CommunityDetails, GateKeepType, CommunityType, CommunityMember, CommunityGateKeepDetails
    };

    use karst::base::constants::errors::{
        Errors::ALREADY_MEMBER, Errors::COMMUNITY_DOES_NOT_EXIST, Errors::NOT_COMMUNITY_OWNER,
        Errors::NOT_MEMBER,
    };


    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    pub struct Storage {
        community_counter: u256,
        community_owner: Map<u256, ContractAddress>, // map<owner_address, community_id>
        communities: Map<u256, CommunityDetails>, // map <community_id, community_details>
        community_membership_status: Map<(u256, ContractAddress), bool>,
        member_community_id: Map<ContractAddress, u256>, // map <memeber address, community id>
        community_member: Map<
            (u256, ContractAddress), CommunityMember
        >, // map<(community_id, member_address), Memeber_details>
        // <
        //     ContractAddress, Vec<CommunityMember>
        // >, //  map <member_address, CommunityMember>
        community_mod: Map<
            (u256, ContractAddress), bool
        >, // <u256, Vec<ContractAddress>>, // map <community id mod_address>
        community_gate_keep: Map<
            u256, CommunityGateKeepDetails
        >, // map <community, CommunityGateKeepDetails>
        gate_keep_permissioned_addresses: Map<
            (u256, ContractAddress), bool
        >, // <u256, Array<ContractAddress>>,
        hub_address: ContractAddress,
        community_nft_classhash: ClassHash
    }

    // *************************************************************************
    //                            EVENT
    // *************************************************************************
    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        CommunityCreated: CommunityCreated,
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
        fn initializer(
            ref self: ComponentState<TContractState>,
            hub_address: ContractAddress,
            community_nft_classhash: felt252
        ) {
            self.community_counter.write(0);
            self.hub_address.write(hub_address);
            self.community_nft_classhash.write(community_nft_classhash.try_into().unwrap());
        }
        fn create_comminuty(ref self: ComponentState<TContractState>, salt: felt252) -> u256 {
            let community_owner = get_caller_address();
            let community_counter = self.community_counter.read();

            let community_id = community_counter + 1;
            let karst_hub = self.hub_address.read();
            let community_nft_classhash = self.community_nft_classhash.read();

            // deploy a new NFT and save the address in community_nft_address
            // let community_nft_address = self
            //     ._get_or_deploy_community_nft(
            //         karst_hub, community_id, community_nft_classhash, salt
            //     );
            let community_details = CommunityDetails {
                community_id: community_id,
                community_owner: community_owner,
                community_metadata_uri: "Community URI",
                community_nft_address: community_owner, // community_nft_address, -- COMING BACK
                community_premium_status: false,
                community_total_members: 0,
                community_type: CommunityType::Free,
            };

            self.communities.write(community_id, community_details);
            self.community_owner.write(community_id, community_owner);
            self.community_counter.write(community_counter);
            self
                .emit(
                    CommunityCreated {
                        community_id: community_id,
                        community_owner: community_owner,
                        community_nft_address: community_owner,
                        block_timestamp: get_block_timestamp()
                    }
                );
            community_id
        }
        fn join_community(
            ref self: ComponentState<TContractState>, profile: ContractAddress, community_id: u256
        ) {
            let community = self.communities.read(community_id);

            let community_member = self.community_membership_status.read((community_id, profile));
            assert(community_member != true, ALREADY_MEMBER);

            // community_token_id
            // a token is minted from the comunity token contract address
            //  let mint_token_id = self._mint_community_nft(community.community_nft_address);
            let community_member = CommunityMember {
                profile_address: profile,
                community_id: community_id,
                total_publications: 0,
                community_token_id: 45, //mint_token_id,
                ban_status: false
            };

            self.community_membership_status.write((community_id, profile), true);

            self.community_member.write((community_id, profile), community_member);

            // update community member count

            let community_total_members = community.community_total_members + 1;
            let updated_community = CommunityDetails {
                community_total_members: community_total_members, ..community
            };
            self.communities.write(community_id, updated_community);
        }
        fn leave_community(
            ref self: ComponentState<TContractState>, profile: ContractAddress, community_id: u256
        ) {
            let community = self.communities.read(community_id);

            let community_member = self.community_membership_status.read((community_id, profile));

            assert(community_member == true, NOT_MEMBER);

            let community_member_details = self.community_member.read((community_id, profile));
            // remove the member_community_id
            self.community_membership_status.write((community_id, profile), false);

            // remove member details
            let leave_community_member = CommunityMember {
                profile_address: profile,
                community_id: 0,
                total_publications: 0,
                community_token_id: 0,
                ban_status: true
            };

            self.community_member.write((community_id, profile), leave_community_member);

            // update community member count
            let community_total_members = community.community_total_members - 1;
            let updated_community = CommunityDetails {
                community_total_members: community_total_members, ..community
            };
            self.communities.write(community_id, updated_community);
            // this function will also burn the nft on leaving
        // call the burn function from the community nft contract

            // self
        //     ._burn_community_nft(
        //         community.community_nft_address, community_member_details.community_token_id
        //     );
        }
        fn set_community_metadata_uri(
            ref self: ComponentState<TContractState>, community_id: u256, metadata_uri: ByteArray
        ) {
            let community_owner = self.community_owner.read(community_id);

            assert(community_owner == get_caller_address(), NOT_COMMUNITY_OWNER);

            let community_details = self.communities.read(community_id);

            let updated_community = CommunityDetails {
                community_metadata_uri: metadata_uri, ..community_details
            };
            self.communities.write(community_id, updated_community)
        }

        fn add_community_mods(
            ref self: ComponentState<TContractState>, community_id: u256, moderator: ContractAddress
        ) {
            // only community owner should be able to set a mod

            let community_owner = self.community_owner.read(community_id);
            assert(community_owner == get_caller_address(), NOT_COMMUNITY_OWNER);

            // Mod must join the community
            let community_member = CommunityMember {
                profile_address: moderator,
                community_id: community_id,
                total_publications: 0,
                community_token_id: 1, // community.community_token_id, COMING BACK TO THIS 
                ban_status: false
            };

            self.community_membership_status.write((community_id, moderator), true);

            self.community_member.write((community_id, moderator), community_member);

            let community = self.communities.read(community_id);

            self.community_mod.write((community_id, moderator), true);

            self
                .emit(
                    CommunityModAdded {
                        community_id: community_id,
                        transaction_executor: community_owner,
                        mod_address: moderator,
                        block_timestamp: get_block_timestamp()
                    }
                )
        }

        fn remove_community_mods(
            ref self: ComponentState<TContractState>, community_id: u256, moderator: ContractAddress
        ) {
            let community_owner = self.community_owner.read(community_id);
            assert(community_owner == get_caller_address(), NOT_COMMUNITY_OWNER);

            let community = self.communities.read(community_id);

            let community_mods = self.community_mod.read((community_id, moderator));

            self.community_mod.write((community_id, moderator), false);
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

        fn set_ban_status(
            ref self: ComponentState<TContractState>,
            community_id: u256,
            profile: ContractAddress,
            ban_status: bool
        ) {
            let caller = get_caller_address();
            let mut caller_is_mod = false;

            let is_community_mod = self.community_mod.read((community_id, caller));
            if (is_community_mod) {
                caller_is_mod = true
            }

            // if call is not mod,
            // check for community onwer
            let community_owner_address = self.community_owner.read(community_id);

            let caller_is_owner = caller == community_owner_address;

            assert(caller_is_mod || caller_is_owner, 'Cannot ban member');

            let community = self.communities.read(community_id);
            assert(community.community_owner == community_owner_address, NOT_COMMUNITY_OWNER);

            let community_member = self.community_membership_status.read((community_id, profile));

            assert(community_member == true, NOT_MEMBER);

            let community_member = self.community_member.read((community_id, profile));

            let updated_member = CommunityMember { ban_status: ban_status, ..community_member };
            self.community_member.write((community_id, profile), updated_member);

            self
                .emit(
                    CommunityBanStatusUpdated {
                        community_id: community_id,
                        transaction_executor: caller,
                        profile: profile,
                        block_timestamp: get_block_timestamp()
                    }
                );
        }

        fn upgrade_community(
            ref self: ComponentState<TContractState>,
            community_id: u256,
            upgrade_type: CommunityType
        ) {
            let caller = get_caller_address();
            let community = self.communities.read(community_id);
            // only owner can upgrade community
            assert(community.community_owner == caller, NOT_COMMUNITY_OWNER);
            let updated_community = CommunityDetails {
                community_type: upgrade_type, community_premium_status: true, ..community
            };
            self.communities.write(community_id, updated_community);
            let community_event = self.communities.read(community_id);
            self
                .emit(
                    CommunityUpgraded {
                        community_id: community_id,
                        transaction_executor: caller,
                        premiumType: community_event.community_type,
                        block_timestamp: get_block_timestamp()
                    }
                );
        }

        fn gatekeep(
            ref self: ComponentState<TContractState>,
            community_id: u256,
            gate_keep_type: GateKeepType,
            nft_contract_address: ContractAddress,
            permissioned_addresses: Array<ContractAddress>,
            entry_fee: u256,
        ) {
            // only community owner can set gate keep type
            let community_owner = self.community_owner.read(community_id);
            assert(community_owner == get_caller_address(), NOT_COMMUNITY_OWNER);

            let community_details = self.communities.read(community_id);

            let mut community_gate_keep_details = CommunityGateKeepDetails {
                community_id: community_id,
                gate_keep_type: gate_keep_type.clone(),
                community_nft_address: nft_contract_address,
                entry_fee: 0
            };

            if (gate_keep_type == GateKeepType::Paid) {
                community_gate_keep_details =
                    CommunityGateKeepDetails {
                        entry_fee: entry_fee, ..community_gate_keep_details
                    };
            }

            self.community_gate_keep.write(community_id, community_gate_keep_details);

            if (gate_keep_type == GateKeepType::PermissionedGating) {
                let length = permissioned_addresses.len();
                let mut index: u32 = 0;
                let mut arr_permissioned_addresses: Array<ContractAddress> = ArrayTrait::new();

                while index < length {
                    self
                        .gate_keep_permissioned_addresses
                        .write((community_id, *permissioned_addresses.at(index)), true);
                    index += 1;
                };
            };

            // emint event
            self
                .emit(
                    CommunityGatekeeped {
                        community_id: community_id,
                        transaction_executor: community_owner,
                        gatekeepType: gate_keep_type,
                        block_timestamp: get_block_timestamp()
                    }
                );
        }

        fn get_community(
            self: @ComponentState<TContractState>, community_id: u256
        ) -> CommunityDetails {
            self.communities.read(community_id)
        }
        fn get_community_metadata_uri(
            self: @ComponentState<TContractState>, community_id: u256
        ) -> ByteArray {
            let community = self.communities.read(community_id);
            community.community_metadata_uri
        }
        fn is_community_member(
            self: @ComponentState<TContractState>, profile: ContractAddress, community_id: u256
        ) -> (bool, u256) {
            let is_community_member_id = self
                .community_membership_status
                .read((community_id, profile));
            (is_community_member_id, community_id)
        }
        fn get_total_members(self: @ComponentState<TContractState>, community_id: u256) -> u256 {
            let community = self.communities.read(community_id);
            community.community_total_members
        }

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

        fn get_ban_status(
            self: @ComponentState<TContractState>, profile: ContractAddress, community_id: u256
        ) -> bool {
            let community_member = self.community_member.read((community_id, profile));
            community_member.ban_status
        }
        fn is_premium_community(
            self: @ComponentState<TContractState>, community_id: u256
        ) -> (bool, CommunityType) {
            let community = self.communities.read(community_id);
            (community.community_premium_status, community.community_type)
        }

        fn is_gatekeeped(
            self: @ComponentState<TContractState>, community_id: u256
        ) -> (bool, GateKeepType) {
            let gate_keep = self.community_gate_keep.read(community_id);

            (true, gate_keep.gate_keep_type)
        }
    }

    #[generate_trait]
    pub impl Private<
        TContractState, +HasComponent<TContractState>
    > of PrivateTrait<TContractState> {
        fn _get_or_deploy_community_nft(
            ref self: ComponentState<TContractState>,
            karst_hub: ContractAddress,
            community_id: u256,
            community_nft_impl_class_hash: ClassHash,
            salt: felt252
        ) -> ContractAddress {
            let mut community = self.communities.read(community_id);
            let community_nft = community.community_nft_address;
            if community_nft.is_zero() {
                // Deploy a new Collect NFT contract
                let deployed_collect_nft_address = self
                    .nft_test(karst_hub, community_id, community_nft_impl_class_hash, salt);

                // Update the community with the deployed Collect NFT address
                let updated_community = CommunityDetails {
                    community_nft_address: deployed_collect_nft_address, ..community
                };

                // Write the updated community with the new Community NFT address
                self.communities.write(community_id, updated_community);
            }

            let community = self.communities.read(community_id);
            community.community_nft_address
        }
        fn nft_test(
            ref self: ComponentState<TContractState>,
            karst_hub: ContractAddress,
            community_id: u256,
            community_nft_impl_class_hash: ClassHash,
            salt: felt252
        ) -> ContractAddress {
            'Demo'.try_into().unwrap()
        }
        fn _deploy_community_nft(
            ref self: ComponentState<TContractState>,
            karst_hub: ContractAddress,
            community_id: u256,
            community_nft_impl_class_hash: ClassHash,
            salt: felt252
        ) -> ContractAddress {
            let mut constructor_calldata: Array<felt252> = array![
                karst_hub.into(), community_id.low.into(), community_id.high.into()
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
        fn _mint_community_nft(
            ref self: ComponentState<TContractState>, community_nft_address: ContractAddress
        ) -> u256 {
            let caller: ContractAddress = get_caller_address();
            let token_id = ICommunityNftDispatcher { contract_address: community_nft_address }
                .mint_nft(caller);
            token_id
        }
        fn _burn_community_nft(
            ref self: ComponentState<TContractState>,
            community_nft_address: ContractAddress,
            token_id: u256
        ) {
            let caller: ContractAddress = get_caller_address();
            ICommunityNftDispatcher { contract_address: community_nft_address }
                .burn_nft(caller, token_id);
        }
    }
}
