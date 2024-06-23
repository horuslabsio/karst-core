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
    use karst::base::types::Profile;
    use karst::base::errors::Errors::NOT_PROFILE_OWNER;
    use karst::base::{hubrestricted::HubRestricted::hub_only};

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        profile: LegacyMap<ContractAddress, Profile>,
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
        owner: ContractAddress,
        #[key]
        profile_address: ContractAddress,
        token_id: u256,
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
            salt: felt252,
            recipient: ContractAddress
        ) -> ContractAddress {
            let owns_karstnft = IERC721Dispatcher { contract_address: karstnft_contract_address }
                .balance_of(recipient);
            if owns_karstnft == 0 {
                IKarstNFTDispatcher { contract_address: karstnft_contract_address }
                    .mint_karstnft(recipient);
            }
            let token_id = IKarstNFTDispatcher { contract_address: karstnft_contract_address }
                .get_user_token_id(recipient);

            let profile_address = IRegistryLibraryDispatcher {
                class_hash: registry_hash.try_into().unwrap()
            }
                .create_account(implementation_hash, karstnft_contract_address, token_id, salt);
            let new_profile = Profile {
                profile_address, profile_owner: recipient, pub_count: 0, metadata_URI: "",
            };
            self.profile.write(profile_address, new_profile);
            self.emit(CreateProfile { owner: recipient, profile_address, token_id });
            profile_address
        }

        /// @notice set profile metadata_uri (`banner_image, description, profile_image` to be uploaded to arweave or ipfs)
        /// @params profile_address the targeted profile address
        /// @params metadata_uri the profile CID
        fn set_profile_metadata_uri(
            ref self: ContractState, profile_address: ContractAddress, metadata_uri: ByteArray
        ) {
            let mut profile = self.profile.read(profile_address);
            assert(get_caller_address() == profile.profile_owner, NOT_PROFILE_OWNER);
            profile.metadata_URI = metadata_uri;
            self.profile.write(profile_address, profile);
        }

        /// @notice increments user's publication count
        /// @params profile_address the targeted profile address
        fn increment_publication_count(
            ref self: ContractState, profile_address: ContractAddress
        ) -> u256 {
            // hub_only(self.karst_hub.read());
            let mut profile = self.profile.read(profile_address);
            let updated_profile = Profile {
                profile_address: profile.profile_address,
                profile_owner: profile.profile_owner,
                pub_count: profile.pub_count + 1,
                metadata_URI: profile.metadata_URI,
            };

            self.profile.write(profile_address, updated_profile);
            profile.pub_count
        }

        // *************************************************************************
        //                            GETTERS
        // *************************************************************************

        // @notice returns the Profile struct of a profile address
        // @params profile_address the targeted profile address
        fn get_profile(ref self: ContractState, profile_address: ContractAddress) -> Profile {
            self.profile.read(profile_address)
        }

        /// @notice returns user metadata
        /// @params user 
        fn get_profile_metadata(
            self: @ContractState, profile_address: ContractAddress
        ) -> ByteArray {
            self.profile.read(profile_address).metadata_URI
        }

        // @notice returns the publication count of a profile address
        // @params profile_address the targeted profile address
        fn get_user_publication_count(
            self: @ContractState, profile_address: ContractAddress
        ) -> u256 {
            self.profile.read(profile_address).pub_count
        }
    }
}
