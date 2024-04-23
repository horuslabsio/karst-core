use starknet::ContractAddress;
#[starknet::interface]
trait IKarst<TState> {
    fn create_token(ref self: TState, addresses: Array<ContractAddress>);
}
