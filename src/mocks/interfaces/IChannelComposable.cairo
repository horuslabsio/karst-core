use starknet::ContractAddress;
use coloniz::base::constants::types::{ChannelDetails, ChannelMember};
use coloniz::base::constants::types::{
    GateKeepType, CommunityGateKeepDetails, CommunityType, CommunityDetails, CommunityMember
};
// *************************************************************************
//                              INTERFACE of coloniz CHANNEL
// *************************************************************************
#[starknet::interface]
pub trait IChannelComposable<TState> {
    // *************************************************************************
    //                             INTERFACE of ICHANNEL
    // *************************************************************************

    // *************************************************************************
    //                              EXTERNALS
    // *************************************************************************
    fn create_channel(ref self: TState, community_id: u256) -> u256;
    fn join_channel(ref self: TState, channel_id: u256);
    fn leave_channel(ref self: TState, channel_id: u256);
    fn set_channel_metadata_uri(ref self: TState, channel_id: u256, metadata_uri: ByteArray);
    fn add_channel_mods(ref self: TState, channel_id: u256, moderators: Array<ContractAddress>);
    fn remove_channel_mods(ref self: TState, channel_id: u256, moderators: Array<ContractAddress>);
    fn set_channel_censorship_status(ref self: TState, channel_id: u256, censorship_status: bool);
    fn set_channel_ban_status(
        ref self: TState,
        channel_id: u256,
        profiles: Array<ContractAddress>,
        ban_statuses: Array<bool>
    );
    // *************************************************************************
    //                              GETTERS
    // *************************************************************************
    fn get_channel(self: @TState, channel_id: u256) -> ChannelDetails;
    fn get_channel_metadata_uri(self: @TState, channel_id: u256) -> ByteArray;
    fn is_channel_member(
        self: @TState, profile: ContractAddress, channel_id: u256
    ) -> (bool, ChannelMember);
    fn get_total_channel_members(self: @TState, channel_id: u256) -> u256;
    fn is_channel_mod(self: @TState, profile: ContractAddress, channel_id: u256) -> bool;
    fn get_channel_censorship_status(self: @TState, channel_id: u256) -> bool;
    fn get_channel_ban_status(self: @TState, profile: ContractAddress, channel_id: u256) -> bool;
    // *************************************************************************
    //                              INTERFACE of ICOMMUNITY
    // *************************************************************************

    // *************************************************************************
    //                            EXTERNALS
    // *************************************************************************
    fn create_community(ref self: TState) -> u256;
    fn join_community(ref self: TState, community_id: u256);
    fn leave_community(ref self: TState, community_id: u256);
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
    fn is_community_member(
        self: @TState, profile: ContractAddress, community_id: u256
    ) -> (bool, CommunityMember);
    fn get_total_members(self: @TState, community_id: u256) -> u256;
    fn is_community_mod(self: @TState, profile: ContractAddress, community_id: u256) -> bool;
    fn get_ban_status(self: @TState, profile: ContractAddress, community_id: u256) -> bool;
    fn is_premium_community(self: @TState, community_id: u256) -> (bool, CommunityType);
    fn is_gatekeeped(self: @TState, community_id: u256) -> (bool, CommunityGateKeepDetails);
}
