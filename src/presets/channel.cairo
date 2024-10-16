#[starknet::contract]
pub mod KarstChannel {
    use karst::channel::channel::ChannelComponent;
    use karst::community::community::CommunityComponent;
    use karst::jolt::jolt::JoltComponent;
    use openzeppelin::access::ownable::OwnableComponent;

    component!(path: ChannelComponent, storage: channel, event: ChannelEvent);
    component!(path: CommunityComponent, storage: community, event: CommunityEvent);
    component!(path: JoltComponent, storage: jolt, event: JoltEvent);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl channelImpl = ChannelComponent::KarstChannel<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        channel: ChannelComponent::Storage,
        #[substorage(v0)]
        community: CommunityComponent::Storage,
        #[substorage(v0)]
        jolt: JoltComponent::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ChannelEvent: ChannelComponent::Event,
        #[flat]
        CommunityEvent: CommunityComponent::Event,
        #[flat]
        JoltEvent: JoltComponent::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event
    }
}
