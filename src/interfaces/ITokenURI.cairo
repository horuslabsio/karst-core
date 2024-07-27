use starknet::ContractAddress;

// *************************************************************************
//                              INTERFACE of TOKEN URI
// *************************************************************************
#[starknet::interface]
pub trait ITokenURI<TState> {
    fn profile_get_token_uri(token_id: u256, mint_timestamp: u64, profile: Profile) -> ByteArray;

    fn handle_get_token_uri(token_id: u256, local_name: felt252, namespace: felt252) -> ByteArray;

    fn follow_get_token_uri(
        follow_token_id: u256, followed_profile_address: ContractAddress, follow_timestamp: u64
    ) -> ByteArray;
}

