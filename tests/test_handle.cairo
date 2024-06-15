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
fn __setup__() -> ContractAddress {
    // deploy handles
    let handles_class_hash = declare("Handles").unwrap();
    let admin: ContractAddress = ADMIN_ADDRESS.try_into().unwrap();
    let symbol: ByteArray = "HNFT";
    let name: ByteArray = "HANDLES_HUB";
    let mut calldata: Array<felt252> = array![USER_ONE];
    admin.serialize(ref calldata);
    symbol.serialize(ref calldata);
    name.serialize(ref calldata);
    let (handles_contract_address, _) = handles_class_hash.deploy(@calldata).unwrap_syscall();

    handles_contract_address
}
// *************************************************************************
//                              TEST
// *************************************************************************

#[test]
fn test_mint_handle() {
    let handles_contract_address = __setup__();
    let _handles_dispatcher = IHandleDispatcher { contract_address: handles_contract_address };
// start_prank(
//     CheatTarget::Multiple(array![publication_contract_address, profile_contract_address]),
//     USER_ONE.try_into().unwrap()
// );

// let publication_type = publication_dispatcher
//     .get_publication_type(user_one_profile_address, user_one_first_post_pointed_pub_id);
// assert(publication_type == PublicationType::Post, 'invalid pub_type');

// stop_prank(
//     CheatTarget::Multiple(array![publication_contract_address, profile_contract_address]),
// );
}

