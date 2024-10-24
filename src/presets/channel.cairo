#[starknet::contract]
pub mod ColonizChannel {
    use coloniz::channel::channel::ChannelComponent;
    use coloniz::community::community::CommunityComponent;
    use coloniz::jolt::jolt::JoltComponent;
    use openzeppelin::access::ownable::OwnableComponent;

    component!(path: ChannelComponent, storage: channel, event: ChannelEvent);
    component!(path: CommunityComponent, storage: community, event: CommunityEvent);
    component!(path: JoltComponent, storage: jolt, event: JoltEvent);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl channelImpl = ChannelComponent::colonizChannel<ContractState>;
    impl channelPrivateImpl = ChannelComponent::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl communityImpl = CommunityComponent::colonizCommunity<ContractState>;
    impl communityPrivateImpl = CommunityComponent::Private<ContractState>;

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
        ref self: ContractState, channel_nft_classhash: felt252, community_nft_classhash: felt252
    ) {
        self.channel._initializer(channel_nft_classhash);
        self.community._initializer(community_nft_classhash);
    }
}
