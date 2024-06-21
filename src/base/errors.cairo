// *************************************************************************
//                            ERRORS
// *************************************************************************
pub mod Errors {
    pub const NOT_PROFILE_OWNER: felt252 = 'NOT_PROFILE_OWNER';
    pub const ALREADY_MINTED: felt252 = 'USER_ALREADY_MINTED';
    pub const INITIALIZED: felt252 = 'ALREADY_INITIALIZED';
    pub const HUB_RESTRICTED: felt252 = 'CALLER_IS_NOT_HUB';
    pub const FOLLOWING: felt252 = 'USER_ALREADY_FOLLOWING';
    pub const NOT_FOLLOWING: felt252 = 'USER_NOT_FOLLOWING';
    pub const BLOCKED_STATUS: felt252 = 'BLOCKED';
    pub const INVALID_POINTED_PUBLICATION: felt252 = 'INVALID_POINTED_PUB';
    pub const PROFILE_DOESNT_OWN_NFT: felt252 = 'Profile address does not own the NFT being linked';
    pub const HANDLEID_NOT_ZERO: felt252 = 'handle_id cannot be zero';
    pub const PROFILEADDRESS_NOT_ZERO: felt252 = 'profile_address cannot be zero';
    pub const CALLER_NOT_OWNER_OF_NFT: felt252 = 'caller is not the owner of the NFT';
}
