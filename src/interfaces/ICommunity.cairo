use starknet::ContractAddress;
use karst::base::constants::types::{CommunityParams, GateKeepType, CommunityType};

// *************************************************************************
//                              INTERFACE of ICommunity
// *************************************************************************

#[starknet::interface]
pub trait ICommunity<TState>{
     // *************************************************************************
    //                            EXTERNALS
    // *************************************************************************
    fn create_comminuty(ref self: TState, comminuty_param: CommunityParams) -> u256;
    fn join_community(ref self: TState, community_id: u256);
	fn leave_community(ref self: TState, community_id: u256);
    fn set_community_metadata_uri(
	        ref self: TState, community_id: u256, metadata_uri: ByteArray
	    );
    fn add_community_mods(ref self: TState, community_id: u256 , moderator: ContractAddress );
	fn remove_community_mods(ref self: TState, community_id: u256 , moderator: ContractAddress );
	fn set_ban_status(ref self: TState, community_id: u256, profile: ContractAddress, ban_status: bool);
	fn upgrade_community(ref self: TState, community_id: u256, upgrade_type: CommunityType);
	fn gatekeep(ref self: TState, community_id: u256, gatekeep_type: GateKeepType, nft_contract_address: ContractAddress, permissioned_addresses: Array<ContractAddress>);
		    
}