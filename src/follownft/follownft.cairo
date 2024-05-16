#[starknet::contract]
mod FollowNFT {
    // *************************************************************************
    //                            IMPORT
    // *************************************************************************
    use starknet::{ ContractAddress, get_caller_address, get_block_timestamp };
    use core::zeroable::Zeroable;
    use karst::interface::IFollowNFT::IFollowNFT;
    use karst::base::{
        errors::Errors,
        hubrestricted::HubRestricted::hub_only
    };

    // *************************************************************************
    //                            STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        followed_profile_id: u256,
        last_follow_token_id: u256,
        follower_count: u256,
        follow_token_id_by_follower_profile_id: LegacyMap<u256, u256>,
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

    #[derive(Drop, starknet::Store)]
    struct FollowData {
        follower_profile_id: u256,
        follow_timestamp: u64
    }

    // *************************************************************************
    //                            EXTERNAL FUNCTIONS
    // *************************************************************************
    #[abi(embed_v0)]
    impl FollowNFTImpl of IFollowNFT<ContractState> {
        fn initialize(ref self: ContractState, profile_id: u256) {
            assert(!self.initialized.read(), Errors::INITIALIZED);
            self.initialized.write(true);
            self.followed_profile_id.write(profile_id);
        }

        fn follow(
            ref self: ContractState,
            follower_profile_id: u256
        ) -> u256 {
            hub_only(self.karst_hub.read());
            let follow_token_id = self.follow_token_id_by_follower_profile_id.read(follower_profile_id);
            assert(follow_token_id.is_zero(), Errors::FOLLOWING);
            self._follow(follower_profile_id)
        }

        fn unfollow(
            ref self: ContractState,
            unfollower_profile_id: u256,
        ) {

        }
    }

    // *************************************************************************
    //                            PRIVATE FUNCTIONS
    // *************************************************************************
    #[generate_trait]
    impl Private of PrivateTrait {
        fn _follow(ref self: ContractState, follower_profile_id: u256) -> u256 {
            let assigned_follow_token_id = self.last_follow_token_id.read() + 1;
            let new_follower_count = self.follower_count.read() + 1;
            let follow_timestamp: u64 = get_block_timestamp();
            let follow_data = FollowData { 
                follower_profile_id: follower_profile_id, follow_timestamp: follow_timestamp 
            };

            self.follow_token_id_by_follower_profile_id.write(follower_profile_id, assigned_follow_token_id);
            self.follow_data_by_follow_token_id.write(assigned_follow_token_id, follow_data);
            self.follower_count.write(new_follower_count);
            return (assigned_follow_token_id);
        }
    }
}