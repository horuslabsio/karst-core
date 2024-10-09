#[starknet::contract]
pub mod KarstPublication {
    use starknet::ContractAddress;
    use karst::publication::publication::PublicationComponent;
    use karst::profile::profile::ProfileComponent;

    component!(path: PublicationComponent, storage: publication, event: PublicationEvent);
    component!(path: ProfileComponent, storage: profile, event: ProfileEvent);
    #[abi(embed_v0)]
    impl publicationImpl = PublicationComponent::KarstPublication<ContractState>;
    #[abi(embed_v0)]
    impl profileImpl = ProfileComponent::KarstProfile<ContractState>;
    impl ProfilePrivateImpl = ProfileComponent::Private<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        publication: PublicationComponent::Storage,
        #[substorage(v0)]
        profile: ProfileComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        PublicationEvent: PublicationComponent::Event,
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
        self.profile._initializer(karstnft_contract_address, hub_address, follow_nft_classhash);
    }
}
