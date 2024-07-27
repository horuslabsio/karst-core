use starknet::ContractAddress;
use karst::base::constants::types::{
    Profile, PublicationType, Publication, MirrorParams, QuoteParams, PostParams, CommentParams
};
// *************************************************************************
//                              INTERFACE of KARST PROFILE
// *************************************************************************
#[starknet::interface]
pub trait IComposable<TState> {
    // *************************************************************************
    //                              EXTERNALS
    // *************************************************************************
    fn initializer(
        ref self: TState,
        karst_nft_address: ContractAddress,
        hub_address: ContractAddress,
        follow_nft_classhash: felt252
    );
    fn create_profile(
        ref self: TState,
        karstnft_contract_address: ContractAddress,
        registry_hash: felt252,
        implementation_hash: felt252,
        salt: felt252
    ) -> ContractAddress;
    fn set_profile_metadata_uri(
        ref self: TState, profile_address: ContractAddress, metadata_uri: ByteArray
    );
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
    fn post(ref self: TState, post_params: PostParams) -> u256;
    fn comment(ref self: TState, comment_params: CommentParams) -> u256;
    fn quote(ref self: TState, quote_params: QuoteParams) -> u256;
    fn mirror(ref self: TState, mirror_params: MirrorParams) -> u256;
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
