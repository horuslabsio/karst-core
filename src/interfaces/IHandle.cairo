use starknet::ContractAddress;

// *************************************************************************
//                              INTERFACE of HANDLE NFT 
// *************************************************************************
#[starknet::interface]
pub trait IHandle<TState> {
    // *************************************************************************
    //                              EXTERNALS
    // *************************************************************************
    fn mint_handle(ref self: TState, address: ContractAddress, local_name: felt252) -> u256;
    fn burn_handle(ref self: TState, token_id: u256);
    fn set_handle_token_uri(ref self: TState, token_id: u256, local_name: felt252);
    fn migrate_handle(ref self: TState, address: ContractAddress, local_name: felt252) -> u256;
    // *************************************************************************
    //                            GETTERS
    // *************************************************************************
    fn get_namespace(self: @TState) -> felt252;
    fn get_local_name(self: @TState, token_id: u256) -> felt252;
    fn get_handle(self: @TState, token_id: u256) -> ByteArray;
    fn exists(self: @TState, token_id: u256) -> bool;
    fn total_supply(self: @TState) -> u256;
    fn get_handle_token_uri(self: @TState, token_id: u256, local_name: felt252) -> ByteArray;
}
