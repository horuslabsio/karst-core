use starknet::ContractAddress;

// *************************************************************************
//                              INTERFACE of ICommunity NFT
// *************************************************************************
#[starknet::interface]
pub trait ICommunityNft<TContractState> {
    fn mint(ref self: TContractState, to: ContractAddress, token_id: u256);
    fn burn(ref self: TContractState, token_id: u256);
}
