#[starknet::contract]
pub mod KarstChannel {
    use karst::channel::channel::ChannelComponent;
    use karst::community::community::CommunityComponent;

    component!(path: ChannelComponent, storage: channel, event: ChannelEvent);
    component!(path: CommunityComponent, storage: community, event: CommunityEvent);

    #[abi(embed_v0)]
    impl channelImpl = ChannelComponent::KarstChannel<ContractState>;
    impl channelPrivateImpl = ChannelComponent::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl communityImpl = CommunityComponent::KarstCommunity<ContractState>;
    impl communityPrivateImpl = CommunityComponent::Private<ContractState>;

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

    #[constructor]
    fn constructor(
        ref self: ContractState, channel_nft_classhash: felt252, community_nft_classhash: felt252
    ) {
        self.channel._initializer(channel_nft_classhash);
        self.community._initializer(community_nft_classhash);
    }
}
