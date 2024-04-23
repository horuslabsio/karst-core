#[starknet::interface]
trait IKarstProfile<TState> {
    fn create_karstnft(ref self: TState);
}


#[starknet::contract]
mod KarstProfile {
    use starknet::ContractAddress;
    #[storage]
    struct Storage {
        profile_id: LegacyMap<ContractAddress, u256>
    }


    #[abi(embed_v0)]
    impl KarstProfileImpl of super::IKarstProfile<ContractState> {
        fn create_karstnft(ref self: ContractState) {
            // make call to karst_nft contract to mint nft via dispatcher
            // fetch tokenId of `caller`
            // specify the contract_address of karstnft
            // execute create_account on token bound registry via dispatcher
            //emit event
        }
    }
}
