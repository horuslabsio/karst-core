use starknet::ContractAddress;

// *************************************************************************
//                              INTERFACE of FollowNFT 
// *************************************************************************
#[starknet::interface]
pub trait IFollowNFT<TState> {
    fn initialize(ref self: TState, profile_id: u256);
    fn follow(
        ref self: TState,
        follower_profile_id: u256
    ) -> u256;
    fn unfollow(
        ref self: TState,
        unfollower_profile_id: u256
    );
}