// *************************************************************************
//                            ERRORS
// *************************************************************************
pub mod Errors {
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
    pub const HADLE_DOES_NOT_EXIST: felt252 = 'Karst: handle does not exist!';
    pub const INVALID_LOCAL_NAME: felt252 = 'Karst: invalid local name!';
    pub const UNSUPPORTED_PUB_TYPE: felt252 = 'Karst: unsupported pub type!';
}
