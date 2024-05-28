// *************************************************************************
//                              INTERFACE of KARST PUBLICATIONS
// *************************************************************************
use starknet::ContractAddress;
use karst::base::types::{PostParams, ReferencePubParams, PublicationType, Publication};

#[starknet::interface]
pub trait IKarstPublications<T> {
    fn post(
        ref self: T,
        contentURI: ByteArray,
        profile_address: ContractAddress,
        profile_contract_address: ContractAddress
    ) -> u256;
    // fn comment(
    //     ref self: T, referencePubParams: ReferencePubParams, profile_address: ContractAddress
    // ) -> u256;
    // fn get_content_uri(self: @T, user: ContractAddress) -> ByteArray;
    // fn get_pub_type(self: @T, user: ContractAddress) -> Option<PublicationType>;
    fn get_publication(self: @T, user: ContractAddress, pubIdAssigned: u256) -> Publication;
}
