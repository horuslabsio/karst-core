#[starknet::contract]
pub mod KarstChannel {
    use karst::channel::channel::ChannelComponent;
    component!(path: ChannelComponent, storage: channel, event: ChannelEvent);
    #[abi(embed_v0)]
    impl channelImpl = ChannelComponent::KarstChannel<ContractState>;
    #[storage]
    struct Storage {
        #[substorage(v0)]
        channel: ChannelComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ChannelEvent: ChannelComponent::Event
    }
}
