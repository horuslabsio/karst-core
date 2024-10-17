use starknet::ContractAddress;

// *************************************************************************
//                            PROFILE
// *************************************************************************
// * @notice A struct containing profile data.
// * profile_address The profile ID of a karst profile
// * profile_owner The address that created the profile_address
// * @param pub_count The number of publications made to this profile.
// * @param metadataURI MetadataURI is used to store the profile's metadata, for example: displayed
// name, description, interests, etc.
// * @param follow_nft profile follow nft token contract
#[derive(Drop, Serde, starknet::Store)]
pub struct Profile {
    pub profile_address: ContractAddress,
    pub profile_owner: ContractAddress,
    pub pub_count: u256,
    pub metadata_URI: ByteArray,
    pub follow_nft: ContractAddress
}

// *************************************************************************
//                            FOLLOW
// *************************************************************************

// /**
// * @notice A struct containing token follow-related data.
// *
// * @param followed_profile_address The ID of the profile being followed.
// * @param follower_profile_address The ID of the profile following.
// * @param followTimestamp The timestamp of the current follow, if a profile is using the token to
// follow.
// * @param block_status true if follower is blocked, false otherwise
// */
#[derive(Drop, Serde, starknet::Store)]
pub struct FollowData {
    pub followed_profile_address: ContractAddress,
    pub follower_profile_address: ContractAddress,
    pub follow_timestamp: u64,
    pub block_status: bool,
}

// *************************************************************************
//                            PUBLICATION
// *************************************************************************

// /**
// * @notice A struct containing publication data.
// *
// * @param pointed_profile_address The profile token ID to point the publication to.
// * @param pointed_pub_id The publication ID to point the publication to.
// * These are used to implement the "reference" feature of the platform and is used in:
// * - Mirrors
// * - Comments
// * - Quotes
// * @param content_URI The URI to set for the content of publication (can be ipfs, arweave, http,
// etc).
// * @param pub_Type The type of publication, can be Nonexistent, Post, Comment, Mirror or Quote.
// * @param root_profile_address The profile ID of the root post (to determine if comments/quotes
// and mirrors come from it).
// * @param root_pub_id The publication ID of the root post (to determine if comments/quotes and
// mirrors come from it).
// */
#[derive(Debug, Drop, Serde, starknet::Store)]
pub struct Publication {
    pub pointed_profile_address: ContractAddress,
    pub pointed_pub_id: u256,
    pub content_URI: ByteArray,
    pub pub_Type: PublicationType,
    pub root_profile_address: ContractAddress,
    pub root_pub_id: u256,
    pub upvote: u256,
    pub downvote: u256,
    pub channel_id: felt252,
    pub collect_nft: ContractAddress,
    pub tipped_amount: u256
}

// /**
// * @notice An enum specifically used in a helper function to easily retrieve the publication type
// for integrations.
// *
// * @param Nonexistent An indicator showing the queried publication does not exist.
// * @param Post A standard post, having an URI, and no pointer to another publication.
// * @param Comment A comment, having an URI, and a pointer to another publication.
// * @param Mirror A mirror, having a pointer to another publication, but no URI.
// */
#[derive(Debug, Drop, Serde, starknet::Store, Clone, PartialEq)]
pub enum PublicationType {
    Nonexistent,
    Post,
    Comment,
    Repost,
}

// /**
// * @notice A struct containing the parameters supplied to the post method
// *
// * @param contentURI URI pointing to the post content
// * @param profile_address profile address that owns the post
// */
#[derive(Drop, Serde, starknet::Store, Clone)]
pub struct PostParams {
    pub content_URI: ByteArray,
    pub profile_address: ContractAddress,
    pub channel_id: felt252
}

///**
// * @notice A struct containing the parameters supplied to the comment method
// *
// * @param profile_address profile address that owns the comment
// * @param contentURI URI pointing to the comment content
// * @param pointed_profile_address profile address of the referenced publication/comment
// * @param pointed_pub_id ID of the pointed publication
// */
#[derive(Drop, Serde, starknet::Store, Clone)]
pub struct CommentParams {
    pub profile_address: ContractAddress,
    pub content_URI: ByteArray,
    pub pointed_profile_address: ContractAddress,
    pub pointed_pub_id: u256,
    pub reference_pub_type: PublicationType,
}

