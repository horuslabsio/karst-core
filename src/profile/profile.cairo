use starknet::ContractAddress;

#[starknet::contract]
mod KarstProfile {
    // *************************************************************************
    //                            IMPORT
    // *************************************************************************
    use core::traits::TryInto;
    use starknet::{ContractAddress, get_caller_address};
    use karst::interfaces::IKarstNFT::{IKarstNFTDispatcher, IKarstNFTDispatcherTrait};
    use karst::interfaces::IRegistry::{
        IRegistryDispatcher, IRegistryDispatcherTrait, IRegistryLibraryDispatcher
    };
    use karst::interfaces::IERC721::{IERC721Dispatcher, IERC721DispatcherTrait};
    use karst::interfaces::IProfile::IKarstProfile;
    use karst::base::errors::Errors::{NOT_PROFILE_OWNER};
    use karst::base::types::Profile;
    use karst::base::{hubrestricted::HubRestricted::hub_only};

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        profile: LegacyMap<ContractAddress, Profile>, //maps user => Profile
        karst_hub: ContractAddress,
    }

    // *************************************************************************
    //                            EVENT
    // *************************************************************************
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        CreateProfile: CreateProfile
    }

    #[derive(Drop, starknet::Event)]
    struct CreateProfile {
        #[key]
        user: ContractAddress, // address of user creating a profile
        #[key]
        profile_address: ContractAddress, // address of created profile
        token_id: u256, // profile nft token ID
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
    impl KarstProfileImpl of IKarstProfile<ContractState> {
        /// @notice creates karst profile
        /// @param karstnft_contract_address address of karstnft
        /// @param registry_hash class_hash of registry contract
        /// @param implementation_hash the class hash of the reference account
        /// @param salt random salt for deployment
        fn create_profile(
            ref self: ContractState,
            karstnft_contract_address: ContractAddress,
            registry_hash: felt252,
            implementation_hash: felt252,
            salt: felt252
        ) -> ContractAddress {
            hub_only(self.karst_hub.read());
            let caller = get_caller_address();
            let owns_karstnft = IERC721Dispatcher { contract_address: karstnft_contract_address }
                .balance_of(caller);
            if owns_karstnft == 0 {
                IKarstNFTDispatcher { contract_address: karstnft_contract_address }
                    .mint_karstnft(caller);
            }
            let token_id = IKarstNFTDispatcher { contract_address: karstnft_contract_address }
                .get_user_token_id(caller);

            let profile_address = IRegistryLibraryDispatcher {
                class_hash: registry_hash.try_into().unwrap()
            }
                .create_account(implementation_hash, karstnft_contract_address, token_id, salt);
            let new_profile = Profile {
                pub_count: 0,
                metadata_URI: "",
                profile_address: profile_address,
                profile_owner: caller
            };
            self.profile.write(caller, new_profile);
            self.emit(CreateProfile { user: caller, token_id, profile_address });
            profile_address
        }
        /// @notice set profile metadata_uri (`banner_image, description, profile_image` to be uploaded to arweave or ipfs)
        /// @params metadata_uri the profile CID
        fn set_profile_metadata_uri(ref self: ContractState, metadata_uri: ByteArray) {
            let caller = get_caller_address();
            let mut profile = self.profile.read(caller);
            // assert that caller is the owner of the profile to be updated.
            assert(caller == profile.profile_owner, NOT_PROFILE_OWNER);
            profile.metadata_URI = metadata_uri;
            self.profile.write(caller, profile);
        }

        fn increment_publication_count(ref self: ContractState) -> u256 {
            hub_only(self.karst_hub.read());
            let caller = get_caller_address();
            let mut profile = self.profile.read(caller);
            let updated_profile = Profile {
                pub_count: profile.pub_count + 1,
                metadata_URI: profile.metadata_URI,
                profile_address: profile.profile_address,
                profile_owner: caller
            };
            self.profile.write(caller, updated_profile);
            profile.pub_count
        }

        // *************************************************************************
        //                            GETTERS
        // *************************************************************************
        /// @notice returns user profile_address
        /// @params user ContractAddress of user 
        fn get_user_profile_address(
            self: @ContractState, user: ContractAddress
        ) -> ContractAddress {
            self.profile.read(user).profile_address
        }
        /// @notice returns user metadata
        /// @params user 
        fn get_profile_metadata(self: @ContractState, user: ContractAddress) -> ByteArray {
            self.profile.read(user).metadata_URI
        }
        /// @notice returns owner of a profile
        /// @params user the user address to query for.
        fn get_profile_owner(self: @ContractState, user: ContractAddress) -> ContractAddress {
            self.profile.read(user).profile_owner
        }

        /// @notice returns a profile
        /// @params profile_address the profile_id_address to query for.
        fn get_profile_details(
            self: @ContractState, user: ContractAddress
        ) -> (u256, ByteArray, ContractAddress, ContractAddress) {
            let profile = self.profile.read(user);
            (
                profile.pub_count,
                profile.metadata_URI,
                profile.profile_address,
                profile.profile_owner
            )
        }

        fn get_profile(ref self: ContractState, user: ContractAddress) -> Profile {
            self.profile.read(user)
        }

        fn get_user_publication_count(self: @ContractState, user: ContractAddress) -> u256 {
            self.profile.read(user).pub_count
        }
    }
}
