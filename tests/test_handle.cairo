use core::option::OptionTrait;
use core::starknet::SyscallResultTrait;
use core::result::ResultTrait;
use core::traits::{TryInto, Into};
use starknet::{ContractAddress};
use snforge_std::{
    declare, ContractClassTrait, CheatTarget, start_prank, stop_prank, start_warp, stop_warp
};

use karst::interfaces::IHandle::{IHandleDispatcher, IHandleDispatcherTrait};
use karst::interfaces::IERC721::{IERC721Dispatcher, IERC721DispatcherTrait};
use karst::namespaces::handles::Handles;


const HUB_ADDRESS: felt252 = 'HUB';
const ADMIN_ADDRESS: felt252 = 'ADMIN';
const USER_ONE: felt252 = 'BOB';
const USER_TWO: felt252 = 'JOHN';
const TEST_LOCAL_NAME: felt252 = 'karst';
const TEST_LOCAL_NAME_TWO: felt252 = 'karst_two';
const TEST_LOCAL_NAME_THREE: felt252 = 'karstdoe_';
const TEST_LOCAL_NAME_FOUR: felt252 = 'karstdoe2';
const TEST_BAD_LOCAL_NAME_1: felt252 = '_karst';
const TEST_BAD_LOCAL_NAME_2: felt252 = 'Karst';
const TEST_BAD_LOCAL_NAME_3: felt252 = 'karst-';

const TEST_TOKEN_ID: u256 =
    2821396919044486126129003092173544296283884532301009869065707438220168412703;


fn __setup__() -> ContractAddress {
    // deploy handles contract
    let handles_class_hash = declare("Handles").unwrap();
    let mut calldata: Array<felt252> = array![ADMIN_ADDRESS];
    HUB_ADDRESS.serialize(ref calldata);
    let (handles_contract_address, _) = handles_class_hash.deploy(@calldata).unwrap_syscall();
    handles_contract_address
}
// *********************************************************************
//                              TEST
// *********************************************************************

#[test]
fn test_mint_handle() {
    let handles_contract_address = __setup__();
    let handles_dispatcher = IHandleDispatcher { contract_address: handles_contract_address };

    start_prank(CheatTarget::One(handles_contract_address), USER_ONE.try_into().unwrap());
    let token_id = handles_dispatcher.mint_handle(USER_ONE.try_into().unwrap(), TEST_LOCAL_NAME);

    let local_name: felt252 = handles_dispatcher.get_local_name(token_id);
    assert(local_name == TEST_LOCAL_NAME, 'invalid local name');

    stop_prank(CheatTarget::One(handles_contract_address));
}


fn test_mint_handle_two() {
    // TODO: test total supply
    let handles_contract_address = __setup__();
    let handles_dispatcher = IHandleDispatcher { contract_address: handles_contract_address };

    start_prank(CheatTarget::One(handles_contract_address), USER_ONE.try_into().unwrap());
    let token_id = handles_dispatcher
        .mint_handle(USER_ONE.try_into().unwrap(), TEST_LOCAL_NAME_TWO);

    let local_name: felt252 = handles_dispatcher.get_local_name(token_id);
    assert(local_name == TEST_LOCAL_NAME_TWO, 'invalid local name two');

    stop_prank(CheatTarget::One(handles_contract_address));
}

#[test]
#[should_panic(expected: ('Karst: invalid local name!',))]
fn test_mint_handle_with_bad_local_name_1() {
    let handles_contract_address = __setup__();
    let handles_dispatcher = IHandleDispatcher { contract_address: handles_contract_address };

    start_prank(CheatTarget::One(handles_contract_address), USER_ONE.try_into().unwrap());
    handles_dispatcher.mint_handle(USER_ONE.try_into().unwrap(), TEST_BAD_LOCAL_NAME_1);
}

#[test]
#[should_panic(expected: ('Karst: invalid local name!',))]
fn test_mint_handle_with_bad_local_name_2() {
    let handles_contract_address = __setup__();
    let handles_dispatcher = IHandleDispatcher { contract_address: handles_contract_address };

    start_prank(CheatTarget::One(handles_contract_address), USER_ONE.try_into().unwrap());
    handles_dispatcher.mint_handle(USER_ONE.try_into().unwrap(), TEST_BAD_LOCAL_NAME_2);
}

#[test]
#[should_panic(expected: ('Karst: invalid local name!',))]
fn test_mint_handle_with_bad_local_name_3() {
    let handles_contract_address = __setup__();
    let handles_dispatcher = IHandleDispatcher { contract_address: handles_contract_address };

    start_prank(CheatTarget::One(handles_contract_address), USER_ONE.try_into().unwrap());
    handles_dispatcher.mint_handle(USER_ONE.try_into().unwrap(), TEST_BAD_LOCAL_NAME_3);
}

#[test]
fn test_get_token_id() {
    let handles_contract_address = __setup__();
    let handles_dispatcher = IHandleDispatcher { contract_address: handles_contract_address };

    start_prank(CheatTarget::One(handles_contract_address), USER_ONE.try_into().unwrap());
    let token_id = handles_dispatcher.get_token_id(TEST_LOCAL_NAME);
    assert!(token_id == TEST_TOKEN_ID, "Invalid token ID");

    stop_prank(CheatTarget::One(handles_contract_address));
}


#[test]
fn test_handle_id_exists_after_mint() {
    let contract_address = __setup__();
    let dispatcher = IHandleDispatcher { contract_address };
    let _erc721Dispatcher = IERC721Dispatcher { contract_address };

    start_prank(CheatTarget::One(contract_address), ADMIN_ADDRESS.try_into().unwrap());
    let handle_id: u256 = dispatcher.mint_handle(USER_ONE.try_into().unwrap(), 'handle');

    assert(dispatcher.exists(handle_id), 'Handle ID does not exist');
}

#[test]
fn test_total_supply() {
    let contract_address = __setup__();
    let dispatcher = IHandleDispatcher { contract_address };

    let current_total_supply: u256 = dispatcher.total_supply();

    start_prank(CheatTarget::One(contract_address), ADMIN_ADDRESS.try_into().unwrap());
    let handle_id: u256 = dispatcher.mint_handle(USER_ONE.try_into().unwrap(), 'handle');
    let total_supply_after_mint: u256 = dispatcher.total_supply();
    assert(total_supply_after_mint == current_total_supply + 1, 'WRONG_TOTAL_SUPPLY');

    start_prank(CheatTarget::One(contract_address), USER_ONE.try_into().unwrap());
    dispatcher.burn_handle(handle_id);

    let total_supply_after_burn: u256 = dispatcher.total_supply();
    assert(total_supply_after_burn == total_supply_after_mint - 1, 'WRONG_TOTAL_SUPPLY');
}

#[test]
fn test_burn() {
    let contract_address = __setup__();
    let dispatcher = IHandleDispatcher { contract_address };
    let _erc721Dispatcher = IERC721Dispatcher { contract_address };

    start_prank(CheatTarget::One(contract_address), ADMIN_ADDRESS.try_into().unwrap());
    let handle_id: u256 = dispatcher.mint_handle(USER_ONE.try_into().unwrap(), 'handle');

    assert(dispatcher.exists(handle_id) == true, 'Handle ID does not exist');
    assert(_erc721Dispatcher.owner_of(handle_id) == USER_ONE.try_into().unwrap(), 'Wrong Owner');

    start_prank(CheatTarget::One(contract_address), USER_ONE.try_into().unwrap());
    dispatcher.burn_handle(handle_id);

    assert(dispatcher.exists(handle_id) == false, 'BURN FAILED');
}

#[test]
#[should_panic(expected: ('Karst: caller is not owner!',))]
fn test_cannot_burn_if_not_owner_of() {
    let contract_address = __setup__();
    let dispatcher = IHandleDispatcher { contract_address };
    let _erc721Dispatcher = IERC721Dispatcher { contract_address };

    start_prank(CheatTarget::One(contract_address), ADMIN_ADDRESS.try_into().unwrap());
    let handle_id: u256 = dispatcher.mint_handle(USER_ONE.try_into().unwrap(), 'handle');

    assert(dispatcher.exists(handle_id), 'Handle ID does not exist');

    start_prank(CheatTarget::One(contract_address), USER_TWO.try_into().unwrap());
    dispatcher.burn_handle(handle_id);
}

#[test]
fn test_get_handle() {
    let handles_contract_address = __setup__();

    let handles_dispatcher = IHandleDispatcher { contract_address: handles_contract_address };

    start_prank(CheatTarget::One(handles_contract_address), USER_ONE.try_into().unwrap());

    let token_id = handles_dispatcher.mint_handle(USER_ONE.try_into().unwrap(), TEST_LOCAL_NAME);

    let handle: ByteArray = handles_dispatcher.get_handle(token_id);
    assert(handle == "karst.kst", 'Invalid handle');

    stop_prank(CheatTarget::One(handles_contract_address));
}

#[test]
#[should_panic(expected: ('Karst: handle does not exist!',))]
fn test_get_handle_should_panic() {
    let handles_contract_address = __setup__();

    let handles_dispatcher = IHandleDispatcher { contract_address: handles_contract_address };

    start_prank(CheatTarget::One(handles_contract_address), USER_ONE.try_into().unwrap());

    handles_dispatcher.get_handle(TEST_TOKEN_ID);
    stop_prank(CheatTarget::One(handles_contract_address));
}
