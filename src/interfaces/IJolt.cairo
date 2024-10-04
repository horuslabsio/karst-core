use starknet::ContractAddress;
use karst::base::constants::types::{JoltParams, JoltData, RenewalData};

#[starknet::interface]
pub trait IJolt<TState> {
    // *************************************************************************
    //                              EXTERNALS
    // *************************************************************************
    fn jolt(ref self: TState, jolt_params: JoltParams) -> u256;
    fn auto_renew(ref self: TState, profile: ContractAddress, jolt_id: u256) -> bool;
    fn fulfill_request(ref self: TState, jolt_id: u256) -> bool;
    fn set_fee_address(ref self: TState, _fee_address: ContractAddress);
    // *************************************************************************
    //                              GETTERS
    // *************************************************************************
    fn get_jolt(self: @TState, jolt_id: u256) -> JoltData;
    fn get_renewal_data(self: @TState, profile: ContractAddress, jolt_id: u256) -> RenewalData;
    fn get_fee_address(self: @TState) -> ContractAddress;
}
