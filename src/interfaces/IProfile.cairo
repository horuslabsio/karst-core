use starknet::ContractAddress;
use karst::base::types::Profile;
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
    fn get_profile_metadata(self: @TState, user: ContractAddress) -> ByteArray;
    fn get_profile_owner(self: @TState, user: ContractAddress) -> ContractAddress;
    fn get_profile_details(
        self: @TState, profile_address: ContractAddress
    ) -> (u256, ByteArray, ContractAddress, ContractAddress);
    fn get_profile(self: @TState, profile_address: ContractAddress) -> Profile;
}
