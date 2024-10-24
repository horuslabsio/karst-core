use starknet::ContractAddress;
use coloniz::base::constants::types::FollowData;

// *************************************************************************
//                              INTERFACE of FollowNFT
// *************************************************************************
#[starknet::interface]
pub trait IFollowNFT<TState> {
    // *************************************************************************
    //                              EXTERNALS
    // *************************************************************************
    fn follow(ref self: TState, follower_profile_address: ContractAddress) -> u256;
    fn unfollow(ref self: TState, unfollower_profile_address: ContractAddress);
    fn process_block(ref self: TState, follower_profile_address: ContractAddress) -> bool;
    fn process_unblock(ref self: TState, follower_profile_address: ContractAddress) -> bool;
    // *************************************************************************
    //                            GETTERS
    // *************************************************************************
    fn get_follower_profile_address(self: @TState, follow_id: u256) -> ContractAddress;
    fn get_follow_timestamp(self: @TState, follow_id: u256) -> u64;
    fn get_follow_data(self: @TState, follow_id: u256) -> FollowData;
    fn is_following(self: @TState, follower_profile_address: ContractAddress) -> bool;
    fn is_blocked(self: @TState, follower_profile_address: ContractAddress) -> bool;
    fn get_follow_id(self: @TState, follower_profile_address: ContractAddress) -> u256;
    fn get_follower_count(self: @TState) -> u256;
    // *************************************************************************
    //                              METADATA
    // *************************************************************************
    fn name(self: @TState) -> ByteArray;
    fn symbol(self: @TState) -> ByteArray;
    fn token_uri(self: @TState, follow_id: u256) -> ByteArray;
}
