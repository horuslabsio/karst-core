// *************************************************************************
//                              TESTING FOR PUBLICATION CONTRACT
// *************************************************************************
// *************************************************************************
//                              IMPORT 
// *************************************************************************

use core::option::OptionTrait;
use core::starknet::SyscallResultTrait;
use core::result::ResultTrait;
use core::traits::{TryInto, Into};
use starknet::{ContractAddress, class_hash::ClassHash};
use snforge_std::{declare, ContractClassTrait, CheatTarget, start_prank, stop_prank};

// Account
use token_bound_accounts::interfaces::IAccount::{IAccountDispatcher, IAccountDispatcherTrait};
use token_bound_accounts::presets::account::Account;
// Registry
use karst::mocks::registry::Registry;
use karst::interfaces::IRegistry::{IRegistryDispatcher, IRegistryDispatcherTrait};
//KarstNFT
use karst::karstnft::karstnft::KarstNFT;
use karst::interfaces::IKarstNFT::{IKarstNFTDispatcher, IKarstNFTDispatcherTrait};
//Profile
use karst::interfaces::IProfile::{IKarstProfileDispatcher, IKarstProfileDispatcherTrait};

// Publication
use karst::publication::Publication;
use karst::interfaces::IPublication::{
    IKarstPublicationsDispatcher, IKarstPublicationsDispatcherTrait
};
// types
use karst::base::types::{PostParams, ReferencePubParams};

// 
// *************************************************************************
//                              SETUP 
// *************************************************************************

const USER1: felt252 = 'user-one';
const HUB_ADDRESS: felt252 = 'hub';
// setup for publication contract
fn __setup__() -> ContractAddress {
    let publication_contract = declare("Publications").unwrap();
    let mut publication_constructor_calldata = array![HUB_ADDRESS];
    let (contract_address, _) = publication_contract
        .deploy(@publication_constructor_calldata)
        .unwrap_syscall();
    contract_address
}

fn deploy_profile() -> ContractAddress {
    let profile_contract = declare("KarstProfile").unwrap();
    let mut karst_profile_constructor_calldata = array![HUB_ADDRESS];
    let (profile_contract_address, _) = profile_contract
        .deploy(@karst_profile_constructor_calldata)
        .unwrap();
    profile_contract_address
}

// setup for nft contract
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

    let (contract_address, _) = contract.deploy(@calldata).unwrap_syscall();

    contract_address
}


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
// *************************************************************************
//      END OF SETUP                   
// *************************************************************************

// *************************************************************************
//                              TEST
// *************************************************************************

#[test]
fn test_post() {
    let publication_contract_address = __setup__();
    let karstnft_contract_address: ContractAddress = deploy_contract("KarstNFT");
    let (_, registry_class_hash) = deploy_registry();
    let profile_contract_address = deploy_profile();
    let acct_class_hash = declare("Account").unwrap_syscall().class_hash;
    start_prank(
        CheatTarget::Multiple(array![publication_contract_address, profile_contract_address]),
        HUB_ADDRESS.try_into().unwrap()
    );
    let profile_dispatcher = IKarstProfileDispatcher { contract_address: profile_contract_address };
    let profile_address = profile_dispatcher
        .create_profile(
            karstnft_contract_address, registry_class_hash, acct_class_hash.into(), 2478
        );
    profile_dispatcher
        .set_profile_metadata_uri("ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaYXr4ga/");
    let publication_dispatcher = IKarstPublicationsDispatcher {
        contract_address: publication_contract_address
    };
    let contentURI: ByteArray = "ipfs://helloworld";
    // let post1 = publication_dispatcher.post(contentURI, profile_address, profile_contract_address);
    // let post2 = publication_dispatcher.post("ell", profile_address, profile_contract_address);
    // let post3 = publication_dispatcher.post("hi", profile_address, profile_contract_address);

    // let post_publication_1 = IKarstPublicationsDispatcher{contract_address:publication_contract_address}.get_publication(profile_address, post1);
    // let post_publication_2 = IKarstPublicationsDispatcher{contract_address:publication_contract_address}.get_publication(profile_address, post2);
    // let post_publication_3 = IKarstPublicationsDispatcher{contract_address:publication_contract_address}.get_publication(profile_address, post3);

    stop_prank(
        CheatTarget::Multiple(array![publication_contract_address, profile_contract_address]),
    );
}

