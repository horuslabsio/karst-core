use starknet::ContractAddress;
use karst::base::constants::types::{JoltParams, JoltData, SubscriptionData};

#[starknet::interface]
pub trait IJolt<TState> {
    // *************************************************************************
    //                              EXTERNALS
    // *************************************************************************
    fn jolt(ref self: TState, jolt_params: JoltParams) -> u256;
    fn auto_renew(ref self: TState, profile: ContractAddress, jolt_id: u256) -> bool;
    fn fulfill_request(ref self: TState, jolt_id: u256) -> bool;
    fn create_subscription(
        ref self: TState, 
        fee_address: ContractAddress, 
        amount: u256, 
        erc20_contract_address: ContractAddress
    );
    fn set_fee_address(ref self: TState, _fee_address: ContractAddress);
    // *************************************************************************
    //                              GETTERS
    // *************************************************************************
    fn get_jolt(self: @TState, jolt_id: u256) -> JoltData;
    fn get_subscription_data(self: @TState, subscription_id: u256) -> SubscriptionData;
    fn get_fee_address(self: @TState) -> ContractAddress;
}
