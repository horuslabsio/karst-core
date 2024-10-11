#[starknet::contract]
pub mod KarstChannel {
    use karst::channel::channel::ChannelComponent;
    use karst::community::community::CommunityComponent;

    component!(path: ChannelComponent, storage: channel, event: ChannelEvent);
    component!(path: CommunityComponent, storage: community, event: CommunityEvent);

    #[abi(embed_v0)]
    impl channelImpl = ChannelComponent::KarstChannel<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        channel: ChannelComponent::Storage,
        #[substorage(v0)]
        community: CommunityComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ChannelEvent: ChannelComponent::Event,
        #[flat]
        CommunityEvent: CommunityComponent::Event
    }
}
