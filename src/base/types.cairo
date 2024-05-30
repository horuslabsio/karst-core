use core::option::OptionTrait;
// *************************************************************************
//                              TYPES
// *************************************************************************
use starknet::ContractAddress;

#[derive(Drop, Serde, starknet::Store)]
pub struct FollowData {
    follower_profile_address: ContractAddress,
    follow_timestamp: u64
}

#[derive(Drop, Serde, starknet::Store)]
pub struct PostParams {
    contentURI: ByteArray,
    profile_address: ContractAddress,
//actionModule,
//actionModulesInitDatas,
//referenceModule
//referenceModuleInitData

}

#[derive(Drop, Serde, starknet::Store)]
pub struct Profile {
    pub_count: u256,
    metadata_URI: ByteArray,
    // profile_address: ContractAddress,
    // profile_owner: ContractAddress
}


#[derive(Debug, Drop, Serde, starknet::Store)]
pub struct Publication {
    pointed_profile_address: ContractAddress,
    pointed_pub_id: u256,
    content_URI: ByteArray,
    pub_Type: PublicationType,
    root_profile_address: ContractAddress,
    root_pub_id: u256
}


#[derive(Debug, Drop, Serde, starknet::Store, PartialEq)]
enum PublicationType {
    Nonexistent,
    Post,
    Comment,
    Mirror,
    Quote
}


#[derive(Drop, Serde, starknet::Store)]
struct ReferencePubParams {
    profile_address: ContractAddress,
    content_URI: ByteArray,
    pointed_profile_address: ContractAddress,
    pointed_pub_id: u256
//    uint256[] referrerProfileIds;
//    uint256[] referrerPubIds;
//    bytes referenceModuleData;
//    address[] actionModules;
//    bytes[] actionModulesInitDatas;
//    address referenceModule;
//    bytes referenceModuleInitData;
}


#[derive(Drop, Serde, starknet::Store)]
struct CommentParams {
    profile_address: ContractAddress,
    contentURI: ByteArray,
    pointedProfile_address: ContractAddress,
    pointedPubId: u256,
//    uint256[] referrerProfileIds;
//    uint256[] referrerPubIds;
//    bytes referenceModuleData;
//    address[] actionModules;
//    bytes[] actionModulesInitDatas;
//    address referenceModule;
//    bytes referenceModuleInitData;
}
