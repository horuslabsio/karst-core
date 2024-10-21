#[starknet::component]
pub mod ChannelComponent {
    // *************************************************************************
    //                            IMPORT
    // *************************************************************************
    use core::clone::Clone;
    use core::starknet::{
        ContractAddress, contract_address_const, get_caller_address, get_block_timestamp, ClassHash,
        syscalls::deploy_syscall, SyscallResultTrait
    };
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, Map, StorageMapReadAccess,
        StorageMapWriteAccess
    };
    use openzeppelin::access::ownable::OwnableComponent;

    use karst::jolt::jolt::JoltComponent;
    use karst::community::community::CommunityComponent;
    use karst::interfaces::{
        IChannel::IChannel, ICommunity::ICommunity,
        ICustomNFT::{ICustomNFTDispatcher, ICustomNFTDispatcherTrait}
    };
    use karst::base::{
        constants::errors::Errors::{
            NOT_CHANNEL_OWNER, ALREADY_MEMBER, NOT_CHANNEL_MEMBER, NOT_COMMUNITY_MEMBER,
            BANNED_FROM_CHANNEL, CHANNEL_HAS_NO_MEMBER, UNAUTHORIZED, INVALID_LENGTH,
            COMMUNITY_DOES_NOT_EXIST, NOT_CHANNEL_MODERATOR
        },
        constants::types::{ChannelDetails, ChannelMember}
    };

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    pub struct Storage {
        channels: Map<u256, ChannelDetails>,
        channel_counter: u256,
        channel_members: Map<(u256, ContractAddress), ChannelMember>,
        channel_moderators: Map<(u256, ContractAddress), bool>,
        channel_nft_classhash: ClassHash,
        channel_ban_status: Map<(u256, ContractAddress), bool>,
    }

    // *************************************************************************
    //                              EVENTS
    // *************************************************************************
    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        ChannelCreated: ChannelCreated,
        JoinedChannel: JoinedChannel,
        LeftChannel: LeftChannel,
        ChannelModAdded: ChannelModAdded,
        ChannelModRemoved: ChannelModRemoved,
        ChannelBanStatusUpdated: ChannelBanStatusUpdated,
        DeployedChannelNFT: DeployedChannelNFT
    }

    #[derive(Drop, starknet::Event)]
    pub struct ChannelCreated {
        pub channel_id: u256,
        pub channel_owner: ContractAddress,
        pub channel_nft_address: ContractAddress,
        pub block_timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct JoinedChannel {
        pub channel_id: u256,
        pub transaction_executor: ContractAddress,
        pub profile: ContractAddress,
        pub token_id: u256,
        pub block_timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct LeftChannel {
        pub channel_id: u256,
        pub transaction_executor: ContractAddress,
        pub profile: ContractAddress,
        pub token_id: u256,
        pub block_timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct ChannelModAdded {
        pub channel_id: u256,
        pub transaction_executor: ContractAddress,
        pub mod_address: ContractAddress,
        pub block_timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct ChannelModRemoved {
        pub channel_id: u256,
        pub transaction_executor: ContractAddress,
        pub mod_address: ContractAddress,
        pub block_timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct ChannelBanStatusUpdated {
        pub channel_id: u256,
        pub transaction_executor: ContractAddress,
        pub profile: ContractAddress,
        pub ban_status: bool,
        pub block_timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct DeployedChannelNFT {
        pub channel_id: u256,
        pub channel_nft: ContractAddress,
        pub block_timestamp: u64,
    }

    // *************************************************************************
    //                              EXTERNAL FUNCTIONS
    // *************************************************************************
    #[embeddable_as(KarstChannel)]
    impl ChannelImpl<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl Community: CommunityComponent::HasComponent<TContractState>,
        impl Jolt: JoltComponent::HasComponent<TContractState>,
        impl Ownable: OwnableComponent::HasComponent<TContractState>
    > of IChannel<ComponentState<TContractState>> {
        /// @notice creates a new channel
        fn create_channel(ref self: ComponentState<TContractState>, community_id: u256) -> u256 {
            let channel_id = self.channel_counter.read() + 1;
            let channel_owner = get_caller_address();
            let channel_nft_classhash = self.channel_nft_classhash.read();

            // check that community exists
            let community_instance = get_dep_component!(@self, Community);
            let _community_id = community_instance.get_community(community_id).community_id;
            assert(community_id == _community_id, COMMUNITY_DOES_NOT_EXIST);

            // deploy channel nft
            let channel_nft_address = self
                ._deploy_channel_nft(
                    channel_id, channel_nft_classhash, channel_id.try_into().unwrap()
                ); // use channel_id as salt since its unique

            // check that owner is a member of the community
            let (membership_status, _) = community_instance
                .is_community_member(channel_owner, community_id);
            assert(membership_status, NOT_COMMUNITY_MEMBER);

            let new_channel = ChannelDetails {
                channel_id: channel_id,
                community_id: community_id,
                channel_owner: channel_owner,
                channel_metadata_uri: "",
                channel_nft_address: channel_nft_address,
                channel_total_members: 0,
                channel_censorship: false,
            };

            // update storage
            self.channels.write(channel_id, new_channel.clone());
            self.channel_counter.write(channel_id);

            // include channel owner as first member
            self._join_channel(channel_owner, channel_id);

            // emit event
            self
                .emit(
                    ChannelCreated {
                        channel_id: new_channel.channel_id,
                        channel_owner: new_channel.channel_owner,
                        channel_nft_address: new_channel.channel_nft_address,
                        block_timestamp: get_block_timestamp(),
                    }
                );

            channel_id
        }

        /// @notice adds a new user to a channel
        /// @param channel_id id of channel to be joined
        fn join_channel(ref self: ComponentState<TContractState>, channel_id: u256) {
            let profile = get_caller_address();

            // check user is not already a channel member and wasn't previously banned
            let (is_channel_member, _) = self.is_channel_member(profile, channel_id);
            let is_banned = self.get_channel_ban_status(profile, channel_id);

            assert(!is_banned, BANNED_FROM_CHANNEL);
            assert(!is_channel_member, ALREADY_MEMBER);

            // join channel
            self._join_channel(profile, channel_id);
        }

        /// @notice removes a member from a channel
        /// @param channel_id id of channel to be left
        fn leave_channel(ref self: ComponentState<TContractState>, channel_id: u256) {
            let mut channel = self.channels.read(channel_id);
            let profile = get_caller_address();
            let channel_member = self.channel_members.read((channel_id, profile));

            // check that profile is a channel member
            let (is_channel_member, _) = self.is_channel_member(profile, channel_id);
            assert(is_channel_member, NOT_CHANNEL_MEMBER);

            // check that channel has members
            let total_members: u256 = channel.channel_total_members;
            assert(total_members > 1, CHANNEL_HAS_NO_MEMBER);

            // burn user's community token
            self._burn_channel_nft(channel.channel_nft_address, channel_member.channel_token_id);

            // update storage
            self
                .channel_members
                .write(
                    (channel_id, profile),
                    ChannelMember {
                        profile: contract_address_const::<0>(),
                        channel_id: 0,
                        total_publications: 0,
                        channel_token_id: 0,
                    }
                );

            channel.channel_total_members -= 1;
            self.channels.write(channel_id, channel);
            // emit event
            self
                .emit(
                    LeftChannel {
                        channel_id: channel_id,
                        transaction_executor: get_caller_address(),
                        profile: profile,
                        token_id: channel_member.channel_token_id,
                        block_timestamp: get_block_timestamp(),
                    }
                )
        }

        /// @notice Set the metadata URI of the channel
        /// @param channel_id The id of the channel
        /// @param metadata_uri The new metadata URI
        /// @dev Only the owner of the channel or a mod can set the metadata URI
        fn set_channel_metadata_uri(
            ref self: ComponentState<TContractState>, channel_id: u256, metadata_uri: ByteArray
        ) {
            let channel_member: ChannelDetails = self.channels.read(channel_id);
            assert(
                channel_member.channel_owner == get_caller_address()
                    || self.is_channel_mod(get_caller_address(), channel_id),
                UNAUTHORIZED
            );
            let mut channel: ChannelDetails = self.channels.read(channel_id);
            channel.channel_metadata_uri = metadata_uri;
            self.channels.write(channel_id, channel);
        }

        /// @notice Add a moderator to the channel
        /// @param channel_id: The id of the channel
        /// @param Array<moderator> The address of the moderator
        /// dev only primary moderator/owner can add the moderators
        fn add_channel_mods(
            ref self: ComponentState<TContractState>,
            channel_id: u256,
            moderators: Array<ContractAddress>
        ) {
            assert(
                self.channels.read(channel_id).channel_owner == get_caller_address(),
                NOT_CHANNEL_OWNER
            );

            self._add_channel_mods(channel_id, moderators);
        }

        /// @notice Remove a moderator from the channel
        /// @param channel_id: The id of the channel
        /// @param moderator: The address of the moderator
        /// dev only primary moderator/owner can remove the moderators
        fn remove_channel_mods(
            ref self: ComponentState<TContractState>,
            channel_id: u256,
            moderators: Array<ContractAddress>
        ) {
            assert(
                self.channels.read(channel_id).channel_owner == get_caller_address(),
                NOT_CHANNEL_OWNER
            );

            self._remove_channel_mods(channel_id, moderators);
        }

        /// @notice Set the censorship status of the channel
        /// @param channel_id The id of the channel
        fn set_channel_censorship_status(
            ref self: ComponentState<TContractState>, channel_id: u256, censorship_status: bool
        ) {
            let mut channel = self.channels.read(channel_id);

            // check caller is owner
            assert(channel.channel_owner == get_caller_address(), NOT_CHANNEL_OWNER);

            // update storage
            channel.channel_censorship = censorship_status;
            self.channels.write(channel_id, channel);
        }

        /// @notice set the ban status of a profile in the channel
        /// @param channel_id The id of the channel
        /// @param profile The address of the profile
        /// @param ban_status The ban status of the profile
        fn set_channel_ban_status(
            ref self: ComponentState<TContractState>,
            channel_id: u256,
            profiles: Array<ContractAddress>,
            ban_statuses: Array<bool>
        ) {
            let mut channel = self.channels.read(channel_id);

            // check caller is owner or mod
            assert(
                channel.channel_owner == get_caller_address()
                    || self.is_channel_mod(get_caller_address(), channel_id),
                UNAUTHORIZED
            );

            self._set_ban_status(channel_id, profiles, ban_statuses);
        }

        /// @notice gets the channel parameters
        /// @param channel_id The id of the channel
        /// @return ChannelDetails The channel parameters
        fn get_channel(self: @ComponentState<TContractState>, channel_id: u256) -> ChannelDetails {
            self.channels.read(channel_id)
        }

        /// @notice gets the metadata URI of the channel
        /// @param channel_id The id of the channel
        /// @return ByteArray The metadata URI
        fn get_channel_metadata_uri(
            self: @ComponentState<TContractState>, channel_id: u256
        ) -> ByteArray {
            self.channels.read(channel_id).channel_metadata_uri
        }

        /// @notice checks if the profile is a member of the channel
        /// @param profile the address of the profile
        /// @param channel_id the id of the channel
        /// @return bool the profile membership status
        fn is_channel_member(
            self: @ComponentState<TContractState>, profile: ContractAddress, channel_id: u256
        ) -> (bool, ChannelMember) {
            let channel_member: ChannelMember = self.channel_members.read((channel_id, profile));
            if (channel_member.channel_id == channel_id) {
                (true, channel_member)
            } else {
                (false, channel_member)
            }
        }

        /// @notice gets the total number of members in a channel
        /// @param channel_id the id of the channel
        /// @return u256 the number of members in a channel
        fn get_total_channel_members(
            self: @ComponentState<TContractState>, channel_id: u256
        ) -> u256 {
            self.channels.read(channel_id).channel_total_members
        }

        /// @notice checks if a profile is a moderator
        /// @param profile addresss to be checked
        /// @param channel_id the id of the channel
        /// @return bool the moderator status
        fn is_channel_mod(
            self: @ComponentState<TContractState>, profile: ContractAddress, channel_id: u256
        ) -> bool {
            self.channel_moderators.read((channel_id, profile))
        }

        /// @notice checks if a channel is censored
        /// @param channel_id the id of the channel
        /// @return bool the censorship status
        fn get_channel_censorship_status(
            self: @ComponentState<TContractState>, channel_id: u256
        ) -> bool {
            self.channels.read(channel_id).channel_censorship
        }

        /// @notice checks if a profile is banned
        /// @param profile addresss to be checked
        /// @param channel_id the id of the channel
        /// @return bool the ban status
        fn get_channel_ban_status(
            self: @ComponentState<TContractState>, profile: ContractAddress, channel_id: u256
        ) -> bool {
            self.channel_ban_status.read((channel_id, profile))
        }
    }

    // *************************************************************************
    //                            PRIVATE FUNCTIONS
    // *************************************************************************
    #[generate_trait]
    pub impl InternalImpl<
        TContractState,
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl Community: CommunityComponent::HasComponent<TContractState>,
        impl Jolt: JoltComponent::HasComponent<TContractState>,
        impl Ownable: OwnableComponent::HasComponent<TContractState>
    > of InternalTrait<TContractState> {
        /// @notice initalizes channel component
        /// @param channel_nft_classhash classhash of channel NFT
        fn _initializer(ref self: ComponentState<TContractState>, channel_nft_classhash: felt252) {
            self.channel_counter.write(0);
            self.channel_nft_classhash.write(channel_nft_classhash.try_into().unwrap());
        }

        /// @notice internal function to join a channel
        /// @param profile address to add to the channel
        /// @param channel_id id of the channel to be joined
        fn _join_channel(
            ref self: ComponentState<TContractState>, profile: ContractAddress, channel_id: u256
        ) {
            let mut channel: ChannelDetails = self.channels.read(channel_id);

            // check that user is a member of the community this channel belongs to
            let community_instance = get_dep_component!(@self, Community);
            let (membership_status, _) = community_instance
                .is_community_member(profile, channel.community_id);
            assert(membership_status, NOT_COMMUNITY_MEMBER);

            // mint a channel token to new joiner
            let minted_token_id = self._mint_channel_nft(profile, channel.channel_nft_address);

            let channel_member = ChannelMember {
                profile: profile,
                channel_id: channel_id,
                total_publications: 0,
                channel_token_id: minted_token_id,
            };

            // update storage
            channel.channel_total_members += 1;
            self.channels.write(channel_id, channel);
            self.channel_members.write((channel_id, profile), channel_member);

            // emit events
            self
                .emit(
                    JoinedChannel {
                        channel_id: channel_id,
                        transaction_executor: get_caller_address(),
                        profile: profile,
                        token_id: minted_token_id,
                        block_timestamp: get_block_timestamp(),
                    }
                )
        }

        /// @notice internal function for adding channel mod
        /// @param channel_id id of channel
        /// @param moderators array of moderators
        fn _add_channel_mods(
            ref self: ComponentState<TContractState>,
            channel_id: u256,
            moderators: Array<ContractAddress>
        ) {
            let length = moderators.len();
            let mut index: u32 = 0;

            while index < length {
                let moderator = *moderators.at(index);

                // check moderator is a channel member
                let (is_channel_member, _) = self.is_channel_member(moderator, channel_id);
                assert(is_channel_member == true, NOT_CHANNEL_MEMBER);

                self.channel_moderators.write((channel_id, moderator), true);

                // emit event
                self
                    .emit(
                        ChannelModAdded {
                            channel_id: channel_id,
                            transaction_executor: get_caller_address(),
                            mod_address: moderator,
                            block_timestamp: get_block_timestamp(),
                        }
                    );
                index += 1;
            };
        }

        /// @notice internal function for removing channel mod
        /// @param channel_id id of channel
        // @param moderators to remove
        fn _remove_channel_mods(
            ref self: ComponentState<TContractState>,
            channel_id: u256,
            moderators: Array<ContractAddress>
        ) {
            let length = moderators.len();
            let mut index: u32 = 0;

            while index < length {
                let moderator = *moderators.at(index);

                // check that profile is a moderator
                let is_moderator = self.is_channel_mod(moderator, channel_id);
                assert(is_moderator, NOT_CHANNEL_MODERATOR);

                self.channel_moderators.write((channel_id, moderator), false);

                // emit event
                self
                    .emit(
                        ChannelModRemoved {
                            channel_id: channel_id,
                            mod_address: moderator,
                            transaction_executor: get_caller_address(),
                            block_timestamp: get_block_timestamp()
                        }
                    );
                index += 1;
            };
        }

        /// @notice internal function for set ban status for members
        /// @param channel_id id of channel to be banned or unbanned
        /// @param profiles addresses
        /// @param ban_statuses bool values
        fn _set_ban_status(
            ref self: ComponentState<TContractState>,
            channel_id: u256,
            profiles: Array<ContractAddress>,
            ban_statuses: Array<bool>
        ) {
            assert(profiles.len() == ban_statuses.len(), INVALID_LENGTH);
            let length = profiles.len();
            let mut index: u32 = 0;

            while index < length {
                let profile = *profiles[index];
                let ban_status = *ban_statuses[index];

                // check profile is a channel member
                let (is_channel_member, _) = self.is_channel_member(profile, channel_id);
                assert(is_channel_member == true, NOT_CHANNEL_MEMBER);

                // update storage
                // let channel_member = self.channel_members.read((channel_id, profile));
                // let updated_member = ChannelMember { ban_status: ban_status, ..channel_member };
                // self.channel_members.write((channel_id, profile), updated_member);
                self.channel_ban_status.write((channel_id, profile), ban_status);
                // emit event
                self
                    .emit(
                        ChannelBanStatusUpdated {
                            channel_id: channel_id,
                            transaction_executor: get_caller_address(),
                            profile: profile,
                            ban_status: ban_status,
                            block_timestamp: get_block_timestamp()
                        }
                    );
                index += 1;
            };
        }

        /// @notice internal function to deploy a channel nft
        /// @param channel_id id of channel
        /// @param salt for randomization
        fn _deploy_channel_nft(
            ref self: ComponentState<TContractState>,
            channel_id: u256,
            channel_nft_impl_class_hash: ClassHash,
            salt: felt252
        ) -> ContractAddress {
            let mut constructor_calldata: Array<felt252> = array![
                channel_id.low.into(), channel_id.high.into()
            ];

            let (account_address, _) = deploy_syscall(
                channel_nft_impl_class_hash, salt, constructor_calldata.span(), true
            )
                .unwrap_syscall();

            self
                .emit(
                    DeployedChannelNFT {
                        channel_id: channel_id,
                        channel_nft: account_address,
                        block_timestamp: get_block_timestamp()
                    }
                );
            account_address
        }

        /// @notice internal function to mint a channel nft
        /// @param profile profile to be minted to
        /// @param channel_nft_address address of channel nft
        fn _mint_channel_nft(
            ref self: ComponentState<TContractState>,
            profile: ContractAddress,
            channel_nft_address: ContractAddress
        ) -> u256 {
            let token_id = ICustomNFTDispatcher { contract_address: channel_nft_address }
                .mint_nft(profile);
            token_id
        }

        /// @notice internal function to burn a channel nft
        /// @param channel_nft_address address of channel nft
        /// @param token_id to burn
        fn _burn_channel_nft(
            ref self: ComponentState<TContractState>,
            channel_nft_address: ContractAddress,
            token_id: u256
        ) {
            ICustomNFTDispatcher { contract_address: channel_nft_address }
                .burn_nft(get_caller_address(), token_id);
        }
    }
}
