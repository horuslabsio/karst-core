use starknet::ContractAddress;

#[starknet::interface]
trait IKarstHub<TState> {
    fn follow(
        ref self: TState, 
        follower_profile_address: ContractAddress, 
        address_of_profiles_to_follow: Array<ContractAddress>
    );
    fn unfollow(
        ref self: TState, 
        address_of_profiles_to_unfollow: Array<ContractAddress>
    );
    fn set_block_status(
        ref self: TState,
        blocker_profile_address: ContractAddress,
        address_of_profiles_to_block: Array<ContractAddress>,
        block_status: bool
    );
    fn is_following(
        self: @TState, 
        followed_profile_address: ContractAddress, 
        follower_address: ContractAddress
    ) -> bool;
    fn get_handle_id(
        self: @TState, 
        profile_address: ContractAddress
    ) -> u256;
    fn get_handle(
        self: @TState, 
        handle_id: u256
    ) -> ByteArray;
}

#[starknet::contract]
mod KarstHub {
    use starknet::{ ContractAddress, get_caller_address, get_contract_address };
    use core::num::traits::zero::Zero;
    use karst::profile::profile::ProfileComponent;
    use karst::publication::publication::PublicationComponent;
    use karst::interfaces::IFollowNFT::{ IFollowNFTDispatcher, IFollowNFTDispatcherTrait };

    // *************************************************************************
    //                              COMPONENTS
    // *************************************************************************
    component!(path: ProfileComponent, storage: profile, event: ProfileEvent);
    component!(path: PublicationComponent, storage: publication, event: PublicationEvent);

    #[abi(embed_v0)]
    impl ProfileImpl = ProfileComponent::KarstProfile<ContractState>;
    impl PublicationImpl = PublicationComponent::KarstPublication<ContractState>;

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        #[substorage(v0)]
        profile: ProfileComponent::Storage,
        #[substorage(v0)]
        publication: PublicationComponent::Storage,
        handle_contract_address: ContractAddress,
        handle_registry_contract_address: ContractAddress
    }

    // *************************************************************************
    //                              EVENTS
    // *************************************************************************
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ProfileEvent: ProfileComponent::Event,
        PublicationEvent: PublicationComponent::Event
    }

    // *************************************************************************
    //                              CONSTRUCTOR
    // *************************************************************************
    #[constructor]
    fn constructor(
        ref self: ContractState,
        karstnft_contract_address: ContractAddress,
        handle_contract_address: ContractAddress,
        handle_registry_contract_address: ContractAddress,
        follow_nft_classhash: felt252
    ) {
        self.profile.initializer(karstnft_contract_address, get_contract_address(), follow_nft_classhash);
        self.handle_contract_address.write(handle_contract_address);
        self.handle_registry_contract_address.write(handle_registry_contract_address);
    }

    #[abi(embed_v0)]
    impl KarstHubImpl of super::IKarstHub<ContractState> {
        // *************************************************************************
        //                            EXTERNAL FUNCTIONS
        // *************************************************************************
        fn follow(
            ref self: ContractState, 
            follower_profile_address: ContractAddress, 
            address_of_profiles_to_follow: Array<ContractAddress>
        ) {
            let addresses_to_follow = address_of_profiles_to_follow.span();
            let mut address_count = addresses_to_follow.len();

            while address_count != 0 {
                // validate profile exists
                let followed_profile_address = addresses_to_follow.at(address_count);
                assert(self.profile.get_profile(followed_profile_address).is_non_zero(), 'zero address')
                // validate profile is not blocked

                // validate user is not self following

                // perform follow action
            }
        }
    
        fn unfollow(ref self: ContractState, address_of_profiles_to_unfollow: Array<ContractAddress>) {
            // TODO
        }
    
        fn set_block_status(
            ref self: ContractState,
            blocker_profile_address: ContractAddress,
            address_of_profiles_to_block: Array<ContractAddress>,
            block_status: bool
        ) {
            // TODO
        }

        fn is_following(
            self: @ContractState, followed_profile_address: ContractAddress, follower_address: ContractAddress
        ) -> bool {
            true
        }

        fn get_handle_id(self: @ContractState, profile_address: ContractAddress) -> u256 {
            25_u256
        }

        fn get_handle(self: @ContractState, handle_id: u256) -> ByteArray {
            "handle"
        }
    }
}