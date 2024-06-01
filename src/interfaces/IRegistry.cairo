use starknet::ContractAddress;

// *************************************************************************
//                              INTERFACE of REGISTRY
// *************************************************************************
#[starknet::interface]
pub trait IRegistry<TContractState> {
    // *************************************************************************
    //                              EXTERNALS
    // *************************************************************************
    fn create_account(
        ref self: TContractState,
        implementation_hash: felt252,
        token_contract: ContractAddress,
        token_id: u256,
        salt: felt252
    ) -> ContractAddress;

    // *************************************************************************
    //                              GETTERS
    // *************************************************************************
    fn get_account(
        self: @TContractState,
        implementation_hash: felt252,
        token_contract: ContractAddress,
        token_id: u256,
        salt: felt252
    ) -> ContractAddress;
    fn total_deployed_accounts(
        self: @TContractState, token_contract: ContractAddress, token_id: u256
    ) -> u8;
}
