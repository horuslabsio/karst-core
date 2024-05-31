// *************************************************************************
//                              PUBLICATION CONTRACT TEST
// *************************************************************************
use core::option::OptionTrait;
use core::starknet::SyscallResultTrait;
use core::result::ResultTrait;
use core::traits::{TryInto, Into};
use starknet::{ContractAddress, class_hash::ClassHash};
use snforge_std::{declare, ContractClassTrait, CheatTarget, start_prank, stop_prank};

use token_bound_accounts::interfaces::IAccount::{IAccountDispatcher, IAccountDispatcherTrait};
use token_bound_accounts::presets::account::Account;
use karst::mocks::registry::Registry;
use karst::interfaces::IRegistry::{IRegistryDispatcher, IRegistryDispatcherTrait};
use karst::karstnft::karstnft::KarstNFT;
use karst::interfaces::IKarstNFT::{IKarstNFTDispatcher, IKarstNFTDispatcherTrait};
use karst::interfaces::IProfile::{IKarstProfileDispatcher, IKarstProfileDispatcherTrait};
use karst::publication::publication::Publications;
use karst::interfaces::IPublication::{
    IKarstPublicationsDispatcher, IKarstPublicationsDispatcherTrait
};
use karst::base::types::{PostParams, ReferencePubParams};

const HUB_ADDRESS: felt252 = 'HUB';
const USER: felt252 = 'USER';

// *************************************************************************
//                              SETUP 
// *************************************************************************
fn __setup__() -> (
    ContractAddress, ContractAddress, ContractAddress, ContractAddress, felt252, felt252
) {
    // deploy NFT
    let nft_contract = declare("KarstNFT").unwrap();
    let names: ByteArray = "KarstNFT";
    let symbol: ByteArray = "KNFT";
    let base_uri: ByteArray = "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaYXr4gQ/";
    let mut calldata: Array<felt252> = array![USER];
    names.serialize(ref calldata);
    symbol.serialize(ref calldata);
    base_uri.serialize(ref calldata);
    let (nft_contract_address, _) = nft_contract.deploy(@calldata).unwrap_syscall();

    // deploy registry
    let registry_class_hash = declare("Registry").unwrap();
    let (registry_contract_address, _) = registry_class_hash.deploy(@array![]).unwrap_syscall();

    // deploy profile
    let profile_contract = declare("KarstProfile").unwrap();
    let mut karst_profile_constructor_calldata = array![HUB_ADDRESS];
    let (profile_contract_address, _) = profile_contract
        .deploy(@karst_profile_constructor_calldata)
        .unwrap();

    // deploy publication
    let publication_contract = declare("Publications").unwrap();
    let mut publication_constructor_calldata = array![HUB_ADDRESS];
    let (publication_contract_address, _) = publication_contract
        .deploy(@publication_constructor_calldata)
        .unwrap_syscall();

    // declare account
    let account_class_hash = declare("Account").unwrap();

    return (
        nft_contract_address,
        registry_contract_address,
        profile_contract_address,
        publication_contract_address,
        registry_class_hash.class_hash.into(),
        account_class_hash.class_hash.into()
    );
}

// *************************************************************************
//                              TEST
// *************************************************************************

#[test]
fn test_post() {
    let (
        nft_contract_address,
        _,
        profile_contract_address,
        publication_contract_address,
        registry_class_hash,
        account_class_hash
    ) =
        __setup__();
    let profile_dispatcher = IKarstProfileDispatcher { contract_address: profile_contract_address };
    let _publication_dispatcher = IKarstPublicationsDispatcher {
        contract_address: publication_contract_address
    };
    start_prank(
        CheatTarget::Multiple(array![publication_contract_address, profile_contract_address]),
        USER.try_into().unwrap()
    );
    let profile_address = profile_dispatcher
        .create_profile(
            nft_contract_address,
            registry_class_hash,
            account_class_hash,
            2478,
            USER.try_into().unwrap()
        );
    profile_dispatcher
        .set_profile_metadata_uri(
            profile_address.try_into().unwrap(),
            "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaYXr4ga/"
        );

    // // POST
    // let contentURI: ByteArray = "ipfs://helloworld";
    // let post1 = publication_dispatcher.post(contentURI, profile_address, profile_contract_address, HUB_ADDRESS.try_into().unwrap());
    // let post2 = publication_dispatcher.post("ell", profile_address, profile_contract_address, HUB_ADDRESS.try_into().unwrap());

    // // COMMENT
    // let comment = publication_dispatcher.comment(profile_address, "hello", profile_address, post1, profile_contract_address);
    // let comment2 = publication_dispatcher.comment(profile_address, "iam", profile_address, post2, profile_contract_address);

    // let post_publication_1 = IKarstPublicationsDispatcher {contract_address: publication_contract_address}.get_publication(profile_address, post1);
    // let post_publication_2 = IKarstPublicationsDispatcher {contract_address: publication_contract_address}.get_publication(profile_address, post2);

    // post
    // println!("post_publication_one: {:?}", post_publication_1);
    // println!("post_publication_two: {:?}", post_publication_2);

    // let comment_publication = IKarstPublicationsDispatcher {
    //     contract_address: publication_contract_address
    // }.get_publication(profile_address, comment);
    // let comment_publication2 = IKarstPublicationsDispatcher {
    //     contract_address: publication_contract_address
    // }.get_publication(profile_address, comment2);

    // // comment
    // println!("comment_publication_one: {:?}", comment_publication);
    // println!("comment_publication_two: {:?}", comment_publication2);

    // assert(post1 == 0, 'invalid pub_count');
    stop_prank(
        CheatTarget::Multiple(array![publication_contract_address, profile_contract_address]),
    );
}

fn to_address(name: felt252) -> ContractAddress {
    name.try_into().unwrap()
}
