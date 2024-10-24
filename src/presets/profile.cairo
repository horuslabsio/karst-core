#[starknet::contract]
pub mod ColonizProfile {
    use starknet::ContractAddress;
    use coloniz::profile::profile::ProfileComponent;

    component!(path: ProfileComponent, storage: profile, event: ProfileEvent);

    #[abi(embed_v0)]
    impl profileImpl = ProfileComponent::colonizProfile<ContractState>;
    impl ProfilePrivateImpl = ProfileComponent::Private<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        profile: ProfileComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ProfileEvent: ProfileComponent::Event
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        coloniznft_contract_address: ContractAddress,
        hub_address: ContractAddress,
        follow_nft_classhash: felt252
    ) {
        self.profile._initializer(coloniznft_contract_address, hub_address, follow_nft_classhash);
    }
}
