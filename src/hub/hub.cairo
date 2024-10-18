use starknet::ContractAddress;

#[starknet::interface]
trait IKarstHub<TState> {
    fn follow(
        ref self: TState,
        follower_profile_address: ContractAddress,
        address_of_profiles_to_follow: Array<ContractAddress>
    ) -> Array<u256>;
    fn unfollow(ref self: TState, address_of_profiles_to_unfollow: Array<ContractAddress>);
    fn set_block_status(
        ref self: TState,
        blocker_profile_address: ContractAddress,
        address_of_profiles_to_block: Array<ContractAddress>,
        block_status: bool
    );
    fn is_following(
        self: @TState, followed_profile_address: ContractAddress, follower_address: ContractAddress
    ) -> bool;
    fn is_blocked(
        self: @TState, followed_profile_address: ContractAddress, follower_address: ContractAddress
    ) -> bool;
    fn get_handle_id(self: @TState, profile_address: ContractAddress) -> u256;
    fn get_handle(self: @TState, handle_id: u256) -> ByteArray;
}

#[starknet::contract]
pub mod KarstHub {
    use core::array::SpanTrait;
    use starknet::{
        ContractAddress, get_caller_address, get_contract_address,
        storage::{StoragePointerWriteAccess, StoragePointerReadAccess}
    };
    use karst::profile::profile::ProfileComponent;
    use karst::publication::publication::PublicationComponent;
    use karst::interfaces::IFollowNFT::{IFollowNFTDispatcher, IFollowNFTDispatcherTrait};
    use karst::interfaces::IHandle::{IHandleDispatcher, IHandleDispatcherTrait};
    use karst::interfaces::IHandleRegistry::{
        IHandleRegistryDispatcher, IHandleRegistryDispatcherTrait
    };
    use karst::base::constants::errors::Errors::{
        BLOCKED_STATUS, INVALID_PROFILE_ADDRESS, SELF_FOLLOWING
    };

    // *************************************************************************
    //                              COMPONENTS
    // *************************************************************************
    component!(path: ProfileComponent, storage: profile, event: ProfileEvent);
    component!(path: PublicationComponent, storage: publication, event: PublicationEvent);

    #[abi(embed_v0)]
    impl ProfileImpl = ProfileComponent::KarstProfile<ContractState>;
    #[abi(embed_v0)]
    impl PublicationImpl = PublicationComponent::KarstPublication<ContractState>;

