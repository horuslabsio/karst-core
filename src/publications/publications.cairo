//! Contract for Karst Publications

use starknet::ContractAddress;
pub mod types;

// *************************************************************************
//                              INTERFACE of KARST PUBLICATIONS
// *************************************************************************
#[starknet::interface]
pub trait IKarstPublications<T> {
    // *************************************************************************
    //                              PUBLISHING FUNCTIONS  
    // *************************************************************************

    fn post(ref self: T, post: types.PostParams);
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
    struct Storage {
        // // profile_id -> profile
        // profiles: HashMap<felt252, Profile>,
        // // profile_id -> profile_id -> bool
        // delegated_executors: HashMap<felt252, HashMap<ContractAddress, bool>>,
    }

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

        //onlyProfileOwnerOrDelegatedExecutor can post
        fn post(ref self: ContractState, post: types::PostParams) {
            let publication_id = 0;
            let transaction_executor = get_caller_address();
            let block_timestamp = 0;
            self.emit(Post { post, publication_id, transaction_executor, block_timestamp, });
        }

        //onlyProfileOwnerOrDelegatedExecutor can post
        fn postWithSig(ref self: ContractState, post: felt252, sig: felt252) {
            let publication_id = 0;
            let transaction_executor = get_caller_address();
            let block_timestamp = 0;
            self.emit(Post { post, publication_id, transaction_executor, block_timestamp, });
        }

        //onlyProfileOwnerOrDelegatedExecutor can post
        fn comment(ref self: ContractState, comment: felt252) {
            let publication_id = 0;
            let transaction_executor = get_caller_address();
            let block_timestamp = 0;
            self.emit(
                Comment { comment, publication_id, transaction_executor, block_timestamp, }
            );
        }

        //onlyProfileOwnerOrDelegatedExecutor can post
        fn commentWithSig(ref self: ContractState, comment: felt252, sig: felt252) {
            let publication_id = 0;
            let transaction_executor = get_caller_address();
            let block_timestamp = 0;
            self.emit(
                Comment { comment, publication_id, transaction_executor, block_timestamp, }
            );
        }

        //onlyProfileOwnerOrDelegatedExecutor can post
        fn mirror(ref self: ContractState, post: felt252) {
            let publication_id = 0;
            let transaction_executor = get_caller_address();
            let block_timestamp = 0;
            self.emit(Mirror { post, publication_id, transaction_executor, block_timestamp, });
        }

        //onlyProfileOwnerOrDelegatedExecutor can post
        fn mirrorWithSig(ref self: ContractState, post: felt252, sig: felt252) {
            let publication_id = 0;
            let transaction_executor = get_caller_address();
            let block_timestamp = 0;
            self.emit(Mirror { post, publication_id, transaction_executor, block_timestamp, });
        }

        //onlyProfileOwnerOrDelegatedExecutor can post
        fn quote(ref self: ContractState, quote: felt252) {
            let publication_id = 0;
            let transaction_executor = get_caller_address();
            let block_timestamp = 0;
            self.emit(Quote { quote, publication_id, transaction_executor, block_timestamp, });
        }

        //onlyProfileOwnerOrDelegatedExecutor can post
        fn quoteWithSig(ref self: ContractState, quote: felt252, sig: felt252) {
            let publication_id = 0;
            let transaction_executor = get_caller_address();
            let block_timestamp = 0;
            self.emit(Quote { quote, publication_id, transaction_executor, block_timestamp, });
        }

        //onlyProfileOwnerOrDelegatedExecutor can post
        fn tip(ref self: ContractState, post: felt252) {
            let publication_id = 0;
            let transaction_executor = get_caller_address();
            let block_timestamp = 0;
            self.emit(Tip { post, publication_id, transaction_executor, block_timestamp, });
        }
    // *************************************************************************
    }
}
