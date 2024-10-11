// *************************************************************************
//                            ERRORS
// *************************************************************************
pub mod Errors {
    pub const UNAUTHORIZED: felt252 = 'Karst: user unauthorized!';
    pub const NOT_PROFILE_OWNER: felt252 = 'Karst: not profile owner!';
    pub const ALREADY_MINTED: felt252 = 'Karst: user already minted!';
    pub const INITIALIZED: felt252 = 'Karst: already initialized!';
    pub const HUB_RESTRICTED: felt252 = 'Karst: caller is not Hub!';
    pub const FOLLOWING: felt252 = 'Karst: user already following!';
    pub const NOT_FOLLOWING: felt252 = 'Karst: user not following!';
    pub const BLOCKED_STATUS: felt252 = 'Karst: user is blocked!';
    pub const INVALID_POINTED_PUBLICATION: felt252 = 'Karst: invalid pointed pub!';
    pub const INVALID_OWNER: felt252 = 'Karst: caller is not owner!';
    pub const INVALID_PROFILE: felt252 = 'Karst: profile is not owner!';
    pub const HANDLE_ALREADY_LINKED: felt252 = 'Karst: handle already linked!';
    pub const HANDLE_DOES_NOT_EXIST: felt252 = 'Karst: handle does not exist!';
    pub const INVALID_LOCAL_NAME: felt252 = 'Karst: invalid local name!';
    pub const UNSUPPORTED_PUB_TYPE: felt252 = 'Karst: unsupported pub type!';
    pub const INVALID_PROFILE_ADDRESS: felt252 = 'Karst: invalid profile address!';
    pub const SELF_FOLLOWING: felt252 = 'Karst: self follow is forbidden';
    pub const ALREADY_REACTED: felt252 = 'Karst: already react to post!';
    pub const ALREADY_MEMBER: felt252 = 'Karst: already a Member';
    pub const COMMUNITY_DOES_NOT_EXIST: felt252 = 'Karst: Community does not exist';
    pub const NOT_COMMUNITY_OWNER: felt252 = 'Karst: Not Community owner';
    pub const ONLY_PREMIUM_COMMUNITIES: felt252 = 'Karst: only premium communities';
    pub const NOT_MEMBER: felt252 = 'Karst: Not a Community  Member';
    pub const BANNED_MEMBER: felt252 = 'Karst: Profile is banned!';
    pub const NOT_TOKEN_OWNER: felt252 = 'Karst: Not a Token Owner';
    pub const TOKEN_DOES_NOT_EXIST: felt252 = 'Karst: Token does not exist';
    pub const SELF_TIPPING: felt252 = 'Karst: self-tip forbidden!';
    pub const SELF_TRANSFER: felt252 = 'Karst: self-transfer forbidden!';
    pub const SELF_REQUEST: felt252 = 'Karst: self-request forbidden!';
    pub const INVALID_EXPIRATION_STAMP: felt252 = 'Karst: invalid expiration stamp';
    pub const INSUFFICIENT_ALLOWANCE: felt252 = 'Karst: insufficient allowance!';
    pub const AUTO_RENEW_DURATION_ENDED: felt252 = 'Karst: auto renew ended!';
    pub const INVALID_JOLT: felt252 = 'Karst: invalid jolt!';
    pub const INVALID_JOLT_RECIPIENT: felt252 = 'Karst: not request recipient!';
    pub const NOT_CHANNEL_OWNER: felt252 = 'Karst: not channel owner';
    pub const NOT_CHANNEL_MODERATOR: felt252 = 'Karst: not channel moderator';
    pub const NOT_CHANNEL_MEMBER: felt252 = 'Karst: not channel member';
    pub const BANNED_FROM_CHANNEL: felt252 = 'Karst: banned from channel';
    pub const CHANNEL_HAS_NO_MEMBER: felt252 = 'Karst: channel has no members';
    pub const INVALID_LENGTH: felt252 = 'Karst: array mismatch';
}
