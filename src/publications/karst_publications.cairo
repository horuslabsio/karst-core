//! Contract for Karst Publications
// *************************************************************************
//                              IMPORTS
// *************************************************************************

use starknet::ContractAddress;
// *************************************************************************
//                              INTERFACE of KARST PUBLICATIONS
// *************************************************************************
#[starknet::interface]
trait IKARSTPUBLICATIONS<T> { // similar to interface IERC20 in Solidity

// *************************************************************************
//                              PUBLISHING FUNCTIONS  
// *************************************************************************
    fn post(ref self:T, post: felt252 );
    fn postWithSig(ref self:T, post: felt252, sig:felt252 );
    fn comment(ref self:T, post: felt252 );
    fn commentWithSig(ref self:T, post: felt252, sig:felt252 );
    fn mirror(ref self:T, post: felt252 );
    fn mirrorWithSig(ref self:T, post: felt252, sig:felt252 );
    fn quote(ref self:T, post: felt252 );
    fn quoteWithSig(ref self:T, post: felt252, sig:felt252 );
    fn tip(ref self:T, post: felt252 );

// *************************************************************************
//                              PROFILE INTERACTION FUNCTIONS  
// *************************************************************************
    
    fn follow(ref self:T, profile_id: felt252 );
    fn followWithSig(ref self:T, profile_id: felt252, sig:felt252 );
    fn unfollow(ref self:T, profile_id: felt252 );
    fn unfollowWithSig(ref self:T, profile_id: felt252, sig:felt252 );
    fn is_following(self: @T, profile_id: felt252) -> bool;
    fn postWithSig(ref self:T, post: felt252, sig:felt252 );
    fn isDelegatedExecutorApproved(self: @T, profile_id: felt252, executor: ContractAddress) -> bool;
}


#[starknet::contract]
mod Publications {
    // *************************************************************************
    //                              IMPORTS
    // *************************************************************************
    use starknet::{ContractAddress, get_contract_address, get_caller_address};
    use zeroable::Zeroable;
    use super::IKARSTPUBLICATIONS;
    use openzeppelin::token::erc20::{ERC20ABIDispatcher};
    use openzeppelin::token::erc20::interface::ERC20ABIDispatcherTrait;
   

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************

    #[storage]
    struct Storage {

    }

    // *************************************************************************
    //                              EVENTS
    // *************************************************************************

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Post: Post,
        comment : Comment,
        Mirror : Mirror,
        Quote : Quote,
        Tip : Tip,
        Follow : Follow,
        Unfollow : Unfollow,
    }

    // *************************************************************************
    //                              STRUCTS
    // *************************************************************************

    #[derive(Drop, starknet::Event)]
    struct Post {
        post: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct Comment {
        post: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct Mirror {
        post: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct Quote {
        post: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct Tip {
        post: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct Follow {
        profile_id: felt252,
    }

    #[derive(Drop, starknet::Event)]
    struct Unfollow {
        profile_id: felt252,
    }

    struct Tip {
        post: felt252,
    }

    // *************************************************************************
    //                              CONSTRUCTOR
    // *************************************************************************
    #[constructor]
    fn constructor() {
    }

    // *************************************************************************
    //                              EXTERNAL FUNCTIONS
    // *************************************************************************

    #[external(v0)]
    impl PublicationsImpl of super::IKARSTPUBLICATIONS<ContractState> {
        // *************************************************************************
        //                              PUBLISHING FUNCTIONS
        // *************************************************************************
      
    }
}