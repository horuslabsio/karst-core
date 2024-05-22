use starknet::ContractAddress;
// *************************************************************************
//                              INTERFACE of KARST PROFILE
// *************************************************************************
#[starknet::interface]
pub trait IKarstProfile<TState> {
    // *************************************************************************
    //                              EXTERNALS
    // *************************************************************************
    fn create_profile(
        ref self: TState,
        karstnft_contract_address: ContractAddress,
        registry_hash: felt252,
        implementation_hash: felt252,
        salt: felt252
    );
    fn set_profile_metadata_uri(ref self: TState, metadata_uri: ByteArray);
    // *************************************************************************
    //                              GETTERS
    // *************************************************************************
    fn get_user_profile_address(self: @TState, user: ContractAddress) -> ContractAddress;
    fn get_profile(self: @TState, profile_id: ContractAddress) -> ByteArray;
    fn get_profile_owner_by_id(self: @TState, profile_id: ContractAddress) -> ContractAddress;
}
