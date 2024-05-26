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

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        profile: LegacyMap<ContractAddress, Profile> //maps user => Profile
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
        ) {
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
                pubCount: 0,
                metadataURI: "",
                profile_address: profile_address,
                profile_owner: caller
            };
            self.profile.write(caller, new_profile);
            self.emit(CreateProfile { user: caller, token_id, profile_address })
        }
        /// @notice set profile metadata_uri (`banner_image, description, profile_image` to be uploaded to arweave or ipfs)
        /// @params metadata_uri the profile CID
        fn set_profile_metadata_uri(ref self: ContractState, metadata_uri: ByteArray) {
            let caller = get_caller_address();
            let mut profile = self.profile.read(caller);
            // assert that caller is the owner of the profile to be updated.
            assert(caller == profile.profile_owner, NOT_PROFILE_OWNER);
            profile.metadataURI = metadata_uri;
            self.profile.write(caller, profile);
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
            self.profile.read(user).metadataURI
        }
        /// @notice returns owner of a profile
        /// @params user the user address to query for.
        fn get_profile_owner(self: @ContractState, user: ContractAddress) -> ContractAddress {
            self.profile.read(user).profile_owner
        }

        /// @notice returns a profile
        /// @params profile_address the profile_id_address to query for.
        fn get_profile_details(
            self: @ContractState, profile_address: ContractAddress
        ) -> (u256, ByteArray, ContractAddress, ContractAddress) {
            let profile = self.profile.read(profile_address);
            (profile.pubCount, profile.metadataURI, profile.profile_address, profile.profile_owner)
        }

        fn get_profile(self: @ContractState, profile_address: ContractAddress) -> Profile {
            self.profile.read(profile_address)
        }
    }
}
