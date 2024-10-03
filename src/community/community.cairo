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
        CommunityDetails, GateKeepType, CommunityType, CommunityMod
    };

    use karst::base::constants::errors::{
        Errors::ALREADY_MEMBER, Errors::COMMUNITY_DOES_NOT_EXIST, Errors::NOT_COMMUNITY_OWNER,
        Errors::NOT_MEMBER,
    };


    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        community_counter: u256,
        community_owner: LegacyMap<u256, ContractAddress>, // map<owner_address, community_id>
        communities: LegacyMap<u256, CommunityDetails>, // map <community_id, community_details>
        community_membership_status: LegacyMap<(u256, ContractAddress), bool>,
        member_community_id: LegacyMap<
            ContractAddress, u256
        >, // map <memeber address, community id>
        community_member: LegacyMap<(u256, ContractAddress), CommunityMember>,
        // <
        //     ContractAddress, Vec<CommunityMember>
        // >, //  map <member_address, CommunityMember>
        community_mod: LegacyMap<u256, Vec<ContractAddress>>, // map <community id mod_address>
        community_gate_keep: LegacyMap<
            u256, CommunityGateKeepDetails
        >, // map <community, CommunityGateKeepDetails>
        gate_keep_permissioned_addresses: LegacyMap<u256, Array<ContractAddress>>,
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
        CommunityGatekeeped: CommunityGatekeeped
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
    pub struct CommunityGatekeeped {
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
            self.community_counter.write(0);
        }
        fn create_comminuty(ref self: ComponentState<TContractState>,) -> u256 {
            let community_owner = get_caller_address();
            let community_counter = self.community_counter.read();
            let community_id = community_counter + 1;

            // deploy a new NFT and save the address in community_nft_address
            let community_details = CommunityDetails {
                community_id: community_id,
                community_owner: community_owner,
                community_metadata_uri: "",
                community_nft_address: "",
                community_premium_status: false,
                community_total_members: 0,
                community_type: "Free",
            };

            self.communities.write(community_id, community_details);
            self.community_owner.write(community_id, community_owner);
            self.community_counter.write(community_counter);
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
            if (!community) {
                panic('Community does not exist')
            }

            let community_member = self
                .community_membership_status
                .read(community_id, member_address);
            assert(community_member == true, ALREADY_MEMBER);

            // let member_community_id = self.member_community_id.read(member_address);
            // assert(member_community_id != community_id, "Already a member");

            // community_token_id
            // a token is minted from the comunity token contract address

            let community_member = CommunityMember {
                profile_address: member_address,
                community_id: community_id,
                total_publications: 0,
                community_token_id: community.community_token_id,
                ban_status: false
            };
            //  self.member_community_id.write(member_address, community.community_id);
            self.community_membership_status.write((community_id, member_address), true);
            // let member_details = self.community_member.read(member_address);
            let member_details = self.community_member.read(community_id, member_address);
            member_details.append(community_member);
            self.community_member.write((community_id, member_address), member_details);

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
            let community_member = self
                .community_membership_status
                .read(community_id, member_address);
            assert(community_member != true, NOT_MEMBER);

            // remove the member_community_id
            self.community_membership_status.write((community_id, member_address), false);

            // remove member details
            let community_member = CommunityMember {
                profile_address: member_address,
                community_id: 0,
                total_publications: 0,
                community_token_id: 0,
                ban_status: true
            };
            let member_details = self.community_member.read(member_address);
            member_details.append(community_member);
            self.community_member.write((community_id, member_address), member_details);

            // update community member count
            community.community_total_members = community.community_total_members - 1;
            self.communities.write(community_id, community);
            // this function will also burn the nft on leaving
        // call the burn function from the community nft contract

        }
        fn set_community_metadata_uri(
            ref self: ComponentState<TContractState>, community_id: u256, metadata_uri: ByteArray
        ) {
            let community_owner = self.community_owner.read(community_id);

            assert(community_owner == get_caller_address(), NOT_COMMUNITY_OWNER);

            let community_details = self.communities.read(community_id);
            community_details.community_metadata_uri = metadata_uri;
            self.communities.write(community_id, community_details)
        }

        fn add_community_mods(
            ref self: ComponentState<TContractState>, community_id: u256, moderator: ContractAddress
        ) {
            // only community owner should be able to set a mod

            let community_owner = self.community_owner.read(community_id);
            assert(community_owner == get_caller_address, NOT_COMMUNITY_OWNER);

            let community = self.communities.read(community_id);

            let mut community_mods = self.community_mod.read(owner_community_id);
            community_mods.append().write(moderator);

            self.community_mod.write(community_id, community_mods);

            self
                .emit(
                    CommunityModAdded {
                        community_id: community_id,
                        transaction_executor: community_owner,
                        mod_address: moderator,
                        community_nft_address: community.community_nft_address,
                        block_timestamp: get_block_timestamp()
                    }
                )
        }

        fn remove_community_mods(
            ref self: ComponentState<TContractState>, community_id: u256, moderator: ContractAddress
        ) {
            let community_owner = self.community_owner.read(community_id);
            assert(community_owner == get_caller_address, NOT_COMMUNITY_OWNER);

            let community = self.communities.read(community_id);

            let community_mods = self.community_mod.read(community_id);

            let mut index = 0;
            while index < community_mods.len() {
                let mod_address = community_mods.at(index);
                if mod_address == moderator {
                    community_mod.append().write(0x0);
                    self.community_mod.write(community_id, community_mods);
                    break ();
                }
                index = index + 1;
            }

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
            let caller = get_caller_address();
            let mut caller_is_mod = false;

            let community_mods = self.community_mod.read(community_id);

            let mut index = 0;
            while index < community_mods.len() {
                let mod_address = community_mods.at(index);
                if mod_address == caller {
                    caller_is_mod = true;
                    break ();
                }
                index = index + 1;
            }

            // if call is not mod,
            // check for community onwer
            let community_owner_adddress = self.community_owner.read(community_id);

            let caller_is_owner = caller == community_owner_address;

            // If caller is neither a mod nor the owner, throw an error
            if !caller_is_mod && !caller_is_owner {
                panic!("Only community moderator or the owner can ban members");
            }

            let community = self.communities.read(community_id);
            if (!community) {
                panic('Community does not exist');
            }

            assert(commuity.community_owner == community_owner_adddress, NOT_COMMUNITY_OWNER);

            let member_community_id = self.member_community_id.read(profile);
            assert(member_community_id == community_id, NOT_MEMBER);

            let community_members = self.community_member.read(profile);
            let memeber_details = community_members
                .iter()
                .find((community_member), community_member.profile_address == profile);
            member_details.ban_status = ban_status;
            community_members.append(memeber_details);
            self.community_member.write((community_id, profile), member_details);

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
            assert(commuity.community_owner == community_owner, NOT_COMMUNITY_OWNER);
            community.community_type = upgrade_type;
            community.community_premium_status = true;
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

        fn gatekeep(
            ref self: ComponentState<TContractState>,
            community_id: u256,
            gate_keep_type: GateKeepType,
            nft_contract_address: ContractAddress,
            permissioned_addresses: Array<ContractAddress>
        ) {
            let community = self.communities.read(community_id);
            if (!community) {
                panic('Community does not exist');
            }

            // only community owner can set gate keep type
            let community_owner = self.community_owner.read(community_id);
            assert(community_owner == get_caller_address, NOT_COMMUNITY_OWNER);

            let community_details = self.communities.read(community_id);

            let community_gate_keep_details = CommunityGateKeepDetails {
                community_id: comminuty_main_id,
                gate_keep_type: gatekeep_type,
                community_nft_address: community_details.community_nft_address,
            };

            // if(gate_keep_type == GateKeepType::Paid){
            //     community_gate_keep_details.insert("entry_fee", 0)
            // }

            self.community_gate_keep.write(comminuty_main_id, community_gate_keep_details);

            if (gate_keep_type == GateKeepType::PermissionedGating) {
                let length = permissioned_addresses.len();
                let mut index: u32 = 0;
                let mut arr_permissioned_addresses: Array<ContractAddress> = ArrayTrait::new();

                while index < length {
                    arr_permissioned_addresses.append(*permissioned_addresses[index])
                    index += 1;
                }

                self
                    .gate_keep_permissioned_addresses
                    .write(community_id, arr_permissioned_addresses)
            }
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
        fn is_premium_community(
            self: @ComponentState<TContractState>, community_id: u256
        ) -> (bool, CommunityType) {
            let community = self.communities.read(community_id);
            (community.community_premium_status, community.community_type)
        }

        fn is_gatekeeped(
            ref self: @ComponentState<TContractState>, community_id: u256
        ) -> (bool, GateKeepType) {
            let community = self.communities.read(community_id);
            if (!community) {
                panic('Community does not exist');
            };

            let gate_keep = self.community_gate_keep.read(community_id);
            if (!gate_keep) {
                (false, GateKeepType::None)
            }
            (true, gate_keep.gate_keep_type)
        }
    }

     // *************************************************************************
    //                            PRIVATE FUNCTIONS
    // *************************************************************************
    
}
