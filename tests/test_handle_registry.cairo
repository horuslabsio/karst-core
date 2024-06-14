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

fn __setup__() { // should contain any actions or logic to be carried out before a test is run
}
// *************************************************************************
//                              TEST
// *************************************************************************

#[test]
fn test_link_should_emit_linked_event() {
    // Deploy the contract and get its address
    let (handle_registry, handle_registry_address) = deploy_handle_registry();

    // Define test parameters
    let handle_id: u256 = 123;
    let profile_address: ContractAddress = contract_address_const::<'profile_address'>();

    // Start the prank to simulate a caller
    start_prank(handle_registry_address, caller());

    // Call the link function
    handle_registry.link(handle_id, profile_address);

    // Stop the prank
    stop_prank(handle_registry_address);

    // Verify that the Linked event was emitted
    let linked_event = fetch_linked_event(handle_registry_address);
    assert_eq!(linked_event.handle_id, handle_id);
    assert_eq!(linked_event.profile_address, profile_address);
    assert_eq!(linked_event.caller, caller());
    assert_ne!(linked_event.timestamp, 0); // Verify timestamp is set
}

#[test]
fn test_unlink_should_emit_unlinked_event() {
    // Deploy the contract and get its address
    let (handle_registry, handle_registry_address) = deploy_handle_registry();

    // Define test parameters
    let handle_id: u256 = 123;
    let profile_address: ContractAddress = contract_address_const::<'profile_address'>();

    // Start the prank to simulate a caller
    start_prank(handle_registry_address, caller());

    // Call the link function
    handle_registry.link(handle_id, profile_address);

    // Call the unlink function
    handle_registry.unlink(handle_id, profile_address);

    // Stop the prank
    stop_prank(handle_registry_address);

    // Verify that the Unlinked event was emitted
    let unlinked_event = fetch_unlinked_event(handle_registry_address);
    assert_eq!(unlinked_event.handle_id, handle_id);
    assert_eq!(unlinked_event.profile_address, profile_address);
    assert_eq!(unlinked_event.caller, caller());
    assert_ne!(unlinked_event.timestamp, 0); // Verify timestamp is set
}
