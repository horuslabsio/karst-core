#[starknet::component]
mod CommunityComponent {
    // *************************************************************************
    //                            IMPORT
    // *************************************************************************
    use core::{traits::TryInto, result::ResultTrait};
    use starknet::{
        ContractAddress, get_caller_address, get_block_timestamp, ClassHash,
        syscalls::deploy_syscall, SyscallResultTrait
    };
    use karst::interfaces::ICommunity::ICommunity;

    //  use karst::interfaces::ICommunity::{
    //     ICommunityDispatcher, ICommunityDispatcherTrait, ICommunityLibraryDispatcher
    // };

    use karst::base::constants::types::{
        CommunityParams, CommunityDetails, GateKeepType, CommunityType, CommunityMod
    };

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        communities_counts: u256,
        communities_owner: LegacyMap<ContractAddress, u256>, // map<owner_address, community_id>
        communities: LegacyMap<u256, CommunityDetails>, // map <community_id, community_details>
        member_community_id: LegacyMap<
            ContractAddress, u256
        >, // map <memeber address, community id>
        community_member: LegacyMap<
            ContractAddress, Vec<CommunityMember>
        >, //  map <member_address, CommunityMember>
        community_mod: LegacyMap<u256, Vec<CommunityMod>>, // map <community id mod_address>
        community_gate_keep: LegacyMap<
            u256, CommunityGateKeepDetails
        >, // map <community, CommunityGateKeepDetails>
        community_gate_keep_permissioned_addresses: LegacyMap<u256, Vec<ContractAddress>>
    }

    // *************************************************************************
    //                            EVENT
    // *************************************************************************
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        CommunityCreated: CommunityCreated,
        CommunityModAdded: CommunityModAdded,
        CommunityBanStatusUpdated: CommunityBanStatusUpdated,
        CommunityModRemoved: CommunityModRemoved,
        CommunityUpgraded: CommunityUpgraded,
        CommunityGateKeep: CommunityGateKeep
    }

    #[derive(Drop, starknet::Event)]
    pub struct CommunityCreated {
        community_id: u256,
        community_owner: ContractAddress,
        community_nft_address: ContractAddress,
        block_timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct CommunityModAdded {
        community_id: u256,
        transaction_executor: ContractAddress,
        mod_address: ContractAddress,
        block_timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct CommunityModRemoved {
        community_id: u256,
        transaction_executor: ContractAddress,
        mod_address: ContractAddress,
        block_timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct CommunityBanStatusUpdated {
        community_id: u256,
        transaction_executor: ContractAddress,
        profile: ContractAddress,
        block_timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct CommunityUpgraded {
        community_id: u256,
        transaction_executor: ContractAddress,
        premiumType: CommunityType,
        block_timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct CommunityGateKeep {
        community_id: u256,
        transaction_executor: ContractAddress,
        gatekeepType: GateKeepType,
        block_timestamp: u64,
    }

    // *************************************************************************
    //                            EXTERNAL FUNCTIONS
    // *************************************************************************
    #[embeddable_as(Community)]
    impl CommunityImpl<
        TContractState, +HasComponent<TContractState>
    > of ICommunity<ComponentState<TContractState>> {
        fn initializer(ref self: ComponentState<TContractState>,) {
            self.communities_counts.write(0);
        }
        fn create_comminuty(
            ref self: ComponentState<TContractState>, community_param: CommunityParams
        ) -> u256 {
            let community_owner = get_caller_address();
            let community_count = self.communities_counts.read();
            let community_id = community_count + 1;

            let community_details = CommunityDetails {
                community_id: community_id,
                community_owner: community_owner,
                community_metadata_uri: "",
                community_nft_address: community_param.community_nft_address,
                community_premium_status: community_param.community_premium_status,
                community_total_members: 0,
                community_type: "Free",
            };

            self.communities.write(community_id, community_details);
            self.communities_owner.write(community_owner, community_id);
            self
                .emit(
                    CommunityCreated {
                        community_id: community_id,
                        community_owner: community_owner,
                        community_nft_address: community_param.community_nft_address,
                        block_timestamp: get_block_timestamp()
                    }
                );
            community_id
        }
        fn join_community(ref self: ComponentState<TContractState>, community_id: u256) {
            let member_address = get_caller_address();
            let community = self.communities.read(community_id);
            let member_community_id = self.member_community_id.read(member_address);
            assert(member_community_id != community_id, "Already a member");

            if (!community) {
                panic('Community does not exist')
            }
            let community_member = CommunityMember {
                profile_address: member_address,
                community_id: community_id,
                total_publications: 0,
                community_token_id: community.community_token_id,
                ban_status: false
            };
            self.member_community_id.write(member_address, community.community_id);
            let member_details = self.community_member.read(member_address);
            member_details.append(community_member);
            self.community_member.write(member_address, member_details);

            // update community member count
            community.community_total_members = community.community_total_members + 1;
            self.communities.write(community_id, community);
        }
        fn leave_community(ref self: ComponentState<TContractState>, community_id: u256) {
            let member_address = get_caller_address();
            let community = self.communities.read(community_id);
            if (!community) {
                panic('Community does not exist')
            }
            let member_community_id = self.member_community_id.read(member_address);
            assert(member_community_id != community_id, "Already a member");

            // remove the member_community_id
            self.member_community_id.write(member_address, 0);

            // remove member details
            let community_member = CommunityMember {
                profile_address: member_address,
                community_id: 0,
                total_publications: 0,
                community_token_id: 0,
                ban_status: false
            };
            let member_details = self.community_member.read(member_address);
            member_details.append(community_member);
            self.community_member.write(member_address, member_details);

            // update community member count
            community.community_total_members = community.community_total_members - 1;
            self.communities.write(community_id, community);
        }
        fn set_community_metadata_uri(
            ref self: ComponentState<TContractState>, community_id: u256, metadata_uri: ByteArray
        ) {
            let community_owner = get_caller_address();
            let comminuty_main_id = self.communities_owner.read(community_owner);
            assert(comminuty_main_id != community_id, "Not Community Owner");
            let community_details = self.communities.read(comminuty_main_id);
            community_details.community_metadata_uri = metadata_uri;
            self.communities.write(comminuty_main_id.community_details)
        }

        fn add_community_mods(
            ref self: ComponentState<TContractState>, community_id: u256, moderator: ContractAddress
        ) {
            // community owner should be able to set a mod 
            let community_owner = get_caller_address();
            let owner_community_id = self.communities_owner.read(community_owner);
            let community = self.communities.read(community_id);
            assert(owner_community_id != community_id, "Not Community Owner");
            let community_mod = self.community_mod.read(community_id);
            let moderator_details = community_mods
                .iter()
                .find((community_mod), community_mod.mod_address == moderator);
            if (moderator_details) {
                moderator_details.community_id = community_id;
                moderator_details.transaction_executor = community_owner;
                moderator_details.mod_address = moderator;
                community_mod.append(moderator_details);
                self.community_mod.write(community_id, community_mod)
            }

            let new_community_mod = CommunityMod {
                community_id: community_id,
                transaction_executor: community_owner,
                mod_address: moderator
            };
            community_mod.append(new_community_mod);

            self.community_mod.write(community_id, community_mod);

            self
                .emit(
                    CommunityModAdded {
                        community_id: community_id,
                        transaction_executor: community_owner,
                        community_nft_address: community.community_nft_address,
                        block_timestamp: get_block_timestamp()
                    }
                )
        }

        fn remove_community_mods(
            ref self: ComponentState<TContractState>, community_id: u256, moderator: ContractAddress
        ) {
            let community_owner = get_caller_address();
            let owner_community_id = self.communities_owner.read(community_owner);
            let community = self.communities.read(community_id);
            assert(owner_community_id != community_id, "Not Community Owner");

            let community_mod = self.community_mod.read(community_id);
            let moderator_details = community_mods
                .iter()
                .find((community_mod), community_mod.mod_address == moderator);

            if (!moderator_details) {
                panic!("Cannot remove mod")
            }

            moderator_details.community_id = 0;
            moderator_details.transaction_executor = "";
            mod_address = "";
            community_mod.append(moderator_details);
            self.community_mod.write(community_id, community_mod);
            self
                .emit(
                    CommunityModRemoved {
                        community_id: community_id,
                        transaction_executor: community_owner,
                        community_nft_address: community.community_nft_address,
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
            let community_owner = get_caller_address();

            // only community owner can take this action
            let community = self.communities.read(community_id);

            assert(commuity.community_owner == community_owner, "Not Community Owner");

            let community = self.communities.read(community_id);
            if (!community) {
                panic('Community does not exist');
            }

            let member_community_id = self.member_community_id.read(profile);
            assert(member_community_id == community_id, "Not a member");

            let community_members = self.community_member.read(profile);
            let memeber_details = community_members
                .iter()
                .find((community_member), community_member.profile_address == profile);
            member_details.ban_status = ban_status;
            community_members.append(memeber_details);
            self.community_member.write(profile, member_details);

            self
                .emit(
                    CommunityBanStatusUpdated {
                        community_id: community_id,
                        transaction_executor: community_owner,
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
            let community = self.communities.read(community_id);
            if (!community) {
                panic('Community does not exist');
            }

            // only owner can upgrade community
            assert(commuity.community_owner == community_owner, "Not Community Owner");
            community.community_type = upgrade_type;
            self.communities.write(community_id, community);

            self
                .emit(
                    CommunityUpgraded {
                        community_id: community_id,
                        transaction_executor: community_owner,
                        premiumType: upgrade_type,
                        block_timestamp: get_block_timestamp()
                    }
                );
        }
        // IN_COMPLETE
        fn gatekeep(
            ref self: ComponentState<TContractState>,
            community_id: u256,
            gate_keep_type: GateKeepType,
            nft_contract_address: ContractAddress,
            permissioned_addresses: Vec<ContractAddress>
        ) {
            // only community owner can set gate keep type
            let community_owner = get_caller_address();
            let comminuty_main_id = self.communities_owner.read(community_owner);
            assert(comminuty_main_id == community_id, "Not Community Owner");
            let community_details = self.communities.read(community_id);
            let community_gate_keep_details = CommunityGateKeepDetails {
                community_id: comminuty_main_id,
                gate_keep_type: gatekeep_type,
                community_nft_address: community_details.community_nft_address,
                permissioned_addresses: permissioned_addresses,
            };

            self.community_gate_keep.write(comminuty_main_id, community_gate_keep_details);
            self
                .community_gate_keep_permissioned_addresses
                .write(community_id, permissioned_addresses)
            // emint event
            self
                .emit(
                    CommunityGateKeep {
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
            self.communities.read(community_id);
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
            let is_community_member_id = self.member_community_id.read(profile);
            if (is_community_member_id != community_id) {
                (false, community_id)
            }
            (true, community_id)
        }
        fn get_total_members(self: @ComponentState<TContractState>, community_id: u256) -> u256 {
            let community = self.communities.read(community_id);
            community.community_total_members
        }

        fn is_community_mod(
            self: @ComponentState<TContractState>, profile: ContractAddress, community_id: u256
        ) -> bool {
            let community_mod = self.community_mod.read(community_id);
            let moderator_details = community_mods
                .iter()
                .find((community_mod), community_mod.mod_address == moderator);

            if (moderator_details) {
                true
            }
            false
        }

        fn get_ban_status(
            self: @ComponentState<TContractState>, profile: ContractAddress, community_id: u256
        ) -> bool {
            let community_members = self.community_member.read(profile);
            let memeber_details = community_members
                .iter()
                .find((community_member), community_member.profile_address == profile);
            memeber_details.ban_status
        }
        fn is_premium_community(self: @TState, community_id: u256) -> (bool, CommunityType) {
            let community = self.communities.read(community_id);
            (community.community_type, community.community_premium_status)
        }
        // INCOMPLETE
        fn is_gatekeeped(ref self: TState, community_id: u256) -> (bool, GateKeepType) {
            (true, "Paid")
        }
    }
}
