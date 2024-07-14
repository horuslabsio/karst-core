use core::option::OptionTrait;
// *************************************************************************
//                              TYPES
// *************************************************************************
use starknet::ContractAddress;

// /**
// * @notice A struct containing token follow-related data.
// *
// * @param follower_profile_address The ID of the profile using the token to follow.
// * @param followTimestamp The timestamp of the current follow, if a profile is using the token to follow.
// */
#[derive(Drop, Serde, starknet::Store)]
pub struct FollowData {
    follower_profile_address: ContractAddress,
    follow_timestamp: u64
}

// * @notice A struct containing profile data.
// * profile_address The profile ID of a karst profile 
// * profile_owner The address that created the profile_address
// * @param pub_count The number of publications made to this profile.
// * @param metadataURI MetadataURI is used to store the profile's metadata, for example: displayed name, description, interests, etc.
#[derive(Drop, Serde, starknet::Store)]
pub struct Profile {
    profile_address: ContractAddress,
    profile_owner: ContractAddress,
    pub_count: u256,
    metadata_URI: ByteArray,
}

// /**
// * @notice A struct containing publication data.
// *
// * @param pointed_profile_address The profile token ID to point the publication to.
// * @param pointed_pub_id The publication ID to point the publication to.
// * These are used to implement the "reference" feature of the platform and is used in:
// * - Mirrors
// * - Comments
// * - Quotes
// * @param content_URI The URI to set for the content of publication (can be ipfs, arweave, http, etc).
// * @param pub_Type The type of publication, can be Nonexistent, Post, Comment, Mirror or Quote.
// * @param root_profile_address The profile ID of the root post (to determine if comments/quotes and mirrors come from it).
// * @param root_pub_id The publication ID of the root post (to determine if comments/quotes and mirrors come from it).
// */
#[derive(Debug, Drop, Serde, starknet::Store)]
pub struct Publication {
    pointed_profile_address: ContractAddress,
    pointed_pub_id: u256,
    content_URI: ByteArray,
    pub_Type: PublicationType,
    root_profile_address: ContractAddress,
    root_pub_id: u256
}

// /**
// * @notice An enum specifically used in a helper function to easily retrieve the publication type for integrations.
// *
// * @param Nonexistent An indicator showing the queried publication does not exist.
// * @param Post A standard post, having an URI, and no pointer to another publication.
// * @param Comment A comment, having an URI, and a pointer to another publication.
// * @param Mirror A mirror, having a pointer to another publication, but no URI.
// * @param Quote A quote, having an URI, and a pointer to another publication.
// */
#[derive(Debug, Drop, Serde, starknet::Store, Clone, PartialEq)]
enum PublicationType {
    Nonexistent,
    Post,
    Comment,
    Mirror,
    Quote
}

// /**
// * @notice A struct containing the parameters supplied to the post method
// *
// * @param contentURI URI pointing to the post content
// * @param profile_address profile address that owns the post
// */
#[derive(Drop, Serde, starknet::Store, Clone)]
pub struct PostParams {
    content_URI: ByteArray,
    profile_address: ContractAddress,
}

// /**
// * @notice A struct containing the parameters supplied to the comment method
// *
// * @param profile_address profile address that owns the comment
// * @param contentURI URI pointing to the comment content
// * @param pointed_profile_address profile address of the referenced publication/comment
// * @param pointed_pub_id ID of the pointed publication
// */
#[derive(Drop, Serde, starknet::Store, Clone)]
struct CommentParams {
    profile_address: ContractAddress,
    content_URI: ByteArray,
    pointed_profile_address: ContractAddress,
    pointed_pub_id: u256,
    reference_pub_type: PublicationType
}


#[derive(Drop, Serde, starknet::Store)]
pub struct ReferencePubParams {
    profile_address: ContractAddress,
    content_URI: ByteArray,
    pointed_profile_address: ContractAddress,
    pointed_pub_id: u256
}

// /**
// * @notice A struct containing the parameters required for the `mirror()` function.
// *
// * @param profile_address The address of the profile to publish to.
// * @param metadata_URI the URI containing metadata attributes to attach to this mirror publication.
// * @param pointed_profile_id The profile address to point the mirror to.
// * @param pointed_pub_id The publication ID to point the mirror to.
// */
#[derive(Drop, Serde, starknet::Store, Clone)]
pub struct MirrorParams {
    profile_address: ContractAddress,
    pointed_profile_address: ContractAddress,
    pointed_pub_id: u256
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
    profile_address: ContractAddress,
    content_URI: ByteArray,
    pointed_profile_address: ContractAddress,
    pointed_pub_id: u256,
    reference_pub_type: PublicationType
}