///**
// * @notice A struct containing the parameters for a reference publication
// *
// * @param profile_address profile address that owns the publication
// * @param contentURI URI pointing to the publication content
// * @param pointed_profile_address profile address of the referenced publication
// * @param pointed_pub_id ID of the pointed publication
// */
#[derive(Drop, Serde, starknet::Store)]
pub struct ReferencePubParams {
    pub profile_address: ContractAddress,
    pub content_URI: ByteArray,
    pub pointed_profile_address: ContractAddress,
    pub pointed_pub_id: u256
}

// /**
// * @notice A struct containing the parameters required for the `mirror()` function.
// *
// * @param profile_address The address of the profile to publish to.
// * @param metadata_URI the URI containing metadata attributes to attach to this mirror
// publication.
// * @param pointed_profile_id The profile address to point the mirror to.
// * @param pointed_pub_id The publication ID to point the mirror to.
// */
#[derive(Drop, Serde, starknet::Store, Clone)]
pub struct RepostParams {
    pub profile_address: ContractAddress,
    pub pointed_profile_address: ContractAddress,
    pub pointed_pub_id: u256,
}

// /**
// * @notice A struct containing the parameters required for the `quote()` function.
// *
// * @param profile_address The address of the profile to publish to.
// * @param content_URI The URI to set for this new publication.
// * @param pointed_profile_address The profile address of the publication author that is quoted.
// * @param pointed_pub_id The publication ID that is quoted.
// */
#[derive(Drop, Serde, starknet::Store, Clone)]
pub struct QuoteParams {
    pub profile_address: ContractAddress,
    pub content_URI: ByteArray,
    pub pointed_profile_address: ContractAddress,
    pub pointed_pub_id: u256,
    pub reference_pub_type: PublicationType
}

// *************************************************************************
//                            COMMUNITY
// *************************************************************************

///**
// * @notice A struct containing the parameters representing a community
// *
// * @param community_id The id of the community
// * @param community_owner profile address that owns the community
// * @param community_metadata_uri metatadata uri of the community
// * @param community_nft_address nft to mint to members of the community
// * @param community_total_members total members in the community
// * @param community_premium_status indicates if a community has upgraded
// * @param community_type type of community upgrade, defaults to none
// */
#[derive(Debug, Drop, Serde, starknet::Store, Clone)]
pub struct CommunityDetails {
    pub community_id: u256,
    pub community_owner: ContractAddress,
    pub community_metadata_uri: ByteArray,
    pub community_nft_address: ContractAddress,
    pub community_total_members: u256,
    pub community_censorship: bool,
    pub community_premium_status: bool,
    pub community_type: CommunityType
}

///**
// * @notice A struct representing details of a community member
// *
// * @param profile_address The address of community member
// * @param community_id The id of the community he belongs to
// * @param total_publications The toal publications of the community member
// * @param community_token_id community nft minted to the member
// */
#[derive(Debug, Drop, Serde, starknet::Store, Clone)]
pub struct CommunityMember {
    pub profile_address: ContractAddress,
    pub community_id: u256,
    pub total_publications: u256,
    pub community_token_id: u256,
}

///**
// * @notice A struct representing details of a community gatekeep
// *
// * @param community_id The id of the community he belongs to
// * @param gate_keep_type The type of gatekeep
// * @param gatekeep_nft_address nft address used if nft_gated
// * @param paid_gating_details details of payment if payment gated
// */
#[derive(Debug, Drop, Serde, starknet::Store, Clone)]
pub struct CommunityGateKeepDetails {
    pub community_id: u256,
    pub gate_keep_type: GateKeepType,
    pub gatekeep_nft_address: ContractAddress,
    pub paid_gating_details: (ContractAddress, u256)
}

///**
// * @notice An enum representing different gatekeep types
// *
// * @param None no gating
// * @param NFTGating member must posess a required NFT to join
// * @param permissionedGating only a permissioned list of profiles can join
// * @param PaidGating profile must pay to join
// */
#[derive(Debug, Drop, Serde, starknet::Store, Clone, PartialEq)]
pub enum GateKeepType {
    None,
    NFTGating,
    PermissionedGating,
    PaidGating,
}

///**
// * @notice An enum representing different community types
// *
// * @param Free default for communities
// * @param Standard second-tier upgrade
// * @param Business top-tier upgrade
// */
#[derive(Debug, Drop, Serde, starknet::Store, Clone, PartialEq)]
pub enum CommunityType {
    Free,
    Standard,
    Business
}

// *************************************************************************
//                            CHANNEL
// *************************************************************************

