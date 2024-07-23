use starknet::ContractAddress;


#[starknet::component]
mod TokenURIComponent {
    // *************************************************************************
    //                            IMPORT
    // *************************************************************************
    use alexandria_bytes::{Bytes, BytesTrait};
    use alexandria_encoding::sol_abi::{SolBytesTrait, SolAbiEncodeTrait};
    use karst::base::utils::byte_array_extra::FeltTryIntoByteArray;

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {}


    // *************************************************************************
    //                            EXTERNAL FUNCTIONS
    // *************************************************************************
    #[embeddable_as(KarstTokenURI)]
    impl TokenUriImpl<
        TContractState, +HasComponent<TContractState>
    > of ITokenURI<ComponentState<TContractState>> {
        fn profile_get_token_uri(
            token_id: u256, mint_timestamp: u64, profile: Profile
        ) -> ByteArray {
            "TODO"
        }
        fn handle_get_token_uri(
            token_id: u256, local_name: felt252, namespace: felt252
        ) -> ByteArray {
            "TODO"
        }

        fn follow_get_token_uri(
            follow_token_id: u256, followed_profile_address: ContractAddress, follow_timestamp: u64
        ) -> ByteArray {
            "TODO"
        }
    }
}
