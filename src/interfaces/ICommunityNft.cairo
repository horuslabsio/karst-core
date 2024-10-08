use starknet::ContractAddress;

// *************************************************************************
//                              INTERFACE of ICommunity NFT
// *************************************************************************
#[starknet::interface]
pub trait ICommunityNft<TContractState> {
    // *************************************************************************
    //                            EXTERNALS
    // *************************************************************************

    fn mint_nft(ref self: TContractState, user_address: ContractAddress) -> u256;
    fn burn_nft(ref self: TContractState, user_address: ContractAddress, token_id: u256);

    // *************************************************************************
    //                            GETTERS
    // *************************************************************************
    fn get_user_token_id(self: @TContractState, user_address: ContractAddress) -> u256;


    // *************************************************************************
    //                            METADATA
    // *************************************************************************
    fn name(self: @TContractState) -> ByteArray;
    fn symbol(self: @TContractState) -> ByteArray;
    fn token_uri(self: @TContractState, token_id: u256) -> ByteArray;
}
