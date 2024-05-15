use starknet::ContractAddress;
#[starknet::interface]
pub trait IKarst<TState> {
    fn mint_karstnft(ref self: TState);
    fn get_token_id(self: @TState) -> u256;
    fn get_user_token_id(self: @TState, caller: ContractAddress) -> u256;
}
