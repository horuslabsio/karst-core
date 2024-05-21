#[starknet::contract]
mod Follow {
    // *************************************************************************
    //                            IMPORT
    // *************************************************************************
    use core::traits::TryInto;
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use core::num::traits::zero::Zero;
    use karst::interface::{
        IFollow::IFollow,
        IkarstNFT::{IKarstNFTDispatcher, IKarstNFTDispatcherTrait},
    };
    use karst::base::{errors::Errors, hubrestricted::HubRestricted::hub_only};
    use karst::base::types::FollowData;

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
        karst_follow_nft: ContractAddress,
    }

    // *************************************************************************
    //                            CONSTRUCTOR
    // *************************************************************************
    #[constructor]
    fn constructor(ref self: ContractState, hub: ContractAddress, follow_nft: ContractAddress) {
        self.karst_hub.write(hub);
        self.karst_follow_nft.write(follow_nft);
    }

    // *************************************************************************
    //                            EXTERNAL FUNCTIONS
    // *************************************************************************
    #[abi(embed_v0)]
    impl FollowImpl of IFollow<ContractState> {
        fn initialize(ref self: ContractState, profile_address: ContractAddress) {
            assert(!self.initialized.read(), Errors::INITIALIZED);
            self.initialized.write(true);
            self.followed_profile_address.write(profile_address);
        }

        fn follow(ref self: ContractState, follower_profile_address: ContractAddress) -> u256 {
            hub_only(self.karst_hub.read());
            let follow_id = self
                .follow_id_by_follower_profile_address
                .read(follower_profile_address);
            assert(follow_id.is_zero(), Errors::FOLLOWING);
            self._follow(follower_profile_address)
        }

        fn unfollow(ref self: ContractState, unfollower_profile_address: ContractAddress,) {
            hub_only(self.karst_hub.read());
            let follow_id = self
                .follow_id_by_follower_profile_address
                .read(unfollower_profile_address);
            assert(follow_id.is_non_zero(), Errors::NOT_FOLLOWING);
            self._unfollow(unfollower_profile_address, follow_id);
        }

        fn mint_follow_nft(
            ref self: ContractState, follow_id: u256
        ) {
            let profile_address = self.followed_profile_address.read();
            let karst_follow_nft = self.karst_follow_nft.read();
            IKarstNFTDispatcher { contract_address: karst_follow_nft }.mint_karstnft();
        }

        fn process_block(
            ref self: ContractState, follower_profile_address: ContractAddress
        ) -> bool {
            let follow_id = self
                .follow_id_by_follower_profile_address
                .read(follower_profile_address);
            assert(follow_id.is_non_zero(), Errors::NOT_FOLLOWING);
            // TODO: Check if token is wrapped and if not wrap first
            self._unfollow(follower_profile_address, follow_id);
            return true;
        }

        // *************************************************************************
        //                            GETTERS
        // *************************************************************************
        fn get_follower_profile_address(
            self: @ContractState, follow_id: u256
        ) -> ContractAddress {
            let follow_data = self.follow_data_by_follow_id.read(follow_id);
            follow_data.follower_profile_address
        }

        fn get_follow_timestamp(self: @ContractState, follow_id: u256) -> u64 {
            let follow_data = self.follow_data_by_follow_id.read(follow_id);
            follow_data.follow_timestamp
        }

        fn get_follow_data(self: @ContractState, follow_id: u256) -> FollowData {
            self.follow_data_by_follow_id.read(follow_id)
        }

        fn is_following(self: @ContractState, follower_profile_address: ContractAddress) -> bool {
            self.follow_id_by_follower_profile_address.read(follower_profile_address) != 0
        }

        fn get_follow_id(
            self: @ContractState, follower_profile_address: ContractAddress
        ) -> u256 {
            self.follow_id_by_follower_profile_address.read(follower_profile_address)
        }

        fn get_follower_count(self: @ContractState) -> u256 {
            self.follower_count.read()
        }
    }

    // *************************************************************************
    //                            PRIVATE FUNCTIONS
    // *************************************************************************
    #[generate_trait]
    impl Private of PrivateTrait {
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
            return (new_follower_id);
        }

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
        }
    }
}
