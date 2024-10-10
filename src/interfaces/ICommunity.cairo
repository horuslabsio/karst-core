use starknet::{ContractAddress};
use karst::base::constants::types::{
    GateKeepType, CommunityGateKeepDetails, CommunityType, CommunityDetails
};

// *************************************************************************
//                              INTERFACE of ICommunity
// *************************************************************************

#[starknet::interface]
pub trait ICommunity<TState> {
    // *************************************************************************
    //                            EXTERNALS
    // *************************************************************************
    fn create_comminuty(ref self: TState, community_type: CommunityType) -> u256;
    fn join_community(ref self: TState, profile: ContractAddress, community_id: u256);
    fn leave_community(ref self: TState, profile: ContractAddress, community_id: u256);
    fn set_community_metadata_uri(ref self: TState, community_id: u256, metadata_uri: ByteArray);
    fn add_community_mods(ref self: TState, community_id: u256, moderators: Array<ContractAddress>);
    fn remove_community_mods(
        ref self: TState, community_id: u256, moderators: Array<ContractAddress>
    );
    fn set_ban_status(
        ref self: TState,
        community_id: u256,
        profiles: Array<ContractAddress>,
        ban_statuses: Array<bool>
    );
    fn upgrade_community(ref self: TState, community_id: u256, upgrade_type: CommunityType);
    fn gatekeep(
        ref self: TState,
        community_id: u256,
        gate_keep_type: GateKeepType,
        nft_contract_address: ContractAddress,
        permissioned_addresses: Array<ContractAddress>,
        entry_fee: u256
    );

    // *************************************************************************
    //                              GETTERS
    // *************************************************************************
    fn get_community(self: @TState, community_id: u256) -> CommunityDetails;
    fn get_community_metadata_uri(self: @TState, community_id: u256) -> ByteArray;
    fn is_community_member(self: @TState, profile: ContractAddress, community_id: u256) -> bool;
    fn get_total_members(self: @TState, community_id: u256) -> u256;
    fn is_community_mod(self: @TState, profile: ContractAddress, community_id: u256) -> bool;
    fn get_ban_status(self: @TState, profile: ContractAddress, community_id: u256) -> bool;
    fn is_premium_community(self: @TState, community_id: u256) -> (bool, CommunityType);
    fn is_gatekeeped(self: @TState, community_id: u256) -> (bool, CommunityGateKeepDetails);
}
