// *************************************************************************
//                              COMMUNITY TEST
// *************************************************************************
use core::option::OptionTrait;
use core::starknet::SyscallResultTrait;
use core::result::ResultTrait;
use core::traits::{TryInto, Into};
use starknet::{ContractAddress, class_hash::ClassHash, contract_address_const, get_block_timestamp};

use snforge_std::{
    declare, start_cheat_caller_address, stop_cheat_caller_address, start_cheat_transaction_hash,
    start_cheat_nonce, spy_events, EventSpyAssertionsTrait, ContractClass, ContractClassTrait,
    DeclareResultTrait, start_cheat_block_timestamp, stop_cheat_block_timestamp, EventSpy
};

use token_bound_accounts::interfaces::IAccount::{IAccountDispatcher, IAccountDispatcherTrait};
use token_bound_accounts::presets::account::Account;
use karst::mocks::registry::Registry;
use karst::interfaces::IRegistry::{IRegistryDispatcher, IRegistryDispatcherTrait};
use karst::karstnft::karstnft::KarstNFT;
use karst::presets::community::KarstCommunity;

use karst::base::constants::types::{
    CommunityDetails, GateKeepType, CommunityType, CommunityMember, CommunityGateKeepDetails
};
use karst::interfaces::ICommunity::{ICommunityDispatcher, ICommunityDispatcherTrait};

const HUB_ADDRESS: felt252 = 'HUB';
const USER_ONE: felt252 = 'BOB';
const USER_TWO: felt252 = 'ALICE';
const USER_THREE: felt252 = 'ROB';
const USER_FOUR: felt252 = 'DAN';
const USER_FIVE: felt252 = 'RANDY';
const USER_SIX: felt252 = 'JOE';

// *************************************************************************
//                              SETUP
// *************************************************************************
fn __setup__() -> (ContractAddress, ContractAddress, ContractAddress, ContractAddress) {
    // deploy Karst NFT
    let nft_class_hash = declare("KarstNFT").unwrap().contract_class();
    let mut calldata: Array<felt252> = array![USER_ONE];
    let (karst_nft_contract_address, _) = nft_class_hash.deploy(@calldata).unwrap_syscall();

    // deploy handle contract
    let handle_class_hash = declare("Handles").unwrap().contract_class();
    let mut calldata: Array<felt252> = array![USER_ONE];
    let (handle_contract_address, _) = handle_class_hash.deploy(@calldata).unwrap_syscall();

    // deploy handle registry contract
    let handle_registry_class_hash = declare("HandleRegistry").unwrap().contract_class();
    let mut calldata: Array<felt252> = array![handle_contract_address.into()];
    let (handle_registry_contract_address, _) = handle_registry_class_hash
        .deploy(@calldata)
        .unwrap_syscall();

    // deploy community nft
    let community_nft_class_hash = declare("CommunityNft").unwrap().contract_class();

    // declare follownft
    let follow_nft_classhash = declare("Follow").unwrap().contract_class();

    // deploy hub contract
    let hub_class_hash = declare("KarstHub").unwrap().contract_class();
    let mut calldata: Array<felt252> = array![
        karst_nft_contract_address.into(),
        handle_contract_address.into(),
        handle_registry_contract_address.into(),
        (*follow_nft_classhash.class_hash).into()
    ];
    let (hub_contract_address, _) = hub_class_hash.deploy(@calldata).unwrap_syscall();

    // deploy community preset contract
    let community_contract = declare("KarstCommunity").unwrap().contract_class();
    let mut community_constructor_calldata: Array<felt252> = array![
        hub_contract_address.into(), (*community_nft_class_hash.class_hash).into(),
    ];
    let (community_contract_address, _) = community_contract
        .deploy(@community_constructor_calldata)
        .unwrap_syscall();

    return (
        community_contract_address,
        karst_nft_contract_address,
        handle_contract_address,
        handle_registry_contract_address,
    );
}

// *************************************************************************
//                              TESTS
// *************************************************************************
#[test]
fn test_creation_community() {
    let (
        community_contract_address,
        karst_nft_contract_address,
        handle_contract_address,
        handle_registry_contract_address,
    ) =
        __setup__();
    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_comminuty();
    assert(community_id == 1, 'invalid community creation');
    stop_cheat_caller_address(community_contract_address);
}


