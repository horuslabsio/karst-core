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
    profileId: ContractAddress,
    contentURI: ByteArray,
    profile_address: ContractAddress,
//actionModule,
//actionModulesInitDatas,
//referenceModule
//referenceModuleInitData

}

#[derive(Drop, Serde, starknet::Store)]
pub struct Profile {
    pubCount: u256,
    metadataURI: ByteArray,
    profile_address: ContractAddress,
    profile_owner: ContractAddress
}


#[derive(Drop, Serde, starknet::Store)]
pub struct Publication {
    pointed_profile_address: ContractAddress,
    pointedPubId: u256,
    contentURI: ByteArray,
    pubType: PublicationType,
    root_profile_address: ContractAddress,
    rootPubId: u256
}


#[derive(Drop, Serde, starknet::Store, PartialEq)]
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
    contentURI: ByteArray,
    pointedProfile_address: ContractAddress,
    pointedPubId: u256
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
