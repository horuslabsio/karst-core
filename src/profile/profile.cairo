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
        profile: LegacyMap<ContractAddress, Profile>, //maps profile_address => Profile
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
            salt: felt252,
            recipient:ContractAddress
        ) -> ContractAddress {
            hub_only(self.karst_hub.read());
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
                pub_count: 0,
                metadata_URI: "",
            };
            self.profile.write(profile_address, new_profile);
            self.emit(CreateProfile { user: profile_address, token_id, profile_address });
            profile_address
        }
        /// @notice set profile metadata_uri (`banner_image, description, profile_image` to be uploaded to arweave or ipfs)
        /// @params metadata_uri the profile CID
        fn set_profile_metadata_uri(ref self: ContractState, profile_address:ContractAddress, metadata_uri: ByteArray) {
            hub_only(self.karst_hub.read());
            let mut profile = self.profile.read(profile_address);
            profile.metadata_URI = metadata_uri;
            self.profile.write(profile_address, profile);
        }

        fn increment_publication_count(ref self: ContractState, profile_address:ContractAddress) -> u256 {
            hub_only(self.karst_hub.read());
            let mut profile = self.profile.read(profile_address);
            let updated_profile = Profile {
                pub_count: profile.pub_count + 1,
                metadata_URI: profile.metadata_URI,
            };
            self.profile.write(profile_address, updated_profile);
            profile.pub_count
        }

        // *************************************************************************
        //                            GETTERS
        // *************************************************************************

        /// @notice returns user metadata
        /// @params user 
        fn get_profile_metadata(self: @ContractState, profile_address: ContractAddress) -> ByteArray {
            self.profile.read(profile_address).metadata_URI
        }


        fn get_profile(ref self: ContractState, profile_address: ContractAddress) -> Profile {
            self.profile.read(profile_address)
        }

        fn get_user_publication_count(self: @ContractState, profile_address: ContractAddress) -> u256 {
            self.profile.read(profile_address).pub_count
        }
    }
}
