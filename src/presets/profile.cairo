#[starknet::contract]
pub mod KarstProfile {
    use starknet::ContractAddress;
    use karst::profile::profile::ProfileComponent;

    component!(path: ProfileComponent, storage: profile, event: ProfileEvent);

    #[abi(embed_v0)]
    impl profileImpl = ProfileComponent::KarstProfile<ContractState>;

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
        karstnft_contract_address: ContractAddress,
        hub_address: ContractAddress,
        follow_nft_classhash: felt252
    ) {
        self.profile.initializer(karstnft_contract_address, hub_address, follow_nft_classhash);
    }
}
