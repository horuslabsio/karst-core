use starknet::ContractAddress;
use karst::base::constants::types::{joltParams, joltData};

#[starknet::interface]
pub trait IJolt<TState> {
	// *************************************************************************
    //                              EXTERNALS
    // *************************************************************************
	fn jolt(ref self: TState, jolt_params: joltParams) -> bool;
	fn set_fee_address(ref self: TState, _fee_address: ContractAddress);
	fn auto_renew(ref self: TState, profile: ContractAddress, renewal_id: u256) -> bool;
	// *************************************************************************
    //                              GETTERS
    // *************************************************************************
	fn get_jolt(self: @TState, jolt_id: u256) -> joltData;
	fn total_jolts_received(self: @TState, profile: ContractAddress) -> u256;
	fn get_fee_address(self: @TState) -> ContractAddress;
}