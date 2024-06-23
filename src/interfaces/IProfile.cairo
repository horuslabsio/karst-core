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
    fn initialize(ref self: TState, hub_address: ContractAddress);
    fn create_profile(
        ref self: TState,
        karstnft_contract_address: ContractAddress,
        registry_hash: felt252,
        implementation_hash: felt252,
        salt: felt252,
        recipient: ContractAddress
    ) -> ContractAddress;
    fn set_profile_metadata_uri(
        ref self: TState, profile_address: ContractAddress, metadata_uri: ByteArray
    );
    fn increment_publication_count(ref self: TState, profile_address: ContractAddress) -> u256;
    // *************************************************************************
    //                              GETTERS
    // *************************************************************************
    fn get_profile_metadata(self: @TState, profile_address: ContractAddress) -> ByteArray;
    fn get_profile(ref self: TState, profile_address: ContractAddress) -> Profile;
    fn get_user_publication_count(self: @TState, profile_address: ContractAddress) -> u256;
}
