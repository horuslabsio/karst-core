use starknet::ContractAddress;
use karst::base::types::FollowData;

// *************************************************************************
//                              INTERFACE of FollowNFT 
// *************************************************************************
#[starknet::interface]
pub trait IFollowNFT<TState> {
    // *************************************************************************
    //                              EXTERNALS
    // *************************************************************************
    fn initialize(ref self: TState, profile_address: ContractAddress);
    fn follow(ref self: TState, follower_profile_address: ContractAddress) -> u256;
    fn unfollow(ref self: TState, unfollower_profile_address: ContractAddress);
    fn wrap(ref self: TState, follow_token_id: u256, wrapped_token_receiver: ContractAddress);
    fn unwrap(ref self: TState, follow_token_id: u256);
    fn process_block(ref self: TState, follower_profile_address: ContractAddress) -> bool;
    // *************************************************************************
    //                            GETTERS
    // *************************************************************************
    fn get_follower_profile_id(ref self: TState, follow_token_id: u256) -> u256;
    fn get_follow_timestamp(ref self: TState, follow_token_id: u256) -> u64;
    fn get_follow_data(ref self: TState, follow_token_id: u256) -> FollowData;
}
