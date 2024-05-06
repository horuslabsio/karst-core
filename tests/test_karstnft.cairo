use core::result::ResultTrait;
use core::traits::TryInto;
use core::traits::Into;
use starknet::{ContractAddress};
use snforge_std::{declare, ContractClassTrait};
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
fn deploy_account_and_registry() -> (ContractAddress, ContractAddress) {
    // karstnft
    let erc721_contract_address = deploy_contract("KarstNFT");
    // deploy account contract
    let account_contract = declare("Account").unwrap();
    let mut acct_constructor_calldata: Array<felt252> = array![
        erc721_contract_address.into(), 1, 0
    ];
    let (account_contract_address, _) = account_contract
        .deploy(@acct_constructor_calldata)
        .unwrap();
    //  REGISTRY
    let registry_contract = declare("Registry").unwrap();
    let (registry_contract_address, _) = registry_contract.deploy(@array![]).unwrap();
    (registry_contract_address, account_contract_address)
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

#[test]
fn test_token_uri() {
    let contract_address: ContractAddress = deploy_contract("KarstNFT");
    let karstDispatcher = IKarstDispatcher { contract_address };
    let dispatcher = IERC721Dispatcher { contract_address };
    karstDispatcher.mint_karstnft();
    let token_id = karstDispatcher.token_id();
    let base_uri = dispatcher.token_uri(token_id);
    assert(token_id == 0, 'error');
    assert(base_uri == "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaYXr4gQ/0", 'error');
}


#[test]
fn test_create_profile() {
    let erc721_contract_address = deploy_contract("KarstNFT");
    let (registry_contract_address, _) = deploy_account_and_registry();
    let profile_contract_address = deploy_profile();
    let acct_class_hash = declare("Account").unwrap().class_hash;
    let dispatcher = IKarstProfileDispatcher { contract_address: profile_contract_address };
    dispatcher
        .create_karstnft(erc721_contract_address, registry_contract_address, acct_class_hash.into(), 2456);
    // let total_id = dispatcher.
}
