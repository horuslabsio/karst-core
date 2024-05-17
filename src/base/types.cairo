// *************************************************************************
//                              TYPES
// *************************************************************************
use starknet::ContractAddress;

#[derive(Drop, Serde, starknet::Store)]
pub struct FollowData {
    follower_profile_address: ContractAddress,
    follow_timestamp: u64
}