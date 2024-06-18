use core::option::OptionTrait;
use core::starknet::SyscallResultTrait;
use core::result::ResultTrait;
use core::traits::{TryInto, Into};
use starknet::{ContractAddress};
use snforge_std::{
    declare, ContractClassTrait, CheatTarget, start_prank, stop_prank, start_warp, stop_warp
};

use karst::interfaces::IHandleRegistry::{IHandleRegistryDispatcher, IHandleRegistryDispatcherTrait};
use karst::namespaces::handle_registry::HandleRegistry;


const HUB_ADDRESS: felt252 = 'HUB';
const ADMIN_ADDRESS: felt252 = 'ADMIN';
const PROFILE_ADDRESS: felt252 = 'PROFILE';
const HANDLE_ADDRESS: felt252 = 'HANDLE';
const PROFILE_ID: u256 = 1234;
const HANDLE_ID: u256 = 1234;

fn __deploy_handles_contract() -> ContractAddress {
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

fn __setup__() -> ContractAddress {
    let handles_contract_address = __deploy_handles_contract();
    let handle_registry_class_hash = declare("HandleRegistry").unwrap();

    let mut calldata: Array<felt252> = array![];
    HUB_ADDRESS.serialize(ref calldata);
    handles_contract_address.serialize(ref calldata);
    let (handle_registry_contract_address, _) = handle_registry_class_hash
        .deploy(@calldata)
        .unwrap_syscall();
    handle_registry_contract_address
}
// *********************************************************************
//                              TEST
// *********************************************************************

#[test]
#[should_panic(expected: ('Handle ID does not exist',))]
fn test_cannot_resolve_if_handle_does_not_exist() {
    let contract_address = __setup__();
    let dispatcher = IHandleRegistryDispatcher { contract_address };
    dispatcher.resolve(1234);
}

#[test]
fn test_resolve() {
    let contract_address = __setup__();
    let dispatcher = IHandleRegistryDispatcher { contract_address };
    start_prank(CheatTarget::One(contract_address), HUB_ADDRESS.try_into().unwrap());
    dispatcher.link(HANDLE_ID, PROFILE_ADDRESS.try_into().unwrap());

    assert(
        dispatcher.resolve(HANDLE_ID) == PROFILE_ADDRESS.try_into().unwrap(), 'INCORRECT PROFILE ID'
    );
}
