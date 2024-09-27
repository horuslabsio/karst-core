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
     use karst::interfaces::ICommunity::{
        ICommunityDispatcher, ICommunityDispatcherTrait, ICommunityLibraryDispatcher
    };

    use karst::base::constants::types::{CommunityParams, GateKeepType, CommunityType};

       // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        communities: LegacyMap<u256, CommunityParams>, // map <community_id, community_details>
        member_community_id: LegacyMap<ContractAddress, u256>, // map <memeber address, community id>
        community_member: LegacyMap<ContractAddress, (CommunityMember)>,  //  map <member_address, CommunityMember>
        community_mod: LegacyMap<u256, (ContractAddress)>, // map <community id tuple<mod_address>>
        community_gate_keep: LegacyMap<u256, (GateKeepType)>
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


}