#[starknet::contract]
mod KarstPublication {
    use starknet::{ContractAddress};
    use karst::publication::publication::PublicationComponent;

    component!(path: PublicationComponent, storage: publication, event: PublicationEvent);

    #[abi(embed_v0)]
    impl publicationImpl = PublicationComponent::KarstPublication<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        publication: PublicationComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        PublicationEvent: PublicationComponent::Event
    }

    #[constructor]
    fn constructor(ref self: ContractState, hub_address: ContractAddress) {
        self.publication.initializer(hub_address);
    }
}
