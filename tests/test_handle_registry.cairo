use core::option::OptionTrait;
use core::starknet::SyscallResultTrait;
use core::result::ResultTrait;
use core::traits::{TryInto, Into};
use starknet::{ContractAddress, get_block_timestamp};
use snforge_std::{
    declare, ContractClassTrait, CheatTarget, start_prank, stop_prank, start_warp, stop_warp,
    spy_events, SpyOn, EventAssertions, EventFetcher
};
use starknet::get_caller_address;

use karst::interfaces::IHandleRegistry::{IHandleRegistryDispatcher, IHandleRegistryDispatcherTrait};
use karst::interfaces::IHandle::{IHandleDispatcher, IHandleDispatcherTrait};
use karst::namespaces::handle_registry::HandleRegistry;
use karst::namespaces::handle_registry::HandleRegistry::{Event as LinkedEvent, HandleLinked};
use karst::namespaces::handle_registry::HandleRegistry::{Event as UnlinkedEvent, HandleUnlinked};


const ADMIN_ADDRESS: felt252 = 'ADMIN';
const USER_ONE: felt252 = 'BOB';
const USER_TWO: felt252 = 'JOHN';
const TEST_LOCAL_NAME: felt252 = 'user';

const PROFILE_ADDRESS: felt252 = 'PROFILE';
const HANDLE_ADDRESS: felt252 = 'HANDLE';
const PROFILE_ID: u256 = 1234;
const HANDLE_ID: u256 = 1234;

fn __setup__() -> (ContractAddress, ContractAddress) {
    // deploy handle contract
    let handle_class_hash = declare("Handles").unwrap();
    let mut calldata: Array<felt252> = array![ADMIN_ADDRESS];
    let (handle_contract_address, _) = handle_class_hash.deploy(@calldata).unwrap_syscall();

    // deploy handle registry contract
    let handle_registry_class_hash = declare("HandleRegistry").unwrap();
    let mut calldata: Array<felt252> = array![handle_contract_address.into()];
    let (handle_registry_contract_address, _) = handle_registry_class_hash
        .deploy(@calldata)
        .unwrap_syscall();

    return (handle_registry_contract_address, handle_contract_address);
}

// *************************************************************************
//                              TEST
// *************************************************************************

#[test]
#[should_panic(expected: ('Karst: handle does not exist!',))]
fn test_cannot_resolve_if_handle_does_not_exist() {
    let (handle_registry_contract_address, _) = __setup__();
    let dispatcher = IHandleRegistryDispatcher {
        contract_address: handle_registry_contract_address
    };
    dispatcher.resolve(1234);
}

#[test]
fn test_resolve() {
    let (handle_registry_contract_address, handle_contract_address) = __setup__();

    // Initialize Dispatchers
    let handle_registry_dispatcher = IHandleRegistryDispatcher {
        contract_address: handle_registry_contract_address
    };
    let handle_dispatcher = IHandleDispatcher { contract_address: handle_contract_address };

    // Mint Handle to USER_ONE
    start_prank(CheatTarget::One(handle_contract_address), ADMIN_ADDRESS.try_into().unwrap());
    let token_id = handle_dispatcher.mint_handle(USER_ONE.try_into().unwrap(), TEST_LOCAL_NAME);

    // Link handle to USER_ONE
    handle_registry_dispatcher.link(token_id, USER_ONE.try_into().unwrap());

    assert(
        handle_registry_dispatcher.resolve(token_id) == USER_ONE.try_into().unwrap(),
        'INCORRECT PROFILE ID'
    );
}

#[test]
fn test_link() {
    let (handle_registry_address, handle_contract_address) = __setup__();
    let registryDispatcher = IHandleRegistryDispatcher {
        contract_address: handle_registry_address
    };
    let handleDispatcher = IHandleDispatcher { contract_address: handle_contract_address };

    // mint handle
    let handle_id = handleDispatcher.mint_handle(USER_ONE.try_into().unwrap(), TEST_LOCAL_NAME);

    // link token to profile
    registryDispatcher.link(handle_id, USER_ONE.try_into().unwrap());

    // check profile was linked
    let retrieved_handle = registryDispatcher.get_handle(USER_ONE.try_into().unwrap());
    assert(retrieved_handle == handle_id, 'linking failed');
}

#[test]
#[should_panic(expected: ('Karst: profile is not owner!',))]
fn test_linking_fails_if_profile_address_is_not_owner() {
    let (handle_registry_address, handle_contract_address) = __setup__();
    let registryDispatcher = IHandleRegistryDispatcher {
        contract_address: handle_registry_address
    };
    let handleDispatcher = IHandleDispatcher { contract_address: handle_contract_address };

    // mint handle
    let handle_id = handleDispatcher.mint_handle(USER_ONE.try_into().unwrap(), TEST_LOCAL_NAME);

    // link token to profile
    registryDispatcher.link(handle_id, USER_TWO.try_into().unwrap());
}

