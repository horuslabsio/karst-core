use core::option::OptionTrait;
use core::starknet::SyscallResultTrait;
use core::result::ResultTrait;
use core::traits::TryInto;
use core::traits::Into;
use starknet::{ContractAddress};
use snforge_std::{declare, ContractClassTrait, CheatTarget,start_prank, stop_prank};
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
#[test]
fn test_constructor_func() {
    let contract_address: ContractAddress = deploy_contract("KarstNFT");
    let dispatcher = IERC721Dispatcher { contract_address };
    let nft_name = dispatcher.name();
    let nft_symbol = dispatcher.symbol();
    assert(nft_name == "KarstNFT", 'error');
    assert(nft_symbol == "KNFT", 'error');
}

const user1:felt252 = 'user_one';
// const user2:felt252 = to_name('user_two');

#[test]
fn test_token_mint() {
    let contract_address: ContractAddress = deploy_contract("KarstNFT");
    let karstDispatcher = IKarstDispatcher { contract_address };
    let dispatcher = IERC721Dispatcher { contract_address };
    start_prank(CheatTarget::One(contract_address), user1.try_into().unwrap());
    karstDispatcher.mint_karstnft();
    let token_id = karstDispatcher.token_id();
    let base_uri = dispatcher.token_uri(token_id);
    let token_balance = dispatcher.balance_of(user1.try_into().unwrap());
    println!("{:?}", token_balance);
    assert(token_id == 0, 'error');
    assert(base_uri == "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaYXr4gQ/0", 'error');
    assert(token_balance == 1, 'no_nft');
    stop_prank(CheatTarget::One(contract_address));
}


fn to_name(name:felt252) -> ContractAddress{
    name.try_into().unwrap()
}



#[test]
fn test_create_profile_total_created() {
    let erc721_contract_address = deploy_contract("KarstNFT");
    let profile_contract_address = deploy_profile();
    let registry_contract_address = deploy_registry();
    let acct_class_hash = declare("Account").unwrap_syscall().class_hash;

    start_prank(CheatTarget::One(profile_contract_address), user1.try_into().unwrap());
    // let token_dispatcher = IERC721Dispatcher{contract_address:erc721_contract_address};
    let dispatcher = IKarstProfileDispatcher { contract_address: profile_contract_address };
    dispatcher
        .create_karstnft(
            erc721_contract_address, registry_contract_address, acct_class_hash.into(), 2456
        );
    let total_id = dispatcher.get_total_id();
    assert(total_id == 1, 'not_one');
    stop_prank(CheatTarget::One(profile_contract_address));
}

#[test]
fn test_user1_profile_id(){
    let profile_contract_address = deploy_profile();
    start_prank(CheatTarget::One(profile_contract_address), user1.try_into().unwrap());
    let dispatcher = IKarstProfileDispatcher { contract_address: profile_contract_address };
    let profile_id = dispatcher.get_user_profile_id(user1.try_into().unwrap());
    println!("{:?}", profile_id);
    assert(profile_id == 0, 'invalid');
    stop_prank(CheatTarget::One(profile_contract_address));
}


#[test]
fn test_user1_profile_metadata(){
    let profile_contract_address = deploy_profile();
    start_prank(CheatTarget::One(profile_contract_address), user1.try_into().unwrap());
    let dispatcher = IKarstProfileDispatcher { contract_address: profile_contract_address };
    dispatcher.set_profile_metadata_uri("ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaYXr4gQ/");
    let user1_id = dispatcher.get_user_profile_id(user1.try_into().unwrap());
    let user1_metadata_uri = dispatcher.get_profile(user1_id);
    let owner = dispatcher.get_profile_owner_by_id(0);
    println!("{:?}", owner);
    let user1 = to_name(user1);
    println!("{:?}", user1);
    assert(user1_metadata_uri == "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaYXr4gQ/", 'invalid');
    stop_prank(CheatTarget::One(profile_contract_address));
}
// let token_owner = token_dispatcher.ownerOf(u256_from_felt252(1));

//print out contract_addresses_of_contract

// println!("{:?}", erc721_contract_address);
// println!("{:?}", profile_contract_address);
// println!("{:?}", registry_contract_address);
// println!("{:?}", acct_class_hash);