///**
// * @notice A struct containing the parameters representing a community
// *
// * @param channel_id id of the channel
// * @param community_id The id of the community the channel belongs to
// * @param channel_owner profile address that owns the channel
// * @param channel_metadata_uri metatadata uri of the channel
// * @param channel_nft_address nft to mint to members of the channel
// * @param channel_total_members total members in the channel
// * @param channel_censorship indicates if a channel censors publications
// */
#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct ChannelDetails {
    pub channel_id: u256,
    pub community_id: u256,
    pub channel_owner: ContractAddress,
    pub channel_metadata_uri: ByteArray,
    pub channel_nft_address: ContractAddress,
    pub channel_total_members: u256,
    pub channel_censorship: bool,
}

///**
// * @notice A struct representing details of a channel member
// *
// * @param profile_address The address of channel member
// * @param channel_id The id of the channel he belongs to
// * @param total_publications The toal publications of the channel member
// * @param channel_token_id channel nft minted to the member
// */
#[derive(Drop, Serde, Clone, starknet::Store)]
pub struct ChannelMember {
    pub profile: ContractAddress,
    pub channel_id: u256,
    pub total_publications: u256,
    pub channel_token_id: u256,
}

// *************************************************************************
//                            JOLT
// *************************************************************************

///**
// * @notice A struct containing the parameters representing a jolt
// *
// * @param jolt_id id of the jolt
// * @param jolt_type The type of jolt (tip, transfer, request, subscription)
// * @param sender the profile jolting
// * @param recipient the profile being jolted
// * @param memo additional description
// * @param amount amount being jolted
// * @param status status of the jolt
// * @param expiration_stamp time when jolt expires (useful for requests)
// * @param block_timestamp time when jolting happened
// * @param erc20_contract_address currency being jolted in
// */
#[derive(Drop, Serde, starknet::Store)]
pub struct JoltData {
    pub jolt_id: u256,
    pub jolt_type: JoltType,
    pub sender: ContractAddress,
    pub recipient: ContractAddress,
    pub memo: ByteArray,
    pub amount: u256,
    pub status: JoltStatus,
    pub expiration_stamp: u64,
    pub block_timestamp: u64,
    pub erc20_contract_address: ContractAddress
}

///**
// * @notice A struct containing the parameters representing a jolt
// *
// * @param jolt_type The type of jolt (tip, transfer, request, subscription)
// * @param recipient the profile being jolted
// * @param memo additional description
// * @param amount amount being jolted
// * @param expiration_stamp time when jolt expires (useful for requests)
// * @param subscription_details details of subscription (if type is subscription)
// * @param erc20_contract_address currency being jolted in
// */
#[derive(Drop, Serde)]
pub struct JoltParams {
    pub jolt_type: JoltType,
    pub recipient: ContractAddress,
    pub memo: ByteArray,
    pub amount: u256,
    pub expiration_stamp: u64,
    pub subscription_details: (
        u256, bool, u256
    ), //subscription_id, renewal_status, renewal_iterations
    pub erc20_contract_address: ContractAddress,
}

///**
// * @notice A struct representing details of a subscription item
// *
// * @param creator The address who created the subscription item
// * @param fee_address The address to send revenues from subscriptions
// * @param amount subscription amount
// * @param erc20_contract_address accepted currency for subscription
// */
#[derive(Drop, Serde, starknet::Store)]
pub struct SubscriptionData {
    pub creator: ContractAddress,
    pub fee_address: ContractAddress,
    pub amount: u256,
    pub erc20_contract_address: ContractAddress
}

///**
// * @notice An enum representing different jolt types
// *
// * @param Tip used for tipping users
// * @param Transfer used for transferring to other users
// * @param Subscription used for subscriptions
// * @param Request used for requests
// */
#[derive(Drop, Serde, starknet::Store, PartialEq)]
pub enum JoltType {
    Tip,
    Transfer,
    Subscription,
    Request
}

///**
// * @notice An enum representing different jolt statuses
// *
// * @param PENDING when a jolt is pending (usually in request scenarios)
// * @param SUCCESSFUL when a jolt is completed
// * @param EXPIRED when a jolt is expired (usually in request scenarios)
// * @param REJECTED when a jolt was rejected
// * @param FAILED when a jolt txn fails
// */
#[derive(Drop, Serde, starknet::Store, PartialEq)]
pub enum JoltStatus {
    PENDING,
    SUCCESSFUL,
    EXPIRED,
    REJECTED,
    FAILED
}
