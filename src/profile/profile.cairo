use starknet::ContractAddress;

#[starknet::contract]
mod KarstProfile {
    // *************************************************************************
    //                            IMPORT
    // *************************************************************************
    use core::traits::TryInto;
    use starknet::{ContractAddress, get_caller_address};
    use karst::interface::IkarstNFT::{IKarstNFTDispatcher, IKarstNFTDispatcherTrait};
    use karst::interface::Iregistry::{
        IRegistryDispatcher, IRegistryDispatcherTrait, IRegistryLibraryDispatcher
    };
    use karst::interface::IERC721::{IERC721Dispatcher, IERC721DispatcherTrait};
    use karst::errors::error::Errors::{NOT_PROFILE_OWNER};
    use karst::interface::Iprofile::IKarstProfile;

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        profile_id: LegacyMap<ContractAddress, ContractAddress>, // mapping of user => profile_address
        profile_metadata_uri: LegacyMap<ContractAddress, ByteArray>, //mapping of profile_id => metadata_uri
        profile_owner: LegacyMap<ContractAddress, ContractAddress> // mapping of profile_address => user
    }

    // *************************************************************************
    //                            EVENT
    // *************************************************************************
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        CreateKarstProfile: CreateKarstProfile
    }

    #[derive(Drop, starknet::Event)]
    struct CreateKarstProfile {
        #[key]
        user: ContractAddress,
        #[key]
        karstnft_contract_address: ContractAddress,
        #[key]
        token_id: u256,
        #[key]
        owner: ContractAddress
    }

    #[abi(embed_v0)]
    impl KarstProfileImpl of IKarstProfile<ContractState> {
        /// @notice creates karst
        /// @param karstnft_contract_address address of karstnft
        /// @param registry_hash class_hash of registry contract
        /// @param implementation_hash the class hash of the reference account
        /// @param salt random salt for deployment
        fn create_karstprofile(
            ref self: ContractState,
            karstnft_contract_address: ContractAddress,
            registry_hash: felt252,
            implementation_hash: felt252,
            salt: felt252
        ) {
            let caller = get_caller_address();
            // check if user has a karst nft
            let own_karstnft = IERC721Dispatcher { contract_address: karstnft_contract_address }
                .balance_of(caller);
            let token_id = IKarstNFTDispatcher { contract_address: karstnft_contract_address }
                .get_user_token_id(caller);
            if own_karstnft == 0 {
                IKarstNFTDispatcher { contract_address: karstnft_contract_address }.mint_karstnft();
             let profile_address =   IRegistryLibraryDispatcher { class_hash: registry_hash.try_into().unwrap() }
                    .create_account(implementation_hash, karstnft_contract_address, token_id, salt);
                // assign profile id 
                self.profile_id.write(caller, profile_address);
                let profile_id = self.profile_id.read(caller);
                self.profile_owner.write(profile_id, caller);
            } else {
             let profile_address =   IRegistryLibraryDispatcher { class_hash: registry_hash.try_into().unwrap() }
                    .create_account(implementation_hash, karstnft_contract_address, token_id, salt);
                // execute create_account on token bound registry via dispatcher
                self.profile_id.write(caller, profile_address);
                let profile_id = self.profile_id.read(caller);
                self.profile_owner.write(profile_id, caller);
            }
            // emit event
            self
                .emit(
                    CreateKarstProfile {
                        user: caller, karstnft_contract_address, token_id, owner: caller,
                    }
                )
        }

        /// @notice returns user profile_id
        /// @params user ContractAddress of user 
        fn get_user_profile_address(self: @ContractState, user: ContractAddress) -> ContractAddress {
            self.profile_id.read(user)
        }
        // /// @notice returns total_profile_id created
        // fn get_total_id(self: @ContractState) -> u256 {
        //     self.total_profile_id.read()
        // }
        /// @notice returns user metadata
        /// @params profile_id profile_id of user
        fn get_profile(self: @ContractState, profile_id: ContractAddress) -> ByteArray {
            self.profile_metadata_uri.read(profile_id)
        }
        /// @notice set profile metadata_uri (`banner_image, discription, profile_image` to be uploaded to arweave or ipfs)
        /// @params metadata_uri the profile CID
        fn set_profile_metadata_uri(ref self: ContractState, metadata_uri: ByteArray) {
            let caller = get_caller_address();
            let profile_id = self.profile_id.read(caller);
            let profile_owner = self.profile_owner.read(profile_id);
            // assert that caller is the owner of the profile to be updated.
            assert(caller == profile_owner, NOT_PROFILE_OWNER);
            self.profile_metadata_uri.write(profile_id, metadata_uri);
        }
        /// @notice returns owner of a profile
        /// @params profile_id the profile_id_address to query for.
        fn get_profile_owner_by_id(self: @ContractState, profile_id: ContractAddress) -> ContractAddress {
            self.profile_owner.read(profile_id)
        }
    }
}
