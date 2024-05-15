use starknet::ContractAddress;
// *************************************************************************
//                              INTERFACE of KARST PUBLICATIONS
// *************************************************************************
#[starknet::interface]
trait IKarstPublications<T> { 

// *************************************************************************
//                              PUBLISHING FUNCTIONS  
// *************************************************************************
    fn post(ref self:T, post: felt252 );
    fn postWithSig(ref self:T, post: felt252, sig:felt252 );
    fn comment(ref self:T, comment: felt252 );
    fn commentWithSig(ref self:T, comment: felt252, sig:felt252 );
    fn mirror(ref self:T, post: felt252 );
    fn mirrorWithSig(ref self:T, post: felt252, sig:felt252 );
    fn quote(ref self:T, quote: felt252 );
    fn quoteWithSig(ref self:T, quote: felt252, sig:felt252 );
    fn tip(ref self:T, post: felt252 );

// *************************************************************************
//                              PROFILE INTERACTION FUNCTIONS  
// *************************************************************************
    
    // fn follow(ref self:T, profile_id: felt252 );
    // fn followWithSig(ref self:T, profile_id: felt252, sig:felt252 );
    // fn unfollow(ref self:T, profile_id: felt252 );
    // fn unfollowWithSig(ref self:T, profile_id: felt252, sig:felt252 );
    // fn is_following(self: @T, profile_id: felt252) -> bool;
    // fn postWithSig(ref self:T, post: felt252, sig:felt252 );
    // fn isDelegatedExecutorApproved(self: @T, profile_id: felt252, executor: ContractAddress) -> bool;
}