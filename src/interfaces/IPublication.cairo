// *************************************************************************
//                              INTERFACE of KARST PUBLICATIONS
// *************************************************************************
use starknet::ContractAddress;
use karst::base::constants::types::{
    PostParams, MirrorParams, ReferencePubParams, PublicationType, Publication, QuoteParams
};

#[starknet::interface]
pub trait IKarstPublications<TState> {
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
        ref self: TState,
        mirrorParams: MirrorParams,
        profile_contract_address: ContractAddress
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
