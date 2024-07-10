use starknet::ContractAddress;
use karst::base::types::{Profile, PublicationType, Publication, MirrorParams, QuoteParams};
// *************************************************************************
//                              INTERFACE of KARST PROFILE
// *************************************************************************
#[starknet::interface]
pub trait IComposable<TState> {
    // *************************************************************************
    //                              EXTERNALS
    // *************************************************************************
    fn initializer(ref self: TState, hub_address: ContractAddress);
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
    fn get_profile(self: @TState, profile_address: ContractAddress) -> Profile;
    fn get_user_publication_count(self: @TState, profile_address: ContractAddress) -> u256;

    // // *************************************************************************
    //                             PUBLICATION
    // *************************************************************************

    // *************************************************************************
    //                              EXTERNALS
    // *************************************************************************
    fn initialize(ref self: TState, hub_address: ContractAddress);
    fn post(
        ref self: TState,
        contentURI: ByteArray,
        profile_address: ContractAddress,
        profile_contract_address: ContractAddress,
    ) -> u256;
    fn comment(
        ref self: TState,
        profile_address: ContractAddress,
        reference_pub_type: PublicationType,
        content_URI: ByteArray,
        pointed_profile_address: ContractAddress,
        pointed_pub_id: u256,
        profile_contract_address: ContractAddress,
    ) -> u256;
    fn quote(
        ref self: TState,
        reference_pub_type: PublicationType,
        quoteParams: QuoteParams,
        profile_contract_address: ContractAddress
    ) -> u256;
    fn mirror(
        ref self: TState, mirrorParams: MirrorParams, profile_contract_address: ContractAddress
    ) -> u256;
    // *************************************************************************
    //                              GETTERS
    // *************************************************************************
    fn get_publication(
        self: @TState, profile_address: ContractAddress, pub_id_assigned: u256
    ) -> Publication;
    fn get_publication_type(
        self: @TState, profile_address: ContractAddress, pub_id_assigned: u256
    ) -> PublicationType;
    fn get_publication_content_uri(
        self: @TState, profile_address: ContractAddress, pub_id: u256
    ) -> ByteArray;
}
