#[starknet::contract]
mod Follow {
    // *************************************************************************
    //                            IMPORT
    // *************************************************************************
    use core::traits::TryInto;
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use core::num::traits::zero::Zero;
    use karst::interfaces::{IFollowNFT::IFollowNFT};
    use karst::base::{
        constants::{errors::Errors, types::FollowData},
        utils::hubrestricted::HubRestricted::hub_only,
    //  token_uris::follow_token_uri::FollowTokenUri,
    };

    use karst::base::token_uris::token_uris::TokenURIComponent;
    component!(path: TokenURIComponent, storage: token_uri, event: TokenUriEvent);


    #[abi(embed_v0)]
    impl TokenURIImpl = TokenURIComponent::KarstTokenURI<ContractState>;
    // *************************************************************************
    //                            STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        followed_profile_address: ContractAddress,
        follower_count: u256,
        follow_id_by_follower_profile_address: LegacyMap<ContractAddress, u256>,
        follow_data_by_follow_id: LegacyMap<u256, FollowData>,
        initialized: bool,
        karst_hub: ContractAddress,
        #[substorage(v0)]
        token_uri: TokenURIComponent::Storage,
    }

    // *************************************************************************
    //                            EVENTS
    // ************************************************************************* 
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Followed: Followed,
        Unfollowed: Unfollowed,
        FollowerBlocked: FollowerBlocked,
    }

    #[derive(Drop, starknet::Event)]
    struct Followed {
        followed_address: ContractAddress,
        follower_address: ContractAddress,
        follow_id: u256,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct Unfollowed {
        unfollowed_address: ContractAddress,
        unfollower_address: ContractAddress,
        follow_id: u256,
        timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    struct FollowerBlocked {
        followed_address: ContractAddress,
        blocked_follower: ContractAddress,
        follow_id: u256,
        timestamp: u64,
    }

    // *************************************************************************
    //                            CONSTRUCTOR
    // *************************************************************************
    #[constructor]
    fn constructor(ref self: ContractState, hub: ContractAddress) {
        self.karst_hub.write(hub);
    }

    // *************************************************************************
    //                            EXTERNAL FUNCTIONS
    // *************************************************************************
    #[abi(embed_v0)]
    impl FollowImpl of IFollowNFT<ContractState> {
        /// @notice initialize follow contract
        /// @param profile_address address of profile to initialize contract for
        fn initialize(ref self: ContractState, profile_address: ContractAddress) {
            assert(!self.initialized.read(), Errors::INITIALIZED);
            self.initialized.write(true);
            self.followed_profile_address.write(profile_address);
        }

        /// @notice performs the follow action
        /// @param follower_profile_address address of the user trying to perform the follow action
        fn follow(ref self: ContractState, follower_profile_address: ContractAddress) -> u256 {
            hub_only(self.karst_hub.read());
            let follow_id = self
                .follow_id_by_follower_profile_address
                .read(follower_profile_address);
            assert(follow_id.is_zero(), Errors::FOLLOWING);
            self._follow(follower_profile_address)
        }

        /// @notice performs the unfollow action
        /// @param unfollower_profile_address address of the user trying to perform the unfollow action
        fn unfollow(ref self: ContractState, unfollower_profile_address: ContractAddress) {
            hub_only(self.karst_hub.read());
            let follow_id = self
                .follow_id_by_follower_profile_address
                .read(unfollower_profile_address);
            assert(follow_id.is_non_zero(), Errors::NOT_FOLLOWING);
            self._unfollow(unfollower_profile_address, follow_id);
        }

        /// @notice performs the block action
        /// @param follower_profile_address address of the user to be blocked
        fn process_block(
            ref self: ContractState, follower_profile_address: ContractAddress
        ) -> bool {
            hub_only(self.karst_hub.read());
            let follow_id = self
                .follow_id_by_follower_profile_address
                .read(follower_profile_address);
            assert(follow_id.is_non_zero(), Errors::NOT_FOLLOWING);
            self._unfollow(follower_profile_address, follow_id);
            self
                .emit(
                    FollowerBlocked {
                        followed_address: self.followed_profile_address.read(),
                        blocked_follower: follower_profile_address,
                        follow_id: follow_id,
                        timestamp: get_block_timestamp()
                    }
                );
            return true;
        }

        // *************************************************************************
        //                            GETTERS
        // *************************************************************************

        /// @notice gets the follower profile address for a follow action
        /// @param follow_id ID of the follow action
        fn get_follower_profile_address(self: @ContractState, follow_id: u256) -> ContractAddress {
            let follow_data = self.follow_data_by_follow_id.read(follow_id);
            follow_data.follower_profile_address
        }

        /// @notice gets the follow timestamp for a follow action
        /// @param follow_id ID of the follow action
        fn get_follow_timestamp(self: @ContractState, follow_id: u256) -> u64 {
            let follow_data = self.follow_data_by_follow_id.read(follow_id);
            follow_data.follow_timestamp
        }

        /// @notice gets the entire follow data for a follow action
        /// @param follow_id ID of the follow action
        fn get_follow_data(self: @ContractState, follow_id: u256) -> FollowData {
            self.follow_data_by_follow_id.read(follow_id)
        }

        /// @notice checks if a particular address is following the followed profile
        /// @param follower_profile_address address of the user to check
        fn is_following(self: @ContractState, follower_profile_address: ContractAddress) -> bool {
            self.follow_id_by_follower_profile_address.read(follower_profile_address) != 0
        }

        /// @notice gets the follow ID for a follower_profile_address
        /// @param follower_profile_address address of the profile
        fn get_follow_id(self: @ContractState, follower_profile_address: ContractAddress) -> u256 {
            self.follow_id_by_follower_profile_address.read(follower_profile_address)
        }

        /// @notice gets the total followers for the followed profile
        fn get_follower_count(self: @ContractState) -> u256 {
            self.follower_count.read()
        }

        // *************************************************************************
        //                            METADATA
        // *************************************************************************
        fn name(self: @ContractState) -> ByteArray {
            return "KARST:FOLLOWER";
        }
        fn symbol(self: @ContractState) -> ByteArray {
            return "KFL";
        }
        fn token_uri(self: @ContractState, follow_id: u256) -> ByteArray {
            let follow_data = self.follow_data_by_follow_id.read(follow_id);
            let timestamp = follow_data.follow_timestamp;
            let followed_profile_address = self.followed_profile_address.read();

            // call token uri component
            self.token_uri.profile_get_token_uri(token_id, mint_timestamp, profile);
        }
    }

    // *************************************************************************
    //                            PRIVATE FUNCTIONS
    // *************************************************************************
    #[generate_trait]
    impl Private of PrivateTrait {
        /// @notice internal function that performs the follow action
        /// @param follower_profile_address address of profile performing the follow action
        fn _follow(ref self: ContractState, follower_profile_address: ContractAddress) -> u256 {
            let new_follower_id = self.follower_count.read() + 1;
            let follow_timestamp: u64 = get_block_timestamp();
            let follow_data = FollowData {
                follower_profile_address: follower_profile_address,
                follow_timestamp: follow_timestamp
            };

            self
                .follow_id_by_follower_profile_address
                .write(follower_profile_address, new_follower_id);
            self.follow_data_by_follow_id.write(new_follower_id, follow_data);
            self.follower_count.write(new_follower_id);
            self
                .emit(
                    Followed {
                        followed_address: self.followed_profile_address.read(),
                        follower_address: follower_profile_address,
                        follow_id: new_follower_id,
                        timestamp: get_block_timestamp()
                    }
                );
            return (new_follower_id);
        }

        /// @notice internal function that performs the unfollow action
        /// @param unfollower address of user performing the unfollow action
        /// @param follow_id ID of the initial follow action
        fn _unfollow(ref self: ContractState, unfollower: ContractAddress, follow_id: u256) {
            self.follow_id_by_follower_profile_address.write(unfollower, 0);
            self
                .follow_data_by_follow_id
                .write(
                    follow_id,
                    FollowData {
                        follower_profile_address: 0.try_into().unwrap(), follow_timestamp: 0
                    }
                );
            self.follower_count.write(self.follower_count.read() - 1);
            self
                .emit(
                    Unfollowed {
                        unfollowed_address: self.followed_profile_address.read(),
                        unfollower_address: unfollower,
                        follow_id,
                        timestamp: get_block_timestamp()
                    }
                );
        }
    }
}
