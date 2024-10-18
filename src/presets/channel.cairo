#[starknet::contract]
pub mod KarstChannel {
    use karst::channel::channel::ChannelComponent;
    use karst::community::community::CommunityComponent;
    use karst::jolt::jolt::JoltComponent;
    use openzeppelin::access::ownable::OwnableComponent;
    use starknet::ContractAddress;

    component!(path: ChannelComponent, storage: channel, event: ChannelEvent);
    component!(path: CommunityComponent, storage: community, event: CommunityEvent);
    component!(path: JoltComponent, storage: jolt, event: JoltEvent);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl channelImpl = ChannelComponent::KarstChannel<ContractState>;
    impl channelPrivateImpl = ChannelComponent::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl joltImpl = JoltComponent::Jolt<ContractState>;
    impl joltPrivateImpl = JoltComponent::Private<ContractState>;

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

    #[constructor]
    fn constructor(
        ref self: ContractState, channel_nft_classhash: felt252, owner: ContractAddress
    ) {
        self.channel._initializer(channel_nft_classhash);
        self.jolt._initializer(owner);
    }
}
