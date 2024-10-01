use starknet::ContractAddress;
#[starknet::interface]
pub trait ICollectNFT<TState> {
    // *************************************************************************
    //                            EXTERNALS
    // *************************************************************************
    fn mint_nft(ref self: TState, address: ContractAddress) -> u256;
    // *************************************************************************
    //                            GETTERS
    // *************************************************************************
    fn get_last_minted_id(self: @TState) -> u256;
    fn get_user_token_id(self: @TState, user: ContractAddress) -> u256;
    fn get_token_mint_timestamp(self: @TState, token_id: u256) -> u64;
    fn get_source_publication_pointer(self: @TState) -> (ContractAddress, u256);
    // *************************************************************************
    //                            METADATA
    // *************************************************************************   
    fn name(self: @TState) -> ByteArray;
    fn symbol(self: @TState) -> ByteArray;
    fn token_uri(self: @TState, token_id: u256) -> ByteArray;
}
