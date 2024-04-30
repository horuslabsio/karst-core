use starknet::ContractAddress;
#[starknet::interface]
pub trait IKarst<TState> {
    fn mint_karstnft(ref self: TState);
    fn token_id(self: @TState) -> u256;
}
