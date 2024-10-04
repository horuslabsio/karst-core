//TODO make the channel as the componet
#[starknet::component]
pub mod ChannelComponent {
    use core::clone::Clone;
    use core::starknet::{
        ContractAddress, get_caller_address, get_block_timestamp,
        storage::{
            StoragePointerWriteAccess, StoragePointerReadAccess, Map, StorageMapReadAccess,
            StorageMapWriteAccess
        }
    };
    use karst::interfaces::IChannel::IChannel;
    use karst::base::{
        constants::errors::Errors::{
            NOT_CHANNEL_OWNER, NOT_CHANNEL_MODERATOR, NOT_CHANNEL_MEMBER, BANNED_FROM_CHANNEL
        },
        constants::types::{channelParams, channelMember}
    };
    #[storage]
    pub struct Storage {
        channels: Map<u256, channelParams>,
        channel_counter: u256,
        channel_members: Map<ContractAddress, channelMember>,
        channel_moderators: Map<(u256, ContractAddress), bool>,
    }

    #[derive(Drop, starknet::Event)]
    pub struct ChannelCreated {
        channel_id: u256,
        channel_owner: ContractAddress,
        channel_nft_address: ContractAddress,
        block_timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct JoinedChannel {
        channel_id: u256,
        transaction_executor: ContractAddress,
        token_id: u256,
        block_timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct LeftChannel {
        channel_id: u256,
        transaction_executor: ContractAddress,
        token_id: u256,
        block_timestamp: u64,
    }
    // this should also contain the IChannel & IChannelNFT implmentation , waht is the self what d.
    #[derive(Drop, starknet::Event)]
    pub struct ChannelModAdded {
        channel_id: u256,
        transaction_executor: ContractAddress,
        mod_address: ContractAddress,
        block_timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct ChannelModRemoved {
        channel_id: u256,
        transaction_executor: ContractAddress,
        mod_address: ContractAddress,
        block_timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct ChannelBanStatusUpdated {
        channel_id: u256,
        transaction_executor: ContractAddress,
        profile: ContractAddress,
        block_timestamp: u64,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        ChannelCreated: ChannelCreated,
        JoinedChannel: JoinedChannel,
        LeftChannel: LeftChannel,
        ChannelModAdded: ChannelModAdded,
        ChannelModRemoved: ChannelModRemoved,
        ChannelBanStatusUpdated: ChannelBanStatusUpdated,
    }


    // mnaking the constructor  to store the onwer , who can set the moderators

    #[embeddable_as(KarstChannel)]
    impl ChannelImpl<
        TContractState, +HasComponent<TContractState>, +Drop<TContractState>
    > of IChannel<ComponentState<TContractState>> {
        ///@notice Create a new channel
        ///@param channel_params: The parameters of the channel
        fn create_channel(
            ref self: ComponentState<TContractState>, channel_params: channelParams
        ) -> u256 {
            let channel_id: u256 = self.channel_counter.read();
            let new_channel = channelParams {
                channel_id: channel_id,
                channel_owner: channel_params.channel_owner,
                channel_metadata_uri: channel_params.channel_metadata_uri,
                channel_nft_address: channel_params.channel_nft_address,
                channel_total_members: 0,
                channel_censorship: channel_params.channel_censorship,
            };
            // increment
            self.channels.write(channel_id, new_channel.clone());
            self.channel_counter.write(channel_id + 1);
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


        ///TODO : Add the minting of the NFT
        /// @notice Join the channel
        /// @param channel_id: The id of the channel
        fn join_channel(ref self: ComponentState<TContractState>, channel_id: u256) {
            // check that i prioor not baned
            let channel_member: channelMember = self.channel_members.read(get_caller_address());
            assert(!channel_member.ban_status, BANNED_FROM_CHANNEL);

            let mut new_channel: channelParams = self.channels.read(channel_id);
            new_channel.channel_total_members += 1;
            self.channels.write(channel_id, new_channel);

            // calculate the total channel member add +1  is the new member id

            self
                .channel_members
                .write(
                    get_caller_address(),
                    channelMember {
                        profile: get_caller_address(),
                        channel_id: channel_id,
                        total_publications: 0,
                        channel_token_id: 0, //TODO impl token gating  self.get_user_token_id(get_caller_address()),
                        ban_status: false,
                    }
                );
            // self.mint_nft(get_caller_address());
            self
                .emit(
                    JoinedChannel {
                        channel_id: channel_id,
                        transaction_executor: get_caller_address(),
                        token_id: 0, // dummy value 
                        // token_id: self.last_minted_id.read() + 1,
                        block_timestamp: get_block_timestamp(),
                    }
                )
        }


        /// @notice Leave the channel
        /// @param channel_id: The id of the channel
        /// @dev The user must be a member of the channel
        fn leave_channel(ref self: ComponentState<TContractState>, channel_id: u256) {
            assert(
                self.channel_members.read(get_caller_address()).channel_id == channel_id,
                NOT_CHANNEL_MEMBER
            );
            assert(
                !self.channel_members.read(get_caller_address()).ban_status, BANNED_FROM_CHANNEL
            );
            assert(self.channels.read(channel_id).channel_total_members > 1, 'total_member  > 1');

            self
                .channel_members
                .write(
                    get_caller_address(),
                    channelMember {
                        profile: get_caller_address(),
                        // todo , what default channel id should set max but not optimize to store
                        channel_id: 10000000,
                        total_publications: 0,
                        channel_token_id: 0,
                        ban_status: false,
                    }
                );

            let mut new_channel: channelParams = self.channels.read(channel_id);
            new_channel.channel_total_members -= 1;
            self.channels.write(channel_id, new_channel);

            //TODO Delete the mapping at the caller address
            //TODO : burn the NFT
            self
                .emit(
                    LeftChannel {
                        channel_id: channel_id,
                        transaction_executor: get_caller_address(),
                        token_id: 0, //TODO impl token gating  self.get_user_token_id(get_caller_address()),
                        block_timestamp: get_block_timestamp(),
                    }
                )
        }


        /// @notice Set the metadata URI of the channel
        /// @param channel_id: The id of the channel
        /// @param metadata_uri: The new metadata URI
        /// @dev Only the owner of the channel can set the metadata URI
        fn set_channel_metadata_uri(
            ref self: ComponentState<TContractState>, channel_id: u256, metadata_uri: ByteArray
        ) {
            let channel_member: channelParams = self.channels.read(channel_id);
            assert(
                channel_member.channel_owner == get_caller_address()
                    || self.channel_moderators.read((channel_id, get_caller_address())),
                NOT_CHANNEL_MODERATOR
            );
            let mut new_channel: channelParams = self.channels.read(channel_id);
            new_channel.channel_metadata_uri = metadata_uri;
            self.channels.write(channel_id, new_channel);
        }


        /// @notice Add a moderator to the channel
        /// @param channel_id: The id of the channel
        /// @param moderator: The address of the moderator
        /// dev only primary moderator/owner can add the moderators
        fn add_channel_mods(
            ref self: ComponentState<TContractState>, channel_id: u256, moderator: ContractAddress
        ) {
            assert(
                self.channels.read(channel_id).channel_owner == get_caller_address(),
                NOT_CHANNEL_OWNER
            );

            self.channel_moderators.write((channel_id, moderator), true);
            self
                .emit(
                    ChannelModAdded {
                        channel_id: channel_id,
                        transaction_executor: get_caller_address(),
                        mod_address: moderator,
                        block_timestamp: get_block_timestamp(),
                    }
                )
        }


        /// @notice Remove a moderator from the channel
        /// @param channel_id: The id of the channel
        /// @param moderator: The address of the moderator
        /// dev only primary moderator/owner can remove the moderators
        fn remove_channel_mods(
            ref self: ComponentState<TContractState>, channel_id: u256, moderator: ContractAddress
        ) {
            // let channel_member: channelParams = self.channels.read(channel_id);
            assert(
                self.channels.read(channel_id).channel_owner == get_caller_address(),
                NOT_CHANNEL_OWNER
            );

            self.channel_moderators.write((channel_id, moderator), false);

            self
                .emit(
                    ChannelModRemoved {
                        channel_id: channel_id,
                        transaction_executor: get_caller_address(),
                        mod_address: moderator,
                        block_timestamp: get_block_timestamp(),
                    }
                )
        }


        /// @notice Set the censorship status of the channel
        /// @param channel_id: The id of the channel
        fn set_channel_censorship_status(
            ref self: ComponentState<TContractState>, channel_id: u256, censorship_status: bool
        ) {
            // let channel_member: channelParams = self.channels.read(channel_id);
            assert(
                self.channels.read(channel_id).channel_owner == get_caller_address(),
                NOT_CHANNEL_OWNER
            );
            let mut new_channel: channelParams = self.channels.read(channel_id);
            new_channel.channel_censorship = censorship_status;
            self.channels.write(channel_id, new_channel);
        }


        ///@notice Set the ban status of a profile in the channel
        /// @param channel_id: The id of the channel
        /// @param profile: The address of the profile
        /// @param ban_status: The ban status of the profile
        fn set_ban_status(
            ref self: ComponentState<TContractState>,
            channel_id: u256,
            profile: ContractAddress,
            ban_status: bool
        ) {
            // let channel_member: channelParams = self.channels.read(channel_id);
            assert(
                self.channels.read(channel_id).channel_owner == get_caller_address()
                    || self.channel_moderators.read((channel_id, get_caller_address())),
                NOT_CHANNEL_MODERATOR
            );
            let mut new_channel_member: channelMember = self.channel_members.read(profile);
            new_channel_member.ban_status = ban_status;
            self.channel_members.write(profile, new_channel_member);

            self
                .emit(
                    ChannelBanStatusUpdated {
                        channel_id: channel_id,
                        transaction_executor: get_caller_address(),
                        profile: profile,
                        block_timestamp: get_block_timestamp(),
                    }
                )
        }


        ///@notice Get the channel parameters
        /// @param channel_id: The id of the channel
        /// @return The channel parameters
        fn get_channel(self: @ComponentState<TContractState>, channel_id: u256) -> channelParams {
            self.channels.read(channel_id)
        }

        ///@notice Get the metadata URI of the channel
        /// @param channel_id: The id of the channel
        /// @return The metadata URI
        fn get_channel_metadata_uri(
            self: @ComponentState<TContractState>, channel_id: u256
        ) -> ByteArray {
            let channel: channelParams = self.channels.read(channel_id);
            channel.channel_metadata_uri
        }

        ///@notice Check if the profile is a member of the channel
        ///@param profile: The address of the profile
        ///@return A tuple of the membership status and the channel id
        fn is_channel_member(
            self: @ComponentState<TContractState>, profile: ContractAddress, channel_id: u256
        ) -> bool {
            let channel_member: channelMember = self.channel_members.read(profile);
            if (channel_member.channel_id == channel_id) {
                true
            } else {
                false
            }
        }


        ///TODO :get the total number of mener of the channel
        fn get_total_members(self: @ComponentState<TContractState>, channel_id: u256) -> u256 {
            let channel: channelParams = self.channels.read(channel_id);
            channel.channel_total_members
        }

        ///@notice check for moderator
        /// @param channel id
        /// @param profile addresss
        fn is_channel_mod(
            self: @ComponentState<TContractState>, profile: ContractAddress, channel_id: u256
        ) -> bool {
            self.channel_moderators.read((channel_id, profile))
        }

        fn get_channel_censorship_status(
            self: @ComponentState<TContractState>, channel_id: u256
        ) -> bool {
            let channel: channelParams = self.channels.read(channel_id);
            channel.channel_censorship
        }

        ///TODO introduce new storage for ban status
        fn get_ban_status(self: @ComponentState<TContractState>, profile: ContractAddress) -> bool {
            let channel_member: channelMember = self.channel_members.read(profile);
            channel_member.ban_status
        }
    }
}
