use core::option::OptionTrait;
use core::starknet::SyscallResultTrait;
use core::result::ResultTrait;
use core::traits::{TryInto, Into};
use starknet::{ContractAddress, class_hash::ClassHash};
use snforge_std::{declare, ContractClassTrait, CheatTarget, start_prank, stop_prank};
use karst::interfaces::IKarstNFT::{IKarstNFTDispatcher, IKarstNFTDispatcherTrait};
use karst::karstnft::karstnft::KarstNFT;
use karst::interfaces::IERC721::{IERC721Dispatcher, IERC721DispatcherTrait};
use karst::interfaces::IProfile::{IKarstProfileDispatcher, IKarstProfileDispatcherTrait};
// Account
use token_bound_accounts::interfaces::IAccount::{IAccountDispatcher, IAccountDispatcherTrait};
use token_bound_accounts::presets::account::Account;
// Registry
use karst::mocks::registry::Registry;
use karst::interfaces::IRegistry::{IRegistryDispatcher, IRegistryDispatcherTrait};

const HUB_ADDRESS: felt252 = 'HUB';
const USER: felt252 = 'USER1';
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
    let mut karst_profile_constructor_calldata = array![HUB_ADDRESS];
    let (profile_contract_address, _) = profile_contract
        .deploy(@karst_profile_constructor_calldata)
        .unwrap();
    profile_contract_address
}

fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap();
    let names: ByteArray = "KarstNFT";
    let symbol: ByteArray = "KNFT";
    let base_uri: ByteArray = "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaYXr4gQ/";
    let mut calldata: Array<felt252> = array![HUB_ADDRESS];
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


#[test]
fn test_token_mint() {
    let contract_address: ContractAddress = deploy_contract("KarstNFT");
    let (_, registry_class_hash) = deploy_registry();
    let profile_contract_address = deploy_profile();
    let acct_class_hash = declare("Account").unwrap_syscall().class_hash;
    let karstDispatcher = IKarstNFTDispatcher { contract_address };
    let _erc721Dispatcher = IERC721Dispatcher { contract_address };

    //user 1 create profile
    start_prank(
        CheatTarget::Multiple(array![profile_contract_address, contract_address]),
        HUB_ADDRESS.try_into().unwrap()
    );
    let dispatcher = IKarstProfileDispatcher { contract_address: profile_contract_address };
    dispatcher.create_profile(contract_address, registry_class_hash, acct_class_hash.into(), 2456, HUB_ADDRESS.try_into().unwrap());
    let current_token_id = karstDispatcher.get_current_token_id();
    dispatcher.set_profile_metadata_uri(HUB_ADDRESS.try_into().unwrap(), "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaYXr4gQ/");
    let hub_profile_uri = dispatcher.get_profile_metadata(HUB_ADDRESS.try_into().unwrap());
    assert(hub_profile_uri == "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaYXr4gQ/", 'invalid');

    assert(current_token_id == 1, 'invalid');
    stop_prank(CheatTarget::Multiple(array![profile_contract_address, contract_address]));
}


fn to_address(name: felt252) -> ContractAddress {
    name.try_into().unwrap()
}

