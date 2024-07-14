// *************************************************************************
//                              INTERFACE of KARST PUBLICATIONS
// *************************************************************************
use starknet::ContractAddress;
use karst::base::constants::types::{
    PostParams, MirrorParams, CommentParams, PublicationType, Publication, QuoteParams
};

#[starknet::interface]
pub trait IKarstPublications<TState> {
    // *************************************************************************
    //                              EXTERNALS
    // *************************************************************************
    fn initialize(ref self: TState, hub_address: ContractAddress);
    fn post(
        ref self: TState,
        post_params: PostParams
    ) -> u256;
    fn comment(
        ref self: TState,
        comment_params: CommentParams
    ) -> u256;
    fn quote(
        ref self: TState,
        quote_params: QuoteParams
    ) -> u256;
    fn mirror(
        ref self: TState,
        mirror_params: MirrorParams
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
