//! Contract for Karst Publications

use starknet::ContractAddress;
// *************************************************************************
//                              INTERFACE of KARST PUBLICATIONS
// *************************************************************************
#[starknet::interface]
pub trait IKarstPublications<T> {
    // *************************************************************************
    //                              PUBLISHING FUNCTIONS  
    // *************************************************************************
    fn post(ref self: T, post: felt252);
    fn postWithSig(ref self: T, post: felt252, sig: felt252);
    fn comment(ref self: T, comment: felt252);
    fn commentWithSig(ref self: T, comment: felt252, sig: felt252);
    fn mirror(ref self: T, post: felt252);
    fn mirrorWithSig(ref self: T, post: felt252, sig: felt252);
    fn quote(ref self: T, quote: felt252);
    fn quoteWithSig(ref self: T, quote: felt252, sig: felt252);
    fn tip(ref self: T, post: felt252);
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

#[starknet::contract]
pub mod Publications {
    // *************************************************************************
    //                              IMPORTS
    // *************************************************************************
    use starknet::{ContractAddress, get_contract_address, get_caller_address};

    use super::IKarstPublications;
    // use openzeppelin::token::erc20::{ERC20ABIDispatcher};
    // use openzeppelin::token::erc20::interface::ERC20ABIDispatcherTrait;

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************

    #[storage]
    struct Storage {}

    // *************************************************************************
    //                              EVENTS
    // *************************************************************************

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        Post: Post,
        Comment: Comment,
        Mirror: Mirror,
        Quote: Quote,
        Tip: Tip,
    }

    // *************************************************************************
    //                              STRUCTS
    // *************************************************************************

    #[derive(Drop, starknet::Event)]
    pub struct Post {
        pub post: felt252,
        pub publication_id: u256,
        pub transaction_executor: ContractAddress,
        pub block_timestamp: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Comment {
        comment: felt252,
        publication_id: u256,
        transaction_executor: ContractAddress,
        block_timestamp: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Mirror {
        post: felt252,
        publication_id: u256,
        transaction_executor: ContractAddress,
        block_timestamp: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Quote {
        quote: felt252,
        publication_id: u256,
        transaction_executor: ContractAddress,
        block_timestamp: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Tip {
        post: felt252,
        publication_id: u256,
        transaction_executor: ContractAddress,
        block_timestamp: u256,
    }

    // *************************************************************************
    //                              CONSTRUCTOR
    // *************************************************************************
    #[constructor]
    fn constructor(ref self: ContractState,) {}

    // *************************************************************************
    //                              EXTERNAL FUNCTIONS
    // *************************************************************************

    #[abi(embed_v0)]
    impl PublicationsImpl of IKarstPublications<ContractState> {
        // *************************************************************************
        //                              PUBLISHING FUNCTIONS
        // *************************************************************************
        fn post(ref self: ContractState, post: felt252) {
            let publication_id = 0;
            let transaction_executor = get_caller_address();
            let block_timestamp = 0;
            Event::Post(Post { post, publication_id, transaction_executor, block_timestamp, });
        }

        fn postWithSig(ref self: ContractState, post: felt252, sig: felt252) {
            let publication_id = 0;
            let transaction_executor = get_caller_address();
            let block_timestamp = 0;
            Event::Post(Post { post, publication_id, transaction_executor, block_timestamp, });
        }

        fn comment(ref self: ContractState, comment: felt252) {
            let publication_id = 0;
            let transaction_executor = get_caller_address();
            let block_timestamp = 0;
            Event::Comment(
                Comment { comment, publication_id, transaction_executor, block_timestamp, }
            );
        }

        fn commentWithSig(ref self: ContractState, comment: felt252, sig: felt252) {
            let publication_id = 0;
            let transaction_executor = get_caller_address();
            let block_timestamp = 0;
            Event::Comment(
                Comment { comment, publication_id, transaction_executor, block_timestamp, }
            );
        }

        fn mirror(ref self: ContractState, post: felt252) {
            let publication_id = 0;
            let transaction_executor = get_caller_address();
            let block_timestamp = 0;
            Event::Mirror(Mirror { post, publication_id, transaction_executor, block_timestamp, });
        }

        fn mirrorWithSig(ref self: ContractState, post: felt252, sig: felt252) {
            let publication_id = 0;
            let transaction_executor = get_caller_address();
            let block_timestamp = 0;
            Event::Mirror(Mirror { post, publication_id, transaction_executor, block_timestamp, });
        }

        fn quote(ref self: ContractState, quote: felt252) {
            let publication_id = 0;
            let transaction_executor = get_caller_address();
            let block_timestamp = 0;
            Event::Quote(Quote { quote, publication_id, transaction_executor, block_timestamp, });
        }

        fn quoteWithSig(ref self: ContractState, quote: felt252, sig: felt252) {
            let publication_id = 0;
            let transaction_executor = get_caller_address();
            let block_timestamp = 0;
            Event::Quote(Quote { quote, publication_id, transaction_executor, block_timestamp, });
        }

        fn tip(ref self: ContractState, post: felt252) {
            let publication_id = 0;
            let transaction_executor = get_caller_address();
            let block_timestamp = 0;
            Event::Tip(Tip { post, publication_id, transaction_executor, block_timestamp, });
        }
    // *************************************************************************
    }
}
