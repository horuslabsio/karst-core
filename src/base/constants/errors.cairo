// *************************************************************************
//                            ERRORS
// *************************************************************************
pub mod Errors {
    pub const UNAUTHORIZED: felt252 = 'coloniz: user unauthorized!';
    pub const NOT_PROFILE_OWNER: felt252 = 'coloniz: not profile owner!';
    pub const ALREADY_MINTED: felt252 = 'coloniz: user already minted!';
    pub const INITIALIZED: felt252 = 'coloniz: already initialized!';
    pub const HUB_RESTRICTED: felt252 = 'coloniz: caller is not Hub!';
    pub const FOLLOWING: felt252 = 'coloniz: already following!';
    pub const NOT_FOLLOWING: felt252 = 'coloniz: user not following!';
    pub const BLOCKED_STATUS: felt252 = 'coloniz: user is blocked!';
    pub const INVALID_POINTED_PUBLICATION: felt252 = 'coloniz: invalid pointed pub!';
    pub const INVALID_OWNER: felt252 = 'coloniz: caller is not owner!';
    pub const INVALID_PROFILE: felt252 = 'coloniz: profile is not owner!';
    pub const HANDLE_ALREADY_LINKED: felt252 = 'coloniz: handle already linked!';
    pub const HANDLE_DOES_NOT_EXIST: felt252 = 'coloniz: handle does not exist!';
    pub const INVALID_LOCAL_NAME: felt252 = 'coloniz: invalid local name!';
    pub const UNSUPPORTED_PUB_TYPE: felt252 = 'coloniz: unsupported pub type!';
    pub const INVALID_PROFILE_ADDRESS: felt252 = 'coloniz: invalid profile_addr!';
    pub const SELF_FOLLOWING: felt252 = 'coloniz: self_follow forbidden';
    pub const ALREADY_REACTED: felt252 = 'coloniz: already react to post!';
    pub const ALREADY_MEMBER: felt252 = 'coloniz: already a Member';
    pub const COMMUNITY_DOES_NOT_EXIST: felt252 = 'coloniz: Comm does not exist';
    pub const NOT_COMMUNITY_OWNER: felt252 = 'coloniz: Not Community owner';
    pub const ONLY_PREMIUM_COMMUNITIES: felt252 = 'coloniz: only premium communiti';
    pub const NOT_COMMUNITY_MEMBER: felt252 = 'coloniz: Not Community Member';
    pub const NOT_COMMUNITY_MOD: felt252 = 'coloniz: Not a community mod';
    pub const BANNED_MEMBER: felt252 = 'coloniz: Profile is banned!';
    pub const NOT_TOKEN_OWNER: felt252 = 'coloniz: Not a Token Owner';
    pub const TOKEN_DOES_NOT_EXIST: felt252 = 'coloniz: Token does not exist';
    pub const SELF_TIPPING: felt252 = 'coloniz: self-tip forbidden!';
    pub const SELF_TRANSFER: felt252 = 'coloniz: self-transfer forbiden';
    pub const SELF_REQUEST: felt252 = 'coloniz: self-request forbiden';
    pub const INVALID_EXPIRATION_STAMP: felt252 = 'coloniz: invld expiration stamp';
    pub const INSUFFICIENT_ALLOWANCE: felt252 = 'coloniz: not enough allowance!';
    pub const AUTO_RENEW_DURATION_ENDED: felt252 = 'coloniz: auto renew ended!';
    pub const INVALID_JOLT: felt252 = 'coloniz: invalid jolt!';
    pub const INVALID_JOLT_RECIPIENT: felt252 = 'coloniz: not request recipient!';
    pub const NOT_CHANNEL_OWNER: felt252 = 'coloniz: not channel owner';
    pub const NOT_CHANNEL_MODERATOR: felt252 = 'coloniz: not channel moderator';
    pub const NOT_CHANNEL_MEMBER: felt252 = 'coloniz: not channel member';
    pub const BANNED_FROM_CHANNEL: felt252 = 'coloniz: banned from channel';
    pub const CHANNEL_HAS_NO_MEMBER: felt252 = 'coloniz: channel has no members';
    pub const INVALID_LENGTH: felt252 = 'coloniz: array mismatch';
}