#[test]
#[should_panic(expected: ('Karst: handle already linked!',))]
fn test_does_not_link_twice_for_same_handle() {
    let (handle_registry_address, handle_contract_address) = __setup__();
    let registryDispatcher = IHandleRegistryDispatcher {
        contract_address: handle_registry_address
    };
    let handleDispatcher = IHandleDispatcher { contract_address: handle_contract_address };

    // mint handle
    let handle_id = handleDispatcher.mint_handle(USER_ONE.try_into().unwrap(), TEST_LOCAL_NAME);

    // link token to profile
    registryDispatcher.link(handle_id, USER_ONE.try_into().unwrap());

    // try linking again
    registryDispatcher.link(handle_id, USER_ONE.try_into().unwrap());
}

#[test]
fn test_unlink() {
    let (handle_registry_address, handle_contract_address) = __setup__();
    let registryDispatcher = IHandleRegistryDispatcher {
        contract_address: handle_registry_address
    };
    let handleDispatcher = IHandleDispatcher { contract_address: handle_contract_address };

    // mint handle
    let handle_id = handleDispatcher.mint_handle(USER_ONE.try_into().unwrap(), TEST_LOCAL_NAME);

    // link token to profile
    registryDispatcher.link(handle_id, USER_ONE.try_into().unwrap());

    // call unlink
    start_prank(CheatTarget::One(handle_registry_address), USER_ONE.try_into().unwrap());
    registryDispatcher.unlink(handle_id, USER_ONE.try_into().unwrap());

    // check it unlinks successfully
    let retrieved_handle = registryDispatcher.get_handle(USER_ONE.try_into().unwrap());
    assert(retrieved_handle == 0, 'unlinking failed');
    stop_prank(CheatTarget::One(handle_registry_address));
}


#[test]
#[should_panic(expected: ('Karst: caller is not owner!',))]
fn test_unlink_fails_if_caller_is_not_owner() {
    let (handle_registry_address, handle_contract_address) = __setup__();
    let registryDispatcher = IHandleRegistryDispatcher {
        contract_address: handle_registry_address
    };
    let handleDispatcher = IHandleDispatcher { contract_address: handle_contract_address };

    // mint handle
    let handle_id = handleDispatcher.mint_handle(USER_ONE.try_into().unwrap(), TEST_LOCAL_NAME);

    // link token to profile
    registryDispatcher.link(handle_id, USER_ONE.try_into().unwrap());

    // call unlink
    start_prank(CheatTarget::One(handle_registry_address), USER_TWO.try_into().unwrap());
    registryDispatcher.unlink(handle_id, USER_ONE.try_into().unwrap());
    stop_prank(CheatTarget::One(handle_registry_address));
}

#[test]
fn test_emmit_linked_event() {
    let (handle_registry_address, handle_contract_address) = __setup__();
    let registryDispatcher = IHandleRegistryDispatcher {
        contract_address: handle_registry_address
    };
    let handleDispatcher = IHandleDispatcher { contract_address: handle_contract_address };
    let mut spy = spy_events(SpyOn::One(handle_registry_address));

    // mint handle
    let handle_id = handleDispatcher.mint_handle(USER_ONE.try_into().unwrap(), TEST_LOCAL_NAME);

    start_prank(CheatTarget::One(handle_registry_address), USER_ONE.try_into().unwrap());

    // link token to profile
    registryDispatcher.link(handle_id, USER_ONE.try_into().unwrap());

    let expected_event = LinkedEvent::Linked(
        HandleLinked {
            handle_id: handle_id,
            profile_address: USER_ONE.try_into().unwrap(),
            caller: USER_ONE.try_into().unwrap(),
            timestamp: get_block_timestamp()
        }
    );
    spy.assert_emitted(@array![(handle_registry_address, expected_event)]);
    stop_prank(CheatTarget::One(handle_registry_address));
}

#[test]
fn test_emmit_unlinked_event() {
    let (handle_registry_address, handle_contract_address) = __setup__();
    let registryDispatcher = IHandleRegistryDispatcher {
        contract_address: handle_registry_address
    };
    let handleDispatcher = IHandleDispatcher { contract_address: handle_contract_address };
    let mut spy = spy_events(SpyOn::One(handle_registry_address));

    // mint handle
    let handle_id = handleDispatcher.mint_handle(USER_ONE.try_into().unwrap(), TEST_LOCAL_NAME);

    // link token to profile
    registryDispatcher.link(handle_id, USER_ONE.try_into().unwrap());

    start_prank(CheatTarget::One(handle_registry_address), USER_ONE.try_into().unwrap());

    // call unlink
    registryDispatcher.unlink(handle_id, USER_ONE.try_into().unwrap());

    let expected_event = UnlinkedEvent::Unlinked(
        HandleUnlinked {
            handle_id: handle_id,
            profile_address: USER_ONE.try_into().unwrap(),
            caller: USER_ONE.try_into().unwrap(),
            timestamp: get_block_timestamp()
        }
    );
    spy.assert_emitted(@array![(handle_registry_address, expected_event)]);
    stop_prank(CheatTarget::One(handle_registry_address));
}
