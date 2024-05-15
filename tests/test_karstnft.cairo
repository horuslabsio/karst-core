use core::option::OptionTrait;
use core::starknet::SyscallResultTrait;
use core::result::ResultTrait;
use core::traits::TryInto;
use core::traits::Into;
use starknet::{ContractAddress};
use snforge_std::{declare, ContractClassTrait, CheatTarget, start_prank, stop_prank};
use karst::interface::Ikarst::{IKarstDispatcher, IKarstDispatcherTrait};
use karst::karstnft::karstnft::KarstNFT;
use karst::interface::IERC721::{IERC721Dispatcher, IERC721DispatcherTrait};
use karst::interface::Iprofile::{IKarstProfileDispatcher, IKarstProfileDispatcherTrait};
// Account
use token_bound_accounts::interfaces::IAccount::{IAccountDispatcher, IAccountDispatcherTrait};
use token_bound_accounts::presets::account::Account;
// Registry
use karst::test_helper::registry::Registry;
use karst::interface::Iregistry::{IRegistryDispatcher, IRegistryDispatcherTrait};


fn deploy_account() -> ContractAddress {
    // karstnft
    let erc721_contract_address = deploy_contract("KarstNFT");
    // deploy account contract
    let account_contract = declare("Account").unwrap();
    let mut acct_constructor_calldata: Array<felt252> = array![
        erc721_contract_address.into(), 1, 0
    ];
    let (account_contract_address, _) = account_contract
        .deploy(@acct_constructor_calldata)
        .unwrap_syscall();
    account_contract_address
}

fn deploy_registry() -> ContractAddress {
    //  REGISTRY
    let registry_contract = declare("Registry").unwrap();
    let (registry_contract_address, _) = registry_contract.deploy(@array![]).unwrap_syscall();
    registry_contract_address
}
fn deploy_profile() -> ContractAddress {
    let profile_contract = declare("KarstProfile").unwrap();
    let (profile_contract_address, _) = profile_contract.deploy(@array![]).unwrap();
    profile_contract_address
}

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap();
    let admin: ContractAddress = 123.try_into().unwrap();
    let names: ByteArray = "KarstNFT";
    let symbol: ByteArray = "KNFT";
    let base_uri: ByteArray = "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaYXr4gQ/";
    let mut calldata: Array<felt252> = array![admin.into()];
    names.serialize(ref calldata);
    symbol.serialize(ref calldata);
    base_uri.serialize(ref calldata);

    let (contract_address, _) = contract.deploy(@calldata).unwrap();

    contract_address
}

#[test]
fn test_constructor_func() {
    let contract_address: ContractAddress = deploy_contract("KarstNFT");
    let dispatcher = IERC721Dispatcher { contract_address };
    let nft_name = dispatcher.name();
    let nft_symbol = dispatcher.symbol();
    assert(nft_name == "KarstNFT", 'error');
    assert(nft_symbol == "KNFT", 'error');
}

const user1: felt252 = 'user_one';
const user2: felt252 = 'user_two';
const user3: felt252 = 'user_three';
const user4: felt252 = 'user_four';

#[test]
fn test_token_mint() {
    let contract_address: ContractAddress = deploy_contract("KarstNFT");
    let registry_contract_address = deploy_registry();
    let profile_contract_address = deploy_profile();
    let acct_class_hash = declare("Account").unwrap_syscall().class_hash;
    let karstDispatcher = IKarstDispatcher { contract_address };
    let dispatcher = IERC721Dispatcher { contract_address };
    start_prank(CheatTarget::One(contract_address), user1.try_into().unwrap());
    karstDispatcher.mint_karstnft();
    let token_id = karstDispatcher.get_user_token_id(user1.try_into().unwrap());
    let base_uri = dispatcher.token_uri(token_id);
    assert(base_uri == "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaYXr4gQ/0", 'error');
    stop_prank(CheatTarget::One(contract_address));

    start_prank(CheatTarget::One(contract_address), user2.try_into().unwrap());
    karstDispatcher.mint_karstnft();
    let token_id = karstDispatcher.get_user_token_id(user2.try_into().unwrap());
    let base_uri2 = dispatcher.token_uri(token_id);
    assert(base_uri2 == "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaYXr4gQ/1", 'error');

    stop_prank(CheatTarget::One(contract_address));

    start_prank(CheatTarget::One(contract_address), user3.try_into().unwrap());
    karstDispatcher.mint_karstnft();
    let token_id = karstDispatcher.get_user_token_id(user3.try_into().unwrap());
    let current_token_id = karstDispatcher.get_token_id();
    println!(" current token_id {}", current_token_id);
    let base_uri3 = dispatcher.token_uri(token_id);
    assert(base_uri3 == "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaYXr4gQ/2", 'error');
    stop_prank(CheatTarget::One(contract_address));
    //user 4 create profile
    start_prank(CheatTarget::Multiple(array![profile_contract_address, contract_address]), user4.try_into().unwrap());
    let dispatcher = IKarstProfileDispatcher { contract_address: profile_contract_address };
    let erc721 = IERC721Dispatcher{contract_address};
    // karstDispatcher.mint_karstnft();
    dispatcher
        .create_karstnft(
            contract_address, registry_contract_address, acct_class_hash.into(), 2456
        );
        let token_id = karstDispatcher.get_user_token_id(user4.try_into().unwrap());
        let owner = erc721.owner_of(token_id);
        let current_token_id = karstDispatcher.get_token_id();
        let fmtuser4 = to_name(user4);
        println!("user token_id {}", token_id);
        println!(" current token_id {}", current_token_id);
        println!("owner of token_id {:?}", owner);
        println!("user4 {:?}", fmtuser4);
        // assert(current_token_id == 4, 'invalid');
    stop_prank(CheatTarget::Multiple(array![profile_contract_address,contract_address]));
}

// #[test]
// fn test_mint_user2(){
//     let contract_address: ContractAddress = deploy_contract("KarstNFT");
//     let karstDispatcher = IKarstDispatcher { contract_address };
//     // let dispatcher = IERC721Dispatcher { contract_address };
//         // user2
//         start_prank(CheatTarget::One(contract_address), user2.try_into().unwrap());
//         karstDispatcher.mint_karstnft();
//         let token_id = karstDispatcher.get_user_token_id(user2.try_into().unwrap());
//         // let base_uri = dispatcher.token_uri(token_id);
//         // let token_balance = dispatcher.balance_of(user2.try_into().unwrap());
//         // println!("balance {:?}", token_balance); 
//         println!("id2 {:?}", token_id);
//         // println!("uri {:?}", base_uri);
//         // assert(token_id == 1, 'error');
//         // assert(base_uri == "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaYXr4gQ/1", 'error');
//         // assert(token_balance == 1, 'no_nft');
//         stop_prank(CheatTarget::One(contract_address));
// }

// #[test]
// fn test_create_profile_total_created() {
//     let erc721_contract_address = deploy_contract("KarstNFT");
//     let profile_contract_address = deploy_profile();
//     let registry_contract_address = deploy_registry();
//     let acct_class_hash = declare("Account").unwrap_syscall().class_hash;

//     start_prank(CheatTarget::One(profile_contract_address), user4.try_into().unwrap());
//     let dispatcher = IKarstProfileDispatcher { contract_address: profile_contract_address };
//     let karstDispatcher = IKarstDispatcher { contract_address:erc721_contract_address };
//     let token_id_prev = karstDispatcher.get_user_token_id(user4.try_into().unwrap());
//     dispatcher
//         .create_karstnft(
//             erc721_contract_address, registry_contract_address, acct_class_hash.into(), 2456
//         );
//         let token_id = karstDispatcher.get_user_token_id(user4.try_into().unwrap());
//     let total_id = dispatcher.get_total_id();
//     println!("{:?}", total_id);
//     println!("{:?}", token_id);
//     // assert(token_id == 3, 'error');
//     stop_prank(CheatTarget::One(profile_contract_address));
// }

#[test]
fn test_user1_profile_id() {
    let profile_contract_address = deploy_profile();
    start_prank(CheatTarget::One(profile_contract_address), user1.try_into().unwrap());
    let dispatcher = IKarstProfileDispatcher { contract_address: profile_contract_address };
    let profile_id = dispatcher.get_user_profile_id(user1.try_into().unwrap());
    assert(profile_id == 0, 'invalid');
    stop_prank(CheatTarget::One(profile_contract_address));
}


// #[test]
// fn test_token_mint() {
//     let contract_address: ContractAddress = deploy_contract("KarstNFT");
//     let karstDispatcher = IKarstDispatcher { contract_address };
//     let dispatcher = IERC721Dispatcher { contract_address };
//     start_prank(CheatTarget::One(contract_address), user1.try_into().unwrap());
//     karstDispatcher.mint_karstnft();
//     let token_id = karstDispatcher.token_id();
//     let base_uri = dispatcher.token_uri(token_id);
//     let token_balance = dispatcher.balance_of(user1.try_into().unwrap());
//     // println!("{:?}", token_balance);
//     assert(token_id == 0, 'error');
//     assert(base_uri == "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaYXr4gQ/0", 'error');
//     assert(token_balance == 1, 'no_nft');
//     stop_prank(CheatTarget::One(contract_address));
// }

fn to_name(name: felt252) -> ContractAddress {
    name.try_into().unwrap()
}
// #[test]
// fn test_create_profile_total_created() {
//     let profile_contract_address = deploy_profile();

//     start_prank(CheatTarget::One(profile_contract_address), user1.try_into().unwrap());
//     let dispatcher = IKarstProfileDispatcher { contract_address: profile_contract_address };
//     let total_id = dispatcher.get_total_id();
//     let profile_id = dispatcher.get_user_profile_id(user1.try_into().unwrap());
//     println!("user1 {:?}", profile_id);
//     println!("total {:?}", total_id);
//     assert(total_id == 1, 'not_one');

//     stop_prank(CheatTarget::One(profile_contract_address));
// }

// #[test]
// fn test_user1_profile_metadata(){
//     let profile_contract_address = deploy_profile();
//     start_prank(CheatTarget::One(profile_contract_address), user1.try_into().unwrap());
//     let dispatcher = IKarstProfileDispatcher { contract_address: profile_contract_address };
//     // dispatcher.set_profile_metadata_uri("ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaYXr4gQ/");
//     let user1_id = dispatcher.get_user_profile_id(user1.try_into().unwrap());
//     let user1_metadata_uri = dispatcher.get_profile(user1_id);
//     let owner = dispatcher.get_profile_owner_by_id(0);
//     println!("{:?}", owner);
//     println!("{:?}", user1_metadata_uri);
//     // assert(user1_metadata_uri == "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaYXr4gQ/", 'invalid');
//     stop_prank(CheatTarget::One(profile_contract_address));
// }
// let token_owner = token_dispatcher.ownerOf(u256_from_felt252(1));

//print out contract_addresses_of_contract

// println!("{:?}", erc721_contract_address);
// println!("{:?}", profile_contract_address);
// println!("{:?}", registry_contract_address);
// println!("{:?}", acct_class_hash);