    impl ProfilePrivateImpl = ProfileComponent::Private<ContractState>;

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
        self
            .profile
            ._initializer(karstnft_contract_address, get_contract_address(), follow_nft_classhash);
        self.handle_contract_address.write(handle_contract_address);
        self.handle_registry_contract_address.write(handle_registry_contract_address);
    }

    #[abi(embed_v0)]
    impl KarstHubImpl of super::IKarstHub<ContractState> {
        // *************************************************************************
        //                            EXTERNAL FUNCTIONS
        // *************************************************************************
        // TODO: Fix get_caller_address so not just anybody can follow on someone's behalf
        /// @notice follows a set of given addresses
        /// @param follower_profile_address address of the user trying to perform the follow action
        /// @param address_of_profiles_to_follow addresses of profiles to follow
        fn follow(
            ref self: ContractState,
            follower_profile_address: ContractAddress,
            address_of_profiles_to_follow: Array<ContractAddress>
        ) -> Array<u256> {
            let mut addresses_to_follow = address_of_profiles_to_follow.span();
            let mut follow_ids = array![];

            while addresses_to_follow.len() != 0 {
                let followed_profile_address = addresses_to_follow.pop_front().unwrap();
                let follow_id = self._follow(follower_profile_address, *followed_profile_address);
                follow_ids.append(follow_id);
            };

            follow_ids
        }

        /// @notice unfollows a set of given addresses
        /// @param address_of_profiles_to_unfollow addresses of profiles to unfollow
        fn unfollow(
            ref self: ContractState, address_of_profiles_to_unfollow: Array<ContractAddress>
        ) {
            let mut addresses_to_unfollow = address_of_profiles_to_unfollow.span();

            while addresses_to_unfollow.len() != 0 {
                let unfollowed_profile_address = addresses_to_unfollow.pop_front().unwrap();
                let unfollower_profile_address = get_caller_address();
                self._unfollow(unfollower_profile_address, *unfollowed_profile_address);
            };
        }

        // TODO: Fix get_caller_address so not just anybody can follow on someone's behalf
        /// @notice blocks/unblocks a set of given addresses
        /// @param blocker_profile_address address of the user trying to perform the block/unblock
        /// action @param address_of_profiles_to_block addresses of profiles to block/unblock
        /// @param block_status true if intent is to block, false if intent is to unblock
        fn set_block_status(
            ref self: ContractState,
            blocker_profile_address: ContractAddress,
            address_of_profiles_to_block: Array<ContractAddress>,
            block_status: bool
        ) {
            let mut addresses = address_of_profiles_to_block.span();

            while addresses.len() != 0 {
                let address_to_block = addresses.pop_front().unwrap();
                self._set_block_status(blocker_profile_address, *address_to_block, block_status);
            }
        }

        // *************************************************************************
        //                            GETTERS
        // *************************************************************************
        /// @notice checks if a particular address is following the followed profile
        /// @param followed_profile_address address of the user being followed
        /// @param follower_address address to be check
        fn is_following(
            self: @ContractState,
            followed_profile_address: ContractAddress,
            follower_address: ContractAddress
        ) -> bool {
            let profile = self.profile.get_profile(followed_profile_address);
            let dispatcher = IFollowNFTDispatcher { contract_address: profile.follow_nft };
            dispatcher.is_following(follower_address)
        }

        /// @notice checks if a particular address is blocked by the followed profile
        /// @param followed_profile_address address of the user being followed
        /// @param follower_profile_address address of the user to check
        fn is_blocked(
            self: @ContractState,
            followed_profile_address: ContractAddress,
            follower_address: ContractAddress
        ) -> bool {
            let profile = self.profile.get_profile(followed_profile_address);
            let dispatcher = IFollowNFTDispatcher { contract_address: profile.follow_nft };
            dispatcher.is_blocked(follower_address)
        }

        /// @notice returns the handle ID linked to a profile address
        /// @param profile_address address of profile to be queried
        fn get_handle_id(self: @ContractState, profile_address: ContractAddress) -> u256 {
            let dispatcher = IHandleRegistryDispatcher {
                contract_address: self.handle_registry_contract_address.read()
            };

            let handle_id = dispatcher.get_handle(profile_address);
            handle_id
        }

        /// @notice returns the full handle of a user
        /// @param handle_id ID of handle to retrieve
        fn get_handle(self: @ContractState, handle_id: u256) -> ByteArray {
            let dispatcher = IHandleDispatcher {
                contract_address: self.handle_contract_address.read()
            };
            dispatcher.get_handle(handle_id)
        }
    }

    // *************************************************************************
    //                            PRIVATE FUNCTIONS
    // *************************************************************************
    #[generate_trait]
    impl Private of PrivateTrait {
        /// @notice internal function that processes the follow action
        /// @param follower_profile_address address of the user trying to perform the follow action
        /// @param followed_profile_address address of profile to follow
        fn _follow(
            ref self: ContractState,
            follower_profile_address: ContractAddress,
            followed_profile_address: ContractAddress
        ) -> u256 {
            // validate profile
            let profile = self.profile.get_profile(followed_profile_address);
            assert(followed_profile_address == profile.profile_address, INVALID_PROFILE_ADDRESS);

            // validate profile is not blocked
            let dispatcher = IFollowNFTDispatcher { contract_address: profile.follow_nft };
            assert(!dispatcher.is_blocked(follower_profile_address), BLOCKED_STATUS);

            // validate user is not self following
            assert(follower_profile_address != followed_profile_address, SELF_FOLLOWING);

            // perform follow action
            dispatcher.follow(follower_profile_address)
        }

        /// @notice internal function that processes the unfollow action
        /// @param unfollower_profile_address address of the user trying to perform the unfollow
        /// action @param unfollowed_profile_address address of profile to unfollow
        fn _unfollow(
            ref self: ContractState,
            unfollower_profile_address: ContractAddress,
            unfollowed_profile_address: ContractAddress
        ) {
            let profile = self.profile.get_profile(unfollowed_profile_address);
            let dispatcher = IFollowNFTDispatcher { contract_address: profile.follow_nft };

            // perform unfollow action
            dispatcher.unfollow(unfollower_profile_address);
        }

        /// @notice internal function that processes the block/unblock action
        /// @param blocker_profile_address address of the user trying to perform the block/unblock
        /// action @param address_to_block address of profile to block/unblock
        /// @param block_status true if intent is to block, false if intent is to unblock
        fn _set_block_status(
            ref self: ContractState,
            blocker_profile_address: ContractAddress,
            address_to_block: ContractAddress,
            block_status: bool
        ) {
            let profile = self.profile.get_profile(blocker_profile_address);
            let dispatcher = IFollowNFTDispatcher { contract_address: profile.follow_nft };

            // perform blocking action
            if block_status == true {
                dispatcher.process_block(address_to_block);
            } else {
                dispatcher.process_unblock(address_to_block);
            }
        }
    }
}
