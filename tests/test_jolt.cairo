use core::traits::TryInto;
use starknet::{ContractAddress, get_block_timestamp};
use snforge_std::{
    declare, start_cheat_caller_address, stop_cheat_caller_address, spy_events,
    EventSpyAssertionsTrait, ContractClassTrait, DeclareResultTrait, start_cheat_block_timestamp,
    stop_cheat_block_timestamp
};
use karst::interfaces::IJolt::{IJoltDispatcher, IJoltDispatcherTrait};
use karst::base::{
    constants::errors::Errors,
    constants::types::{joltData, joltParams, JoltType, JoltCurrency, JoltStatus, RenewalData}
};

const ADMIN: felt252 = 13245;
const ADDRESS1: felt252 = 53435;
const ADDRESS2: felt252 = 204925;
const ADDRESS3: felt252 = 249205;

// *************************************************************************
//                              SETUP
// *************************************************************************
fn __setup__() -> ContractAddress {
    let jolt_contract = declare("Jolt").unwrap().contract_class();
    let (jolt_contract_address, _) = jolt_contract.deploy(@array![ADMIN]).unwrap();
    return (jolt_contract_address);
}
// *************************************************************************
//                              TEST
// *************************************************************************


