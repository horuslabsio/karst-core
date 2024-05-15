use core::option::OptionTrait;
use core::starknet::SyscallResultTrait;
use core::result::ResultTrait;
use core::traits::{TryInto, Into};
use starknet::{ContractAddress, class_hash::ClassHash};
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

fn deploy_registry() -> (ContractAddress, felt252) {
    let registry_class_hash = declare("Registry").unwrap();
    let (registry_contract_address, _) = registry_class_hash.deploy(@array![]).unwrap_syscall();
    return (registry_contract_address, registry_class_hash.class_hash.into());
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
    let (registry_contract_address, registry_class_hash) = deploy_registry();
    let profile_contract_address = deploy_profile();
    let acct_class_hash = declare("Account").unwrap_syscall().class_hash;
    let karstDispatcher = IKarstDispatcher { contract_address };
    let erc721Dispatcher = IERC721Dispatcher { contract_address };
    
    //user 1 create profile
    start_prank(CheatTarget::Multiple(array![profile_contract_address, contract_address]), user1.try_into().unwrap());
    let dispatcher = IKarstProfileDispatcher { contract_address: profile_contract_address };
    dispatcher
        .create_karstnft(
            contract_address, registry_contract_address, registry_class_hash, acct_class_hash.into(), 2456
        );
        let token_id = karstDispatcher.get_user_token_id(user1.try_into().unwrap());
        let _owner = erc721Dispatcher.owner_of(token_id);
        let current_token_id = karstDispatcher.get_token_id();
        let _token_user1_uri = erc721Dispatcher.token_uri(token_id);
        dispatcher.set_profile_metadata_uri("Helloworld");
        let user1_profile_id = dispatcher.get_user_profile_id(user1.try_into().unwrap());
        let user1_profile_uri = dispatcher.get_profile(user1_profile_id);
        assert(user1_profile_uri == "Helloworld", 'invalid');
        // println!("user token_id {}", token_id);
        // println!("user token_uri {:?}", token_user1_uri);
        // println!(" current token_id {}", current_token_id);
        // println!("owner of token_id {:?}", owner);
        assert(current_token_id == 1, 'invalid');
    stop_prank(CheatTarget::Multiple(array![profile_contract_address,contract_address]));
   //user2
    start_prank(CheatTarget::Multiple(array![profile_contract_address, contract_address]), user2.try_into().unwrap());
    let karstDispatcher = IKarstDispatcher { contract_address };
    karstDispatcher.mint_karstnft();
    let _user2_token_id = karstDispatcher.get_user_token_id(user2.try_into().unwrap());
    // println!("user2 token_id {:?}", user2_token_id);
    // let token_user2_uri = erc721Dispatcher.token_uri(user2_token_id);
    // println!("user2 token_uri {:?}", token_user2_uri);
    let current_token_id = karstDispatcher.get_token_id();

    dispatcher
    .create_karstnft(
        contract_address, registry_contract_address, registry_class_hash, acct_class_hash.into(), 2456
    );
    assert(current_token_id == 2, 'invalid');
    stop_prank(CheatTarget::Multiple(array![profile_contract_address,contract_address]));

//user3
    start_prank(CheatTarget::Multiple(array![profile_contract_address, contract_address]), user3.try_into().unwrap());
    let karstDispatcher = IKarstDispatcher { contract_address };
    karstDispatcher.mint_karstnft();
    let user3_token_id = karstDispatcher.get_user_token_id(user3.try_into().unwrap());
    // println!("user3 token_id {:?}", user3_token_id);
    let _token_user3_uri = erc721Dispatcher.token_uri(user3_token_id);
    let current_token_id = karstDispatcher.get_token_id();

    dispatcher
    .create_karstnft(
        contract_address, registry_contract_address, registry_class_hash, acct_class_hash.into(), 2456
    );
    assert(current_token_id == 3, 'invalid');
    stop_prank(CheatTarget::Multiple(array![profile_contract_address,contract_address]));

    //user4
    start_prank(CheatTarget::Multiple(array![profile_contract_address, contract_address]), user4.try_into().unwrap());
    let karstDispatcher = IKarstDispatcher { contract_address };
    karstDispatcher.mint_karstnft();
    let user4_token_id = karstDispatcher.get_user_token_id(user4.try_into().unwrap());
    // println!("user4 token_id {:?}", user4_token_id);
    let _token_user4_uri = erc721Dispatcher.token_uri(user4_token_id);
    // println!("user4 token_uri {:?}", token_user4_uri);
    let current_token_id = karstDispatcher.get_token_id();

    dispatcher
    .create_karstnft(
        contract_address, registry_contract_address, registry_class_hash, acct_class_hash.into(), 2456
    );
    assert(current_token_id == 4, 'invalid');
    stop_prank(CheatTarget::Multiple(array![profile_contract_address,contract_address]));
}






fn to_name(name: felt252) -> ContractAddress {
    name.try_into().unwrap()
}


// To do:
// - Test profile token balance