// *************************************************************************
//                            ERRORS
// *************************************************************************
pub mod Errors {
    pub const NOT_PROFILE_OWNER: felt252 = 'NOT_PROFILE_OWNER';
    pub const INITIALIZED: felt252 = 'ALREADY_INITIALIZED';
    pub const HUB_RESTRICTED: felt252 = 'CALLER_IS_NOT_HUB';
    pub const FOLLOWING: felt252 = 'USER_ALREADY_FOLLOWING';
    pub const NOT_FOLLOWING: felt252 = 'USER_NOT_FOLLOWING';
}
