// *************************************************************************
//                            OZ ERC721
// *************************************************************************
use openzeppelin::{
    token::erc721::{ERC721Component::{ERC721Metadata, ERC721Mixin, HasComponent}},
    introspection::src5::SRC5Component,
};


#[starknet::interface]
trait IERC721Metadata<TState> {
    fn name(self: @TState) -> ByteArray;
    fn symbol(self: @TState) -> ByteArray;
}

#[starknet::embeddable]
impl IERC721MetadataImpl<
    TContractState,
    +HasComponent<TContractState>,
    +SRC5Component::HasComponent<TContractState>,
    +Drop<TContractState>
> of IERC721Metadata<TContractState> {
    fn name(self: @TContractState) -> ByteArray {
        let component = HasComponent::get_component(self);
        ERC721Metadata::name(component)
    }

    fn symbol(self: @TContractState) -> ByteArray {
        let component = HasComponent::get_component(self);
        ERC721Metadata::symbol(component)
    }
}

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
        utils::hubrestricted::HubRestricted::hub_only, token_uris::follow_token_uri::FollowTokenUri,
    };

    use openzeppelin::{
        account, access::ownable::OwnableComponent,
        token::erc721::{
            ERC721Component, erc721::ERC721Component::InternalTrait as ERC721InternalTrait
        },
        introspection::{src5::SRC5Component}
    };

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);

    // allow to check what interface is supported
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;
    impl SRC5InternalImpl = SRC5Component::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl ERC721Impl = ERC721Component::ERC721Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721CamelOnlyImpl = ERC721Component::ERC721CamelOnlyImpl<ContractState>;

    // add an owner
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    // *************************************************************************
    //                            STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        admin: ContractAddress,
        followed_profile_address: ContractAddress,
        follower_count: u256,
        follow_id_by_follower_profile_address: LegacyMap<ContractAddress, u256>,
        follow_data_by_follow_id: LegacyMap<u256, FollowData>,
        karst_hub: ContractAddress,
    }

    // *************************************************************************
    //                            EVENTS
    // ************************************************************************* 
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        Followed: Followed,
        Unfollowed: Unfollowed,
        FollowerBlocked: FollowerBlocked,
        FollowerUnblocked: FollowerUnblocked
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

    #[derive(Drop, starknet::Event)]
    struct FollowerUnblocked {
        followed_address: ContractAddress,
        unblocked_follower: ContractAddress,
        follow_id: u256,
        timestamp: u64,
    }

    // *************************************************************************
    //                            CONSTRUCTOR
    // *************************************************************************
    #[constructor]
    fn constructor(
        ref self: ContractState,
        hub: ContractAddress,
        profile_address: ContractAddress,
        admin: ContractAddress
    ) {
        self.admin.write(admin);
        self.erc721.initializer("KARST:FOLLOWER", "KFL", "");
        self.karst_hub.write(hub);
        self.followed_profile_address.write(profile_address);
    }

    // *************************************************************************
    //                            EXTERNAL FUNCTIONS
    // *************************************************************************
    #[abi(embed_v0)]
    impl FollowImpl of IFollowNFT<ContractState> {
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

        /// @notice performs the blocking action
        /// @param follower_profile_address address of the user to be blocked
        fn process_block(
            ref self: ContractState, follower_profile_address: ContractAddress
        ) -> bool {
            hub_only(self.karst_hub.read());
            let follow_id = self
                .follow_id_by_follower_profile_address
                .read(follower_profile_address);
            assert(follow_id.is_non_zero(), Errors::NOT_FOLLOWING);
            let follow_data = self.follow_data_by_follow_id.read(follow_id);
            self
                .follow_data_by_follow_id
                .write(
                    follow_id,
                    FollowData {
                        followed_profile_address: follow_data.followed_profile_address,
                        follower_profile_address: follow_data.follower_profile_address,
                        follow_timestamp: follow_data.follow_timestamp,
                        block_status: true,
                    }
                );
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

        /// @notice performs the unblocking action
        /// @param follower_profile_address address of the user to be unblocked
        fn process_unblock(
            ref self: ContractState, follower_profile_address: ContractAddress
        ) -> bool {
            hub_only(self.karst_hub.read());
            let follow_id = self
                .follow_id_by_follower_profile_address
                .read(follower_profile_address);
            assert(follow_id.is_non_zero(), Errors::NOT_FOLLOWING);
            let follow_data = self.follow_data_by_follow_id.read(follow_id);
            self
                .follow_data_by_follow_id
                .write(
                    follow_id,
                    FollowData {
                        followed_profile_address: follow_data.followed_profile_address,
                        follower_profile_address: follow_data.follower_profile_address,
                        follow_timestamp: follow_data.follow_timestamp,
                        block_status: false,
                    }
                );
            self
                .emit(
                    FollowerUnblocked {
                        followed_address: self.followed_profile_address.read(),
                        unblocked_follower: follower_profile_address,
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

        /// @notice checks if a particular address is blocked by the followed profile
        /// @param follower_profile_address address of the user to check
        fn is_blocked(self: @ContractState, follower_profile_address: ContractAddress) -> bool {
            let follow_id = self
                .follow_id_by_follower_profile_address
                .read(follower_profile_address);
            self.follow_data_by_follow_id.read(follow_id).block_status
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
        /// @notice returns the collection name
        fn name(self: @ContractState) -> ByteArray {
            return "KARST:FOLLOWER";
        }

        /// @notice returns the collection symbol
        fn symbol(self: @ContractState) -> ByteArray {
            return "KFL";
        }

        /// @notice returns the token URI of a particular follow NFT
        /// @param follow_id ID of NFT to be queried
        fn token_uri(self: @ContractState, follow_id: u256) -> ByteArray {
            let follow_data = self.follow_data_by_follow_id.read(follow_id);
            let timestamp = follow_data.follow_timestamp;
            let followed_profile_address = self.followed_profile_address.read();
            FollowTokenUri::get_token_uri(follow_id, followed_profile_address, timestamp)
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
            self.erc721._mint(follower_profile_address, new_follower_id);

            let follow_timestamp: u64 = get_block_timestamp();
            let follow_data = FollowData {
                followed_profile_address: self.followed_profile_address.read(),
                follower_profile_address: follower_profile_address,
                follow_timestamp: follow_timestamp,
                block_status: false,
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
            self.erc721._burn(follow_id);
            self.follow_id_by_follower_profile_address.write(unfollower, 0);
            self
                .follow_data_by_follow_id
                .write(
                    follow_id,
                    FollowData {
                        followed_profile_address: 0.try_into().unwrap(),
                        follower_profile_address: 0.try_into().unwrap(),
                        follow_timestamp: 0,
                        block_status: false,
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
