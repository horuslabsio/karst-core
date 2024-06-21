use core::option::OptionTrait;
use core::starknet::SyscallResultTrait;
use core::result::ResultTrait;
use core::traits::{TryInto, Into};
use starknet::{ContractAddress, get_caller_address};
use snforge_std::{
    declare, ContractClassTrait, CheatTarget, start_prank, stop_prank, start_warp, stop_warp, spy_events, SpyOn
};
use karst::interfaces::IHandleRegistry::{IHandleRegistryDispatcher, IHandleRegistryDispatcherTrait};
use karst::namespaces::handle_registry::HandleRegistry;

#[derive(Drop, starknet::Event)]
struct HandleLinked {
    handle_id: u256,
    profile_address: ContractAddress,
    caller: ContractAddress,
    timestamp: u64
}

#[derive(Drop, starknet::Event)]
struct HandleUnlinked {
    handle_id: u256,
    profile_address: ContractAddress,
    caller: ContractAddress,
    timestamp: u64
}

fn __setup__() {
    // Any actions or logic to be carried out before a test is run


    // Helper function to deploy the HandleRegistry contract
    fn deploy_handle_registry() -> (HandleRegistry, ContractAddress) {
        let contract_class = declare(HandleRegistry::get_contract_class()).unwrap();
        let contract_address = contract_class.deploy().unwrap();
        let handle_registry: HandleRegistry = HandleRegistry::from_contract_address(contract_address);
        (handle_registry, contract_address)
    }

    // Define the caller address for the tests
    fn caller() -> ContractAddress {
        contract_address_const::<'caller'>()
    }
}

// *************************************************************************
//                              TEST
// *************************************************************************

#[test]
fn test_link_should_emit_linked_event_and_update_state() {
    // Deploy the contract and get its address
    let (handle_registry, handle_registry_address) = deploy_handle_registry();

    // Define test parameters
    let handle_id: u256 = 123;
    let profile_address: ContractAddress = contract_address_const::<'profile_address'>();

    // Start the prank to simulate a caller
    start_prank(caller());

    // Spy on events emitted by the contract
    let mut spy = spy_events(SpyOn::One(handle_registry_address));

    // Call the link function
    handle_registry.link(handle_id, profile_address);

    // Stop the prank
    stop_prank();

    // Verify that the Linked event was emitted
    let expected_event = HandleLinked { handle_id, profile_address, caller: caller(), timestamp: starknet::get_block_timestamp() };
    spy.assert_emitted(@array![(handle_registry_address, expected_event)]);

    // Verify the state was updated
    let resolved_address = handle_registry.resolve(handle_id);
    assert_eq!(resolved_address, profile_address);

    let handle = handle_registry.get_handle(profile_address);
    assert_eq!(handle, handle_id);
}

#[test]
fn test_unlink_should_emit_unlinked_event_and_update_state() {
    // Deploy the contract and get its address
    let (handle_registry, handle_registry_address) = deploy_handle_registry();

    // Define test parameters
    let handle_id: u256 = 123;
    let profile_address: ContractAddress = contract_address_const::<'profile_address'>();

    // Start the prank to simulate a caller
    start_prank(caller());

    // Spy on events emitted by the contract
    let mut spy = spy_events(SpyOn::One(handle_registry_address));

    // Call the link function
    handle_registry.link(handle_id, profile_address);

    // Call the unlink function
    handle_registry.unlink(handle_id, profile_address);

    // Stop the prank
    stop_prank();

    // Verify that the Unlinked event was emitted
    let expected_event = HandleUnlinked { handle_id, profile_address, caller: caller(), timestamp: starknet::get_block_timestamp() };
    spy.assert_emitted(@array![(handle_registry_address, expected_event)]);

    // Verify the state was updated
    let resolved_address = handle_registry.resolve(handle_id);
    assert_eq!(resolved_address, ContractAddress::zero());

    let handle = handle_registry.get_handle(profile_address);
    assert_eq!(handle, 0);
}
