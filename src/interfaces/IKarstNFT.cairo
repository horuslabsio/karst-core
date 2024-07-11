use starknet::ContractAddress;
// *************************************************************************
//                              INTERFACE of KARST NFT
// *************************************************************************
#[starknet::interface]
pub trait IKarstNFT<TState> {
    // *************************************************************************
    //                            EXTERNALS
    // *************************************************************************
    fn mint_karstnft(ref self: TState, address: ContractAddress);
    // *************************************************************************
    //                            GETTERS
    // *************************************************************************
    fn get_last_minted_id(self: @TState) -> u256;
    fn get_user_token_id(self: @TState, user: ContractAddress) -> u256;
    fn get_token_mint_timestamp(self: @TState, token_id: u256) -> u64;
    // *************************************************************************
    //                            METADATA
    // *************************************************************************   
    fn name(self: @TState) -> ByteArray;
    fn symbol(self: @TState) -> ByteArray;
    fn token_uri(self: @TState, token_id: u256) -> ByteArray;
}
