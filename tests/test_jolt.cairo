use core::traits::TryInto;
use starknet::{ContractAddress, get_block_timestamp};
use snforge_std::{
    declare, start_cheat_caller_address, stop_cheat_caller_address, spy_events,
    EventSpyAssertionsTrait, ContractClassTrait, DeclareResultTrait, start_cheat_block_timestamp,
    stop_cheat_block_timestamp
};
use karst::interfaces::IJolt::{IJoltDispatcher, IJoltDispatcherTrait};

const ADMIN: felt252 = 13245;

// *************************************************************************
//                              SETUP
// *************************************************************************
fn __setup__() -> ContractAddress {
    let jolt_contract = declare("Jolt").unwrap().contract_class();
    let (jolt_contract_address, _) = jolt_contract
        .deploy(@array![ADMIN])
        .unwrap();
    return (jolt_contract_address);
}

// *************************************************************************
//                              TEST
// *************************************************************************
#[test]
fn test_constructor() {
    let jolt_contract_address = __setup__();
    let dispatcher = IJoltDispatcher{ contract_address: jolt_contract_address };
    let owner = dispatcher.owner();
    assert(owner == ADMIN.try_into().unwrap(), 'invalid owner!');
}