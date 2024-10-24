#[starknet::component]
pub mod ProfileComponent {
    // *************************************************************************
    //                            IMPORT
    // *************************************************************************
    use core::{traits::TryInto};
    use starknet::{
        get_tx_info, ContractAddress, get_caller_address, get_block_timestamp, ClassHash,
        syscalls::deploy_syscall, SyscallResultTrait,
        storage::{
            StoragePointerWriteAccess, StoragePointerReadAccess, Map, StorageMapReadAccess,
            StorageMapWriteAccess
        }
    };
    use coloniz::interfaces::IColonizNFT::{IColonizNFTDispatcher, IColonizNFTDispatcherTrait};
    use coloniz::interfaces::IRegistry::{IRegistryDispatcherTrait, IRegistryLibraryDispatcher};
    use coloniz::interfaces::IERC721::{IERC721Dispatcher, IERC721DispatcherTrait};
    use coloniz::interfaces::IProfile::IProfile;
    use coloniz::base::{constants::types::Profile, constants::errors::Errors::NOT_PROFILE_OWNER};

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    pub struct Storage {
        profile: Map<ContractAddress, Profile>,
        coloniz_nft_address: ContractAddress,
        hub_address: ContractAddress,
        follow_nft_classhash: ClassHash
    }

    // *************************************************************************
    //                            EVENT
    // *************************************************************************
    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        CreatedProfile: CreatedProfile
    }

    #[derive(Drop, starknet::Event)]
    pub struct CreatedProfile {
        #[key]
        pub owner: ContractAddress,
        #[key]
        pub profile_address: ContractAddress,
        pub token_id: u256,
        pub timestamp: u64
    }

    // *************************************************************************
    //                            EXTERNAL FUNCTIONS
    // *************************************************************************
    #[embeddable_as(colonizProfile)]
    impl ProfileImpl<
        TContractState, +HasComponent<TContractState>
    > of IProfile<ComponentState<TContractState>> {
        /// @notice creates coloniz profile
        /// @param coloniznft_contract_address address of coloniznft
        /// @param registry_hash class_hash of registry contract
        /// @param implementation_hash the class hash of the reference account
        /// @param salt random salt for deployment
        fn create_profile(
            ref self: ComponentState<TContractState>,
            coloniznft_contract_address: ContractAddress,
            registry_hash: felt252,
            implementation_hash: felt252,
            salt: felt252
        ) -> ContractAddress {
            // mint coloniz nft
            let recipient = get_caller_address();
            let owns_coloniznft = IERC721Dispatcher {
                contract_address: coloniznft_contract_address
            }
                .balance_of(recipient);
            if owns_coloniznft == 0 {
                IColonizNFTDispatcher { contract_address: coloniznft_contract_address }
                    .mint_coloniznft(recipient);
            }
            let token_id = IColonizNFTDispatcher { contract_address: coloniznft_contract_address }
                .get_user_token_id(recipient);
            let tx_info = get_tx_info().unbox();
            let chain_id = tx_info.chain_id;
            // create tokenbound account
            let profile_address = IRegistryLibraryDispatcher {
                class_hash: registry_hash.try_into().unwrap()
            }
                .create_account(
                    implementation_hash, coloniznft_contract_address, token_id, salt, chain_id
                );

            // deploy follow nft contract
            let mut constructor_calldata: Array<felt252> = array![
                self.hub_address.read().into(), profile_address.into(), recipient.into()
            ];
            let (follow_nft_address, _) = deploy_syscall(
                self.follow_nft_classhash.read(),
                profile_address.into(),
                constructor_calldata.span(),
                true
            )
                .unwrap_syscall();

            // create new Profile obj
            let new_profile = Profile {
                profile_address,
                profile_owner: recipient,
                pub_count: 0,
                metadata_URI: "",
                follow_nft: follow_nft_address,
            };

            // update profile, emit events
            self.profile.write(profile_address, new_profile);
            self
                .emit(
                    CreatedProfile {
                        owner: recipient,
                        profile_address,
                        token_id,
                        timestamp: get_block_timestamp()
                    }
                );
            profile_address
        }

        /// @notice set profile metadata_uri (`banner_image, description, profile_image` to be
        /// uploaded to arweave or ipfs)
        /// @params profile_address the targeted profile address
        /// @params metadata_uri the profile CID
        fn set_profile_metadata_uri(
            ref self: ComponentState<TContractState>,
            profile_address: ContractAddress,
            metadata_uri: ByteArray
        ) {
            let mut profile: Profile = self.profile.read(profile_address);
            assert(get_caller_address() == profile.profile_owner, NOT_PROFILE_OWNER);

            profile.metadata_URI = metadata_uri;
            self.profile.write(profile_address, profile);
        }

        // *************************************************************************
        //                            GETTERS
        // *************************************************************************

        // @notice returns the Profile struct of a profile address
        // @params profile_address the targeted profile address
        fn get_profile(
            self: @ComponentState<TContractState>, profile_address: ContractAddress
        ) -> Profile {
            self.profile.read(profile_address)
        }

        /// @notice returns user profile metadata
        /// @params profile_address the targeted profile address
        fn get_profile_metadata(
            self: @ComponentState<TContractState>, profile_address: ContractAddress
        ) -> ByteArray {
            let profile: Profile = self.profile.read(profile_address);
            profile.metadata_URI
        }

        // @notice returns the publication count of a profile address
        // @params profile_address the targeted profile address
        fn get_user_publication_count(
            self: @ComponentState<TContractState>, profile_address: ContractAddress
        ) -> u256 {
            let profile: Profile = self.profile.read(profile_address);
            profile.pub_count
        }
    }

    #[generate_trait]
    pub impl Private<
        TContractState, +HasComponent<TContractState>
    > of PrivateTrait<TContractState> {
        /// @notice initialize profile component
        fn _initializer(
            ref self: ComponentState<TContractState>,
            coloniz_nft_address: ContractAddress,
            hub_address: ContractAddress,
            follow_nft_classhash: felt252
        ) {
            self.coloniz_nft_address.write(coloniz_nft_address);
            self.hub_address.write(hub_address);
            self.follow_nft_classhash.write(follow_nft_classhash.try_into().unwrap());
        }

        /// @notice increments user's publication count
        /// @params profile_address the targeted profile address
        fn increment_publication_count(
            ref self: ComponentState<TContractState>, profile_address: ContractAddress
        ) -> u256 {
            let mut profile: Profile = self.profile.read(profile_address);
            let new_pub_count = profile.pub_count + 1;
            let updated_profile = Profile { pub_count: new_pub_count, ..profile };

            self.profile.write(profile_address, updated_profile);
            new_pub_count
        }
    }
}
