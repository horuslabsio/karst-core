use core::option::OptionTrait;
use core::starknet::SyscallResultTrait;
use core::result::ResultTrait;
use core::traits::{TryInto, Into};

use starknet::{ContractAddress, get_block_timestamp};

use snforge_std::{
    declare, start_cheat_caller_address, stop_cheat_caller_address, spy_events,
    EventSpyAssertionsTrait, ContractClassTrait, DeclareResultTrait
};

use karst::interfaces::IKarstNFT::{IKarstNFTDispatcher, IKarstNFTDispatcherTrait};
use karst::profile::profile::ProfileComponent::{Event as ProfileEvent, CreatedProfile};
use karst::interfaces::IProfile::{IProfileDispatcher, IProfileDispatcherTrait};

const HUB_ADDRESS: felt252 = 'HUB';
const USER: felt252 = 'USER1';

// *************************************************************************
//                              SETUP
// *************************************************************************

fn __setup__() -> (ContractAddress, ContractAddress, felt252, felt252, ContractAddress) {
    // deploy NFT
    let nft_contract = declare("KarstNFT").unwrap().contract_class();
    let mut calldata: Array<felt252> = array![USER];
    let (nft_contract_address, _) = nft_contract.deploy(@calldata).unwrap_syscall();

    // deploy registry
    let registry_class_hash = declare("Registry").unwrap().contract_class();
    let (registry_contract_address, _) = registry_class_hash.deploy(@array![]).unwrap_syscall();

    // declare account
    let account_class_hash = declare("Account").unwrap().contract_class();

    // declare follownft
    let follow_nft_classhash = declare("Follow").unwrap().contract_class();

    // deploy profile
    let profile_contract = declare("KarstProfile").unwrap().contract_class();
    let mut karst_profile_constructor_calldata = array![
        nft_contract_address.into(), HUB_ADDRESS, (*follow_nft_classhash.class_hash).into()
    ];
    let (profile_contract_address, _) = profile_contract
        .deploy(@karst_profile_constructor_calldata)
        .unwrap();

    return (
        nft_contract_address,
        registry_contract_address,
        (*registry_class_hash.class_hash).into(),
        (*account_class_hash.class_hash).into(),
        profile_contract_address
    );
}

// *************************************************************************
//                              TESTS
// *************************************************************************
#[test]
fn test_profile_creation() {
    let (
        nft_contract_address, _, registry_class_hash, account_class_hash, profile_contract_address
    ) =
        __setup__();
    let karstNFTDispatcher = IKarstNFTDispatcher { contract_address: nft_contract_address };
    let profileDispatcher = IProfileDispatcher { contract_address: profile_contract_address };

    //user 1 create profile
    start_cheat_caller_address(profile_contract_address, USER.try_into().unwrap());
    start_cheat_caller_address(nft_contract_address, USER.try_into().unwrap());
    let profile_address = profileDispatcher
        .create_profile(nft_contract_address, registry_class_hash, account_class_hash, 2456,);

    // test a new karst nft is minted
    let last_minted_id = karstNFTDispatcher.get_last_minted_id();
    let token_id = karstNFTDispatcher.get_user_token_id(USER.try_into().unwrap());
    assert(last_minted_id == 1.try_into().unwrap(), 'invalid ID');
    assert(token_id == 1.try_into().unwrap(), 'invalid ID');

    // test profile creation was successful
    let profile = profileDispatcher.get_profile(profile_address);
    assert(profile.profile_address == profile_address, 'invalid profile address');
    assert(profile.profile_owner == USER.try_into().unwrap(), 'invalid profile address');

    // test follow nft contract is deployed
    assert(profile.follow_nft != 0.try_into().unwrap(), 'follow nft not deployed');

    stop_cheat_caller_address(profile_contract_address);
    stop_cheat_caller_address(nft_contract_address);
}

#[test]
fn test_profile_metadata() {
    let (
        nft_contract_address, _, registry_class_hash, account_class_hash, profile_contract_address
    ) =
        __setup__();
    let profileDispatcher = IProfileDispatcher { contract_address: profile_contract_address };

    //user 1 create profile
    start_cheat_caller_address(profile_contract_address, USER.try_into().unwrap());
    start_cheat_caller_address(nft_contract_address, USER.try_into().unwrap());
    let profile_address = profileDispatcher
        .create_profile(nft_contract_address, registry_class_hash, account_class_hash, 2456);

    profileDispatcher
        .set_profile_metadata_uri(
            profile_address.try_into().unwrap(),
            "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaYXr4gQ/"
        );

    // test profile URI
    let profile_uri = profileDispatcher.get_profile_metadata(profile_address.try_into().unwrap());
    assert(
        profile_uri == "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaYXr4gQ/",
        'invalid profile URI'
    );

    stop_cheat_caller_address(profile_contract_address);
    stop_cheat_caller_address(nft_contract_address);
}

#[test]
fn test_profile_creation_event() {
    let (
        nft_contract_address, _, registry_class_hash, account_class_hash, profile_contract_address
    ) =
        __setup__();
    let karstNFTDispatcher = IKarstNFTDispatcher { contract_address: nft_contract_address };
    let profileDispatcher = IProfileDispatcher { contract_address: profile_contract_address };
    let mut spy = spy_events();

    //user 1 create profile
    start_cheat_caller_address(profile_contract_address, USER.try_into().unwrap());
    start_cheat_caller_address(nft_contract_address, USER.try_into().unwrap());

    let profile_address = profileDispatcher
        .create_profile(nft_contract_address, registry_class_hash, account_class_hash, 2456,);

    let token_id = karstNFTDispatcher.get_user_token_id(USER.try_into().unwrap());

    let expected_event = ProfileEvent::CreatedProfile(
        CreatedProfile {
            owner: USER.try_into().unwrap(),
            profile_address,
            token_id,
            timestamp: get_block_timestamp()
        }
    );

    spy.assert_emitted(@array![(profile_contract_address, expected_event)]);

    stop_cheat_caller_address(profile_contract_address);
    stop_cheat_caller_address(nft_contract_address);
}
