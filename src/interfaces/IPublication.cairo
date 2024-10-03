// *************************************************************************
//                              INTERFACE of KARST PUBLICATIONS
// *************************************************************************
use starknet::ContractAddress;
use karst::base::constants::types::{
    PostParams, RepostParams, CommentParams, PublicationType, Publication
};

#[starknet::interface]
pub trait IKarstPublications<TState> {
    // *************************************************************************
    //                              EXTERNALS
    // *************************************************************************
    fn post(ref self: TState, post_params: PostParams) -> u256;
    fn comment(ref self: TState, comment_params: CommentParams) -> u256;
    fn repost(ref self: TState, repost_params: RepostParams) -> u256;
    fn upvote(ref self: TState, profile_address: ContractAddress, pub_id: u256);
    fn downvote(ref self: TState, profile_address: ContractAddress, pub_id: u256);
    fn tip(ref self: TState, profile_address: ContractAddress, pub_id: u256, amount: u256);
    fn collect(
        ref self: TState,
        karst_hub: ContractAddress,
        profile_address: ContractAddress,
        pub_id: u256,
        collect_nft_impl_class_hash: felt252,
        salt: felt252
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
    fn get_upvote_count(self: @TState, profile_address: ContractAddress, pub_id: u256) -> u256;
    fn get_downvote_count(self: @TState, profile_address: ContractAddress, pub_id: u256) -> u256;
    fn get_tipped_amount(self: @TState, profile_address: ContractAddress, pub_id: u256) -> u256;
}
