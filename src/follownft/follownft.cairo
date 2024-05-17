#[starknet::contract]
mod FollowNFT {
    // *************************************************************************
    //                            IMPORT
    // *************************************************************************
    use core::traits::TryInto;
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use core::num::traits::zero::Zero;
    use karst::interface::IFollowNFT::IFollowNFT;
    use karst::base::{errors::Errors, hubrestricted::HubRestricted::hub_only};
    use karst::base::types::FollowData;

    // *************************************************************************
    //                            STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        followed_profile_address: ContractAddress,
        last_follow_token_id: u256,
        follower_count: u256,
        follow_token_id_by_follower_profile_address: LegacyMap<ContractAddress, u256>,
        follow_data_by_follow_token_id: LegacyMap<u256, FollowData>,
        initialized: bool,
        karst_hub: ContractAddress,
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
    impl FollowNFTImpl of IFollowNFT<ContractState> {
        fn initialize(ref self: ContractState, profile_address: ContractAddress) {
            assert(!self.initialized.read(), Errors::INITIALIZED);
            self.initialized.write(true);
            self.followed_profile_address.write(profile_address);
        }

        fn follow(ref self: ContractState, follower_profile_address: ContractAddress) -> u256 {
            hub_only(self.karst_hub.read());
            let follow_token_id = self
                .follow_token_id_by_follower_profile_address
                .read(follower_profile_address);
            assert(follow_token_id.is_zero(), Errors::FOLLOWING);
            self._follow(follower_profile_address)
        }

        fn unfollow(ref self: ContractState, unfollower_profile_address: ContractAddress,) {
            hub_only(self.karst_hub.read());
            let follow_token_id = self
                .follow_token_id_by_follower_profile_address
                .read(unfollower_profile_address);
            assert(follow_token_id.is_non_zero(), Errors::NOT_FOLLOWING);
            self._unfollow(unfollower_profile_address, follow_token_id);
        }

        fn wrap(
            ref self: ContractState, follow_token_id: u256, wrapped_token_receiver: ContractAddress
        ) {
            if (wrapped_token_receiver.is_zero()) {
                self._wrap(follow_token_id, self.followed_profile_address.read());
            } else {
                self.wrap(follow_token_id, wrapped_token_receiver);
            }
        }

        fn unwrap(ref self: ContractState, follow_token_id: u256) {
            let follow_data = self.follow_data_by_follow_token_id.read(follow_token_id);
            assert(follow_data.follower_profile_address.is_non_zero(), Errors::NOT_FOLLOWING);
        // TODO: Burn token with token_id
        }

        fn process_block(
            ref self: ContractState, follower_profile_address: ContractAddress
        ) -> bool {
            let follow_token_id = self
                .follow_token_id_by_follower_profile_address
                .read(follower_profile_address);
            assert(follow_token_id.is_non_zero(), Errors::NOT_FOLLOWING);
            // TODO: Check if token is wrapped and if not wrap first
            self._unfollow(follower_profile_address, follow_token_id);
            return true;
        }
    }

    // *************************************************************************
    //                            PRIVATE FUNCTIONS
    // *************************************************************************
    #[generate_trait]
    impl Private of PrivateTrait {
        fn _follow(ref self: ContractState, follower_profile_address: ContractAddress) -> u256 {
            let assigned_follow_token_id = self.last_follow_token_id.read() + 1;
            let new_follower_count = self.follower_count.read() + 1;
            let follow_timestamp: u64 = get_block_timestamp();
            let follow_data = FollowData {
                follower_profile_address: follower_profile_address,
                follow_timestamp: follow_timestamp
            };

            self
                .follow_token_id_by_follower_profile_address
                .write(follower_profile_address, assigned_follow_token_id);
            self.follow_data_by_follow_token_id.write(assigned_follow_token_id, follow_data);
            self.follower_count.write(new_follower_count);
            return (assigned_follow_token_id);
        }

        fn _unfollow(ref self: ContractState, unfollower: ContractAddress, follow_token_id: u256) {
            self.follow_token_id_by_follower_profile_address.write(unfollower, 0);
            self
                .follow_data_by_follow_token_id
                .write(
                    follow_token_id,
                    FollowData {
                        follower_profile_address: 0.try_into().unwrap(), follow_timestamp: 0
                    }
                );
            self.follower_count.write(self.follower_count.read() - 1);
        }

        fn _wrap(
            ref self: ContractState, follow_token_id: u256, wrapped_token_receiver: ContractAddress
        ) {}
    }
}
