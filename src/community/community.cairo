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
        CommunityParams, CommunityDetails, GateKeepType, CommunityType
    };

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        communities_counts: u256,
        communities: LegacyMap<
            u256, Vec<CommunityDetails>
        >, // map <community_id, community_details>
        member_community_id: LegacyMap<
            ContractAddress, u256
        >, // map <memeber address, community id>
        community_member: LegacyMap<
            ContractAddress, Vec<CommunityMember>
        >, //  map <member_address, CommunityMember>
        community_mod: LegacyMap<u256, ContractAddress>, // map <community id tuple<mod_address>>
        community_gate_keep: LegacyMap<u256, Vec<GateKeepType>>
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
        CommunityUpgraded: CommunityUpgraded
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
            let owner = get_caller_address();
            let community_count = self.communities_counts.read();
            let community_id = community_count + 1;

            let community_details = CommunityDetails {
                community_id: community_id,
                community_owner: community_owner,
                community_metadata_uri: "",
                community_nft_address: community_param.community_nft_address,
                community_premium_status: community_param.community_premium_status,
                community_total_members: 0
            };

            self.communities.write(community_id, community_details);
            self
                .emit(
                    CommunityCreated {
                        community_id: u256,
                        community_owner: ContractAddress,
                        community_nft_address: ContractAddress,
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

            if (community) {
                panic('Community ID does not exist')
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
        }
    }
}