#[test]
fn test_join_community() {
    let (
        community_contract_address,
        karst_nft_contract_address,
        handle_contract_address,
        handle_registry_contract_address,
    ) =
        __setup__();
    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    //create the community
    let community_id = communityDispatcher.create_comminuty();
    // join the community
    communityDispatcher.join_community(community_id);
    let (is_member, community) = communityDispatcher
        .is_community_member(USER_ONE.try_into().unwrap(), community_id);
    println!("is member: {}", is_member);
    assert(is_member == true, 'Not Community Member');
    stop_cheat_caller_address(community_contract_address);
}

#[test]
#[should_panic(expected: ('Karst: already a Member',))]
fn test_should_panic_join_one_community_twice() {
    let (
        community_contract_address,
        karst_nft_contract_address,
        handle_contract_address,
        handle_registry_contract_address,
    ) =
        __setup__();
    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());

    let community_id = communityDispatcher.create_comminuty();

    communityDispatcher.join_community(community_id);
    communityDispatcher.join_community(community_id);
}


#[test]
fn test_leave_community() {
    let (
        community_contract_address,
        karst_nft_contract_address,
        handle_contract_address,
        handle_registry_contract_address,
    ) =
        __setup__();
    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    //create the community
    let community_id = communityDispatcher.create_comminuty();
    // join the community
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_TWO.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    // leave community
    start_cheat_caller_address(community_contract_address, USER_TWO.try_into().unwrap());
    communityDispatcher.leave_community(community_id);

    let (is_member, community) = communityDispatcher
        .is_community_member(USER_TWO.try_into().unwrap(), community_id);
    println!("is member: {}", is_member);
    assert(is_member != true, 'A Community Member');

    stop_cheat_caller_address(community_contract_address);
}


#[test]
#[should_panic(expected: ('Karst: Not a Community  Member',))]
fn test_should_panic_not_member() {
    let (
        community_contract_address,
        karst_nft_contract_address,
        handle_contract_address,
        handle_registry_contract_address,
    ) =
        __setup__();
    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    //create the community
    let community_id = communityDispatcher.create_comminuty();
    // join the community
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    // leave community
    start_cheat_caller_address(community_contract_address, USER_TWO.try_into().unwrap());
    communityDispatcher.leave_community(community_id);
}


#[test]
fn test_set_community_metadata_uri() {
    let (
        community_contract_address,
        karst_nft_contract_address,
        handle_contract_address,
        handle_registry_contract_address,
    ) =
        __setup__();
    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_comminuty();
    let metadata_uri = "ipfs://helloworld";
    communityDispatcher.set_community_metadata_uri(community_id, metadata_uri);
    let result_meta_uri = communityDispatcher.get_community_metadata_uri(community_id);
    assert(result_meta_uri == "ipfs://helloworld", 'invalid uri');
    stop_cheat_caller_address(community_contract_address);
}

#[test]
#[should_panic(expected: ('Karst: Not Community owner',))]
fn test_should_panic_set_community_metadata_uri() {
    let (
        community_contract_address,
        karst_nft_contract_address,
        handle_contract_address,
        handle_registry_contract_address,
    ) =
        __setup__();
    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_comminuty();

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_THREE.try_into().unwrap());
    let metadata_uri = "ipfs://helloworld";
    communityDispatcher.set_community_metadata_uri(community_id, metadata_uri);
}


#[test]
fn test_add_community_mod() {
    let (
        community_contract_address,
        karst_nft_contract_address,
        handle_contract_address,
        handle_registry_contract_address,
    ) =
        __setup__();
    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_comminuty();
    // add a community mod
    communityDispatcher.add_community_mods(community_id, USER_SIX.try_into().unwrap());

    // check a community mod - is_community_mod
    let is_community_mod = communityDispatcher
        .is_community_mod(USER_SIX.try_into().unwrap(), community_id);
    assert(is_community_mod == true, 'Not a Community Mod');
    stop_cheat_caller_address(community_contract_address);
}


#[test]
#[should_panic(expected: ('Karst: Not Community owner',))]
fn test_should_panic_add_community_mod() {
    let (
        community_contract_address,
        karst_nft_contract_address,
        handle_contract_address,
        handle_registry_contract_address,
    ) =
        __setup__();
    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_comminuty();

    stop_cheat_caller_address(community_contract_address);

    // when a wrong community owner try to add a MOD
    start_cheat_caller_address(community_contract_address, USER_TWO.try_into().unwrap());

    // add a community mod
    communityDispatcher.add_community_mods(community_id, USER_SIX.try_into().unwrap());
}
