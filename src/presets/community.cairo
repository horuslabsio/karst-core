#[starknet::contract]
pub mod KarstCommunity {
    use starknet::ContractAddress;
    use karst::community::community::CommunityComponent;
    use karst::interfaces::ICommunity::ICommunity;

    component!(path: CommunityComponent, storage: community, event: CommunityEvent);

    #[abi(embed_v0)]
    impl communityImpl = CommunityComponent::KarstCommunity<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        community: CommunityComponent::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        CommunityEvent: CommunityComponent::Event
    }

    #[constructor]
    fn constructor(
        ref self: ContractState, hub_address: ContractAddress, community_nft_classhash: felt252
    ) {
        self.community.initializer(hub_address, community_nft_classhash);
    }
}
