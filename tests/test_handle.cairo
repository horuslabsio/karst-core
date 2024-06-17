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

// Dummy accounts for testing
mod Account {
    use starknet::ContractAddress;
    use core::traits::TryInto;

    fn admin() -> ContractAddress {
        'admin'.try_into().unwrap()
    }

    fn other_address() -> ContractAddress {
        'other'.try_into().unwrap()
    }

    fn other_address_2() -> ContractAddress {
        'other2'.try_into().unwrap()
    }
}

const HUB_ADDRESS: felt252 = 'HUB';

fn __setup__() -> ContractAddress {
    let handles_contract = declare("Handles").unwrap();
    let symbol: ByteArray = "OSH";
    let name: ByteArray = "Oshioke";
    let mut handles_constructor_calldata: Array<felt252> = array![Account::admin().into()];
    name.serialize(ref handles_constructor_calldata);
    symbol.serialize(ref handles_constructor_calldata);
    HUB_ADDRESS.serialize(ref handles_constructor_calldata);
    let (contract_address, _) = handles_contract
        .deploy(@handles_constructor_calldata)
        .unwrap_syscall();
    contract_address
}
// *************************************************************************
//                              TEST
// *************************************************************************

// Test to fail if handle burn function is called by non owner.
#[test]
#[should_panic(expected: ('Wrong owner',))]
fn test_cannot_burn_if_not_owner_of() {
    let contract_address = __setup__();
    let dispatcher = IHandleDispatcher { contract_address };
    let _erc721Dispatcher = IERC721Dispatcher { contract_address };

    start_prank(CheatTarget::One(contract_address), Account::admin());
    let handle_id: u256 = dispatcher.mint_handle(Account::other_address(), 'handle');

    assert(dispatcher.exists(handle_id), 'Handle ID does not exist');

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
    assert(total_supply_after_mint == current_total_supply + 1, 'WRONG_TOTAL_SUPPLY');

    start_prank(CheatTarget::One(contract_address), Account::other_address());
    dispatcher.burn_handle(handle_id);

    let total_supply_after_burn: u256 = dispatcher.total_supply();
    assert(total_supply_after_burn == total_supply_after_mint - 1, 'WRONG_TOTAL_SUPPLY');
}

#[test]
fn test_burn() {
    let contract_address = __setup__();
    let dispatcher = IHandleDispatcher { contract_address };
    let _erc721Dispatcher = IERC721Dispatcher { contract_address };

    start_prank(CheatTarget::One(contract_address), Account::admin());
    let handle_id: u256 = dispatcher.mint_handle(Account::other_address(), 'handle');

    assert(dispatcher.exists(handle_id) == true, 'Handle ID does not exist');
    assert(_erc721Dispatcher.owner_of(handle_id) == Account::other_address(), 'Wrong Owner');

    start_prank(CheatTarget::One(contract_address), Account::other_address());
    dispatcher.burn_handle(handle_id);

    assert(dispatcher.exists(handle_id) == false, 'BURN FAILED');
}
