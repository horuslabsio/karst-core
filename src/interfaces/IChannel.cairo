use starknet::ContractAddress;
use karst::base::constants::types::ChannelDetails;

#[starknet::interface]
pub trait IChannel<TState> {
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
        ref self: TState, channel_id: u256, profiles: Array<ContractAddress>,
        ban_statuses: Array<bool>
    );
    // *************************************************************************
    //                              GETTERS
    // *************************************************************************
    fn get_channel(self: @TState, channel_id: u256) -> ChannelDetails;
    fn get_channel_metadata_uri(self: @TState, channel_id: u256) -> ByteArray;
    fn is_channel_member(self: @TState, profile: ContractAddress, channel_id: u256) -> bool;
    fn get_total_members(self: @TState, channel_id: u256) -> u256;
    fn is_channel_mod(self: @TState, profile: ContractAddress, channel_id: u256) -> bool;
    fn get_channel_censorship_status(self: @TState, channel_id: u256) -> bool;
    fn get_channel_ban_status(self: @TState, profile: ContractAddress, channel_id: u256) -> bool;
}