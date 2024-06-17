use core::option::OptionTrait;
use core::starknet::SyscallResultTrait;
use core::result::ResultTrait;
use core::traits::{TryInto, Into};
use starknet::{ContractAddress};
use snforge_std::{
    declare, ContractClassTrait, CheatTarget, start_prank, stop_prank, start_warp, stop_warp
};

use karst::interfaces::IHandle::{IHandleDispatcher, IHandleDispatcherTrait};
use karst::namespaces::handles::Handles;


const HUB_ADDRESS: felt252 = 'HUB';
const ADMIN_ADDRESS: felt252 = 'ADMIN';
const USER_ONE: felt252 = 'BOB';
const TEST_LOCAL_NAME: felt252 = 'Karst';
const TEST_LOCAL_NAME_TWO: felt252 = 'KarstTwo';
const TEST_TOKEN_ID: u256 =
    2540877955141668895793685311412709713268096759973504917614769975982792961434;


fn __setup__() -> ContractAddress {
    // deploy handles contract
    let handles_class_hash = declare("Handles").unwrap();
    let symbol: ByteArray = "HNFT";
    let name: ByteArray = "HANDLES_HUB";
    let mut calldata: Array<felt252> = array![ADMIN_ADDRESS];
    name.serialize(ref calldata);
    symbol.serialize(ref calldata);
    HUB_ADDRESS.serialize(ref calldata);
    let (handles_contract_address, _) = handles_class_hash.deploy(@calldata).unwrap_syscall();
    handles_contract_address
}
// *************************************************************************
//                              TEST
// *************************************************************************

#[test]
fn test_total_supply() {
    let handles_contract_address = __setup__();

    let handles_dispatcher = IHandleDispatcher { contract_address: handles_contract_address };

    let total_supply_before = handles_dispatcher.total_supply();

    assert(total_supply_before == 0, 'total supply should be 0');

    start_prank(CheatTarget::One(handles_contract_address), USER_ONE.try_into().unwrap());

    handles_dispatcher.mint_handle(USER_ONE.try_into().unwrap(), TEST_LOCAL_NAME);

    let total_supply = handles_dispatcher.total_supply();

    assert(total_supply == total_supply_before + 1, 'total supply not incremented');

    stop_prank(CheatTarget::One(handles_contract_address));
}


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
fn test_get_token_id() {
    let handles_contract_address = __setup__();

    let handles_dispatcher = IHandleDispatcher { contract_address: handles_contract_address };

    start_prank(CheatTarget::One(handles_contract_address), USER_ONE.try_into().unwrap());

    let token_id = handles_dispatcher.get_token_id(TEST_LOCAL_NAME);

    assert!(token_id == TEST_TOKEN_ID, "Invalid token ID");

    stop_prank(CheatTarget::One(handles_contract_address));
}

