use starknet::ContractAddress;
// *************************************************************************
//                              INTERFACE of KARST NFT
// *************************************************************************
#[starknet::interface]
pub trait IKarstNFT<TState> {
    fn mint_karstnft(ref self: TState, address: ContractAddress);
    fn get_current_token_id(self: @TState) -> u256;
    fn get_user_token_id(self: @TState, user: ContractAddress) -> u256;
}
