#[starknet::component]
pub mod ChannelComponent {
    // *************************************************************************
    //                            IMPORT
    // *************************************************************************
    use core::clone::Clone;
    use core::starknet::{
        ContractAddress, contract_address_const, get_caller_address, get_block_timestamp, ClassHash, syscalls::deploy_syscall, SyscallResultTrait
    };
    use starknet::storage::{
        StoragePointerReadAccess, StoragePointerWriteAccess, StoragePathEntry, Map,
        StorageMapReadAccess, StorageMapWriteAccess, Vec, VecTrait, MutableVecTrait
    };
    use karst::interfaces::IChannel::IChannel;
    use karst::interfaces::ICommunity::ICommunity;
    use karst::interfaces::ICommunityNft::{ICommunityNftDispatcher, ICommunityNftDispatcherTrait};
    use karst::community::community::CommunityComponent;
    use karst::base::{
        constants::errors::Errors::{
            NOT_CHANNEL_OWNER, ALREADY_MEMBER, NOT_CHANNEL_MEMBER, NOT_MEMBER, BANNED_FROM_CHANNEL,
            CHANNEL_HAS_NO_MEMBER, UNAUTHORIZED_ACESS
        },
        constants::types::{channelDetails, channelMember}
    };

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    pub struct Storage {
        channels: Map<u256, channelDetails>,
        channel_counter: u256,
        channel_members: Map<(u256, ContractAddress), channelMember>,
        channel_moderators: Map<u256, Vec<ContractAddress>>,
        channel_nft_classhash: ClassHash,
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

    #[derive(Drop, starknet::Event)]
    pub struct ChannelModAdded {
        channel_id: u256,
        transaction_executor: ContractAddress,
        mod_address: Array<ContractAddress>,
        block_timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct ChannelModRemoved {
        channel_id: u256,
        transaction_executor: ContractAddress,
        mod_address: Array<ContractAddress>,
        block_timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct ChannelBanStatusUpdated {
        channel_id: u256,
        transaction_executor: ContractAddress,
        profile: ContractAddress,
        block_timestamp: u64,
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
        impl Community: CommunityComponent::HasComponent<TContractState>
    > of IChannel<ComponentState<TContractState>> {
        /// @notice creates a new channel
        fn create_channel(
            ref self: ComponentState<TContractState>, community_id: u256
        ) -> u256 {
            let channel_id = self.channel_counter.read() + 1;
            let channel_owner = get_caller_address();

            let new_channel = channelDetails {
                channel_id: channel_id,
                community_id: community_id,
                channel_owner: channel_owner,
                channel_metadata_uri: "",
                channel_nft_address: 1.try_into().unwrap(),
                channel_total_members: 0,
                channel_censorship: false,
            };

            // include channel owner as first member
            self._join_channel(channel_owner, channel_id);

            // update storage
            self.channels.write(channel_id, new_channel.clone());
            self.channel_counter.write(channel_id);

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
            let is_channel_member = self.is_channel_member(profile, channel_id);
            let is_banned = self.get_ban_status(profile, channel_id);
            assert(!is_channel_member, ALREADY_MEMBER);
            assert(!is_banned, BANNED_FROM_CHANNEL);

            // join channel
            self._join_channel(profile, channel_id);
        }


        /// @notice removes a member from a channel
        /// @param channel_id id of channel to be left
        fn leave_channel(ref self: ComponentState<TContractState>, channel_id: u256) {
            // check that profile is a channel member
            assert(
                self
                    .channel_members
                    .read((channel_id, get_caller_address()))
                    .channel_id == channel_id
                    && self
                        .channel_members
                        .read((channel_id, get_caller_address()))
                        .profile == get_caller_address(),
                NOT_CHANNEL_MEMBER
            );

            // check that channel has members
            let total_members: u256 = self.channels.read(channel_id).channel_total_members;
            assert(total_members > 1, CHANNEL_HAS_NO_MEMBER);

            // update storage
            self
                .channel_members
                .write(
                    (channel_id, get_caller_address()),
                    channelMember {
                        profile: contract_address_const::<0>(),
                        channel_id: 0,
                        total_publications: 0,
                        channel_token_id: 0,
                        ban_status: false,
                    }
                );

            let mut channel: channelDetails = self.channels.read(channel_id);
            channel.channel_total_members -= 1;
            self.channels.write(channel_id, channel);

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
            let channel_member: channelDetails = self.channels.read(channel_id);
            assert(
                channel_member.channel_owner == get_caller_address()
                    || self.is_channel_mod(get_caller_address(), channel_id),
                UNAUTHORIZED_ACESS
            );
            let mut channel: channelDetails = self.channels.read(channel_id);
            channel.channel_metadata_uri = metadata_uri;
            self.channels.write(channel_id, channel);
        }


        /// @notice Add a moderator to the channel
        /// @param channel_id: The id of the channel
        /// @param Array<moderator>: The address of the moderator
        /// dev only primary moderator/owner can add the moderators
        fn add_channel_mods(
            ref self: ComponentState<TContractState>,
            channel_id: u256,
            moderator: Array<ContractAddress>
        ) {
            assert(
                self.channels.read(channel_id).channel_owner == get_caller_address(),
                NOT_CHANNEL_OWNER
            );

            for i in 0
                ..moderator
                    .len() {
                        if (!self.is_channel_mod(*moderator.at(i), channel_id)) {
                            self
                                .channel_moderators
                                .entry(channel_id)
                                .append()
                                .write(*moderator.at(i));
                        }
                    };
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
            ref self: ComponentState<TContractState>,
            channel_id: u256,
            moderator: Array<ContractAddress>
        ) {
            assert(
                self.channels.read(channel_id).channel_owner == get_caller_address(),
                NOT_CHANNEL_OWNER
            );
            for i in 0
                ..moderator
                    .len() {
                        if (self.is_channel_mod(*moderator.at(i), channel_id)) {
                            let mut channe_moderators = self.channel_moderators.entry(channel_id);
                            for j in 0
                                ..channe_moderators
                                    .len() {
                                        if (channe_moderators.at(j).read() == *moderator.at(i)) {
                                            // todo zero address set
                                            channe_moderators
                                                .at(j)
                                                .write(contract_address_const::<0>());
                                        }
                                    };
                        }
                    };

            // remove at the index thus making the best thing which i can made is the person who i
            // can make the best place to make the system which is todo
            // first know the element and then remove the function and delete the person

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
            // let channel_member: channelDetails = self.channels.read(channel_id);
            assert(
                self.channels.read(channel_id).channel_owner == get_caller_address(),
                NOT_CHANNEL_OWNER
            );
            let mut channel: channelDetails = self.channels.read(channel_id);
            channel.channel_censorship = censorship_status;
            self.channels.write(channel_id, channel);
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
            // let channel_member: channelDetails = self.channels.read(channel_id);
            assert(
                self.channels.read(channel_id).channel_owner == get_caller_address()
                    || self.is_channel_mod(get_caller_address(), channel_id),
                UNAUTHORIZED_ACESS
            );
            // check that channel exits and the profile is a member of the channel
            assert(
                self.channel_members.read((channel_id, profile)).profile == profile
                    && self.channel_members.read((channel_id, profile)).channel_id == channel_id,
                NOT_CHANNEL_MEMBER
            );

            let mut channel_member: channelMember = self
                .channel_members
                .read((channel_id, profile));
            channel_member.ban_status = ban_status;
            self.channel_members.write((channel_id, profile), channel_member);

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
        fn get_channel(self: @ComponentState<TContractState>, channel_id: u256) -> channelDetails {
            self.channels.read(channel_id)
        }

        ///@notice Get the metadata URI of the channel
        /// @param channel_id: The id of the channel
        /// @return The metadata URI
        fn get_channel_metadata_uri(
            self: @ComponentState<TContractState>, channel_id: u256
        ) -> ByteArray {
            let channel: channelDetails = self.channels.read(channel_id);
            channel.channel_metadata_uri
        }

        ///@notice Check if the profile is a member of the channel
        ///@param profile: The address of the profile
        ///@return A tuple of the membership status and the channel id
        fn is_channel_member(
            self: @ComponentState<TContractState>, profile: ContractAddress, channel_id: u256
        ) -> bool {
            let channel_member: channelMember = self.channel_members.read((channel_id, profile));
            if (channel_member.channel_id == channel_id) {
                true
            } else {
                false
            }
        }


        ///TODO :get the total number of mener of the channel
        fn get_total_members(self: @ComponentState<TContractState>, channel_id: u256) -> u256 {
            let channel: channelDetails = self.channels.read(channel_id);
            channel.channel_total_members
        }

        ///@notice check for moderator
        /// @param channel id
        /// @param profile addresss
        fn is_channel_mod(
            self: @ComponentState<TContractState>, profile: ContractAddress, channel_id: u256
        ) -> bool {
            let mut dd = self.channel_moderators.entry(channel_id);
            let mut flag: bool = false;
            for i in 0..dd.len() {
                if (dd.at(i).read() == profile) {
                    flag = true;
                    break;
                }
            };
            flag
        }

        fn get_channel_censorship_status(
            self: @ComponentState<TContractState>, channel_id: u256
        ) -> bool {
            let channel: channelDetails = self.channels.read(channel_id);
            channel.channel_censorship
        }

        fn get_ban_status(
            self: @ComponentState<TContractState>, profile: ContractAddress, channel_id: u256
        ) -> bool {
            let channel_member: channelMember = self.channel_members.read((channel_id, profile));
            channel_member.ban_status
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
        impl Community: CommunityComponent::HasComponent<TContractState>
    > of InternalTrait<TContractState> {
        /// @notice initalizes channel component
        /// @param channel_nft_classhash classhash of channel NFT
        fn _initializer(
            ref self: ComponentState<TContractState>, channel_nft_classhash: felt252
        ) {
            self.channel_counter.write(0);
            self.channel_nft_classhash.write(channel_nft_classhash.try_into().unwrap());
        }

        fn _join_channel(
            ref self: ComponentState<TContractState>,
            profile: ContractAddress,
            channel_id: u256
        ) {
            let mut channel: channelDetails = self.channels.read(channel_id);

            // check that user is a member of the community this channel belongs to
            let community_instance = get_dep_component!(@self, Community);
            let membership_status = community_instance.is_community_member(profile, channel.community_id);
            assert(membership_status, NOT_MEMBER);

            let channel_member = channelMember {
                profile: get_caller_address(),
                channel_id: channel_id,
                total_publications: 0,
                channel_token_id: 0,
                ban_status: false,
            };

            // mint a channel token to new joiner
            let minted_token_id = self
                ._mint_channel_nft(profile, channel.channel_nft_address);
            
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
                        token_id: minted_token_id,
                        block_timestamp: get_block_timestamp(),
                    }
                )
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
            community_nft_address: ContractAddress
        ) -> u256 {
            let token_id = ICommunityNftDispatcher { contract_address: community_nft_address }
                .mint_nft(profile);
            token_id
        }

        /// @notice internal function to burn a channel nft
        /// @param channel_nft_address address of channel nft
        /// @param token_id to burn
        fn _burn_community_nft(
            ref self: ComponentState<TContractState>,
            community_nft_address: ContractAddress,
            token_id: u256
        ) {
            ICommunityNftDispatcher { contract_address: community_nft_address }
                .burn_nft(get_caller_address(), token_id);
        }
    }
}