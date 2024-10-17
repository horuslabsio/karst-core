#[starknet::contract]
pub mod Jolt {
    use starknet::ContractAddress;
    use karst::jolt::jolt::JoltComponent;
    use openzeppelin::access::ownable::OwnableComponent;

    component!(path: JoltComponent, storage: jolt, event: JoltEvent);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl joltImpl = JoltComponent::Jolt<ContractState>;
    impl joltPrivateImpl = JoltComponent::Private<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        jolt: JoltComponent::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        JoltEvent: JoltComponent::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.jolt._initializer(owner);
    }
}
