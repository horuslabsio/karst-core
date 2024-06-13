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

fn __setup__() { // should contain any actions or logic to be carried out before a test is run
}
// *************************************************************************
//                              TEST
// *************************************************************************

// Test to fail if handle burn function is called by non owner.
#[test]
#[should_panic(expected: 'NOT_OWNER')]
fn test_cannot_burn_if_not_owner_of() {
    let contract_address = __setup__();
    let dispatcher = IHandleDispatcher { contract_address };

    start_prank(CheatTarget::One(contract_address), Account::admin());
    let handle_id: u256 = dispatcher.mint_handle(Account::other_address(), 'handle');

    assert(dispatcher.exists(handle_id) == true, 'Handle ID does not exist');
    assert(dispatcher.ownerOf(handle_id) == Account::other_address(), 'Wrong Owner');

    start_prank(CheatTarget::One(contract_address), Account::other_address_2());
    dispatcher.burn_handle(handle_id);
}

#[test]
fn test_total_supply() {
    let contract_address = __setup__();
    let dispatcher = IHandleDispatcher { contract_address };

    let current_total_supply: u256 = dispatcher.total_supply();

    start_prank(CheatTarget::One(contract_address), Account::admin());
    let handle_id: u256 = dispatcher.mint_handle(Account::other_address(), 'handle');

    let total_supply_after_mint: u256 = dispatcher.total_supply();
    assert(total_supply_after_mint == current_total_supply + 1, "WRONG_TOTAL_SUPPLY");

    start_prank(CheatTarget::One(contract_address), Account::other_address());
    dispatcher.burn_handle(handle_id);

    let total_supply_after_burn: u256 = dispatcher.total_supply();
    assert(total_supply_after_burn == total_supply_after_mint - 1, "WRONG_TOTAL_SUPPLY");
}

#[test]
fn test_burn() {
    let contract_address = __setup__();
    let dispatcher = IHandleDispatcher { contract_address };

    start_prank(CheatTarget::One(contract_address), Account::admin());
    let handle_id: u256 = dispatcher.mintHandle(Account::other_address(), 'handle');

    assert(dispatcher.exists(handle_id) == true, 'Handle ID does not exist');
    assert(dispatcher.ownerOf(handleId) == Account::other_address(), 'Wrong Owner');

    start_prank(CheatTarget::One(contract_address), Account::other_address());
    dispatcher.burn_handle(handle_id);

    assert(dispatcher.exists(handle_id) == false, "BURN FAILED");
}
