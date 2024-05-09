use starknet::ContractAddress;



#[starknet::contract]
mod KarstProfile {
    use starknet::{ContractAddress, get_caller_address};
    use karst::interface::Ikarst::{IKarstDispatcher, IKarstDispatcherTrait};
    use karst::interface::Iregistry::{IRegistryDispatcher, IRegistryDispatcherTrait};
    use karst::interface::IERC721::{IERC721Dispatcher, IERC721DispatcherTrait};
    use karst::errors::error::Errors::{NOT_PROFILE_OWNER};
    use karst::interface::Iprofile::IKarstProfile;

    #[storage]
    struct Storage {
        profile_id: LegacyMap<ContractAddress, u256>,
        total_profile_id: u256,
        profile_metadata_uri: LegacyMap<u256, ByteArray>,
        profile_owner: LegacyMap<u256, ContractAddress>
    }

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
        registry_contract_address: ContractAddress,
        #[key]
        token_id: u256,
        #[key]
        owner: ContractAddress
    }

    #[abi(embed_v0)]
    impl KarstProfileImpl of IKarstProfile<ContractState> {
        fn create_karstnft(
            ref self: ContractState,
            karstnft_contract_address: ContractAddress,
            registry_contract_address: ContractAddress,
            implementation_hash: felt252,
            salt: felt252
        ) {
            let caller = get_caller_address();
            // check if user has a karst nft
            let own_karstnft = IERC721Dispatcher { contract_address: karstnft_contract_address }
                .balance_of(caller);
            let token_id = IKarstDispatcher { contract_address: karstnft_contract_address }
                .token_id();
            let current_total_id = self.total_profile_id.read();
            if own_karstnft == 0 {
                IKarstDispatcher { contract_address: karstnft_contract_address }.mint_karstnft();
                IRegistryDispatcher { contract_address: registry_contract_address }
                    .create_account(implementation_hash, karstnft_contract_address, token_id, salt);
                // assign profile id 
                self.profile_id.write(caller, current_total_id + 1);
                self.total_profile_id.write(current_total_id + 1);
                let profile_id = self.profile_id.read(caller);
                self.profile_owner.write(profile_id, caller);
            } else {
                IRegistryDispatcher { contract_address: registry_contract_address }
                    .create_account(implementation_hash, karstnft_contract_address, token_id, salt);
                // execute create_account on token bound registry via dispatcher
                self.profile_id.write(caller, current_total_id + 1);
                self.total_profile_id.write(current_total_id + 1);
                let profile_id = self.profile_id.read(caller);
                self.profile_owner.write(profile_id, caller);
            }
            // emit event
            self
                .emit(
                    CreateKarstProfile {
                        user: caller,
                        karstnft_contract_address,
                        registry_contract_address,
                        token_id,
                        owner: caller
                    }
                )
        }

        fn get_user_profile_id(self: @ContractState, user: ContractAddress) -> u256 {
            self.profile_id.read(user)
        }

        fn get_total_id(self: @ContractState) -> u256 {
            self.total_profile_id.read()
        }

        fn get_profile(self: @ContractState, profile_id: u256) -> ByteArray {
            self.profile_metadata_uri.read(profile_id)
        }

        fn set_profile_metadata_uri(ref self: ContractState, metadata_uri: ByteArray) {
            let caller = get_caller_address();
            let profile_id = self.profile_id.read(caller);
            let profile_owner = self.profile_owner.read(profile_id);
            // assert that caller is the owner of the profile to be updated.
            assert(caller == profile_owner, NOT_PROFILE_OWNER);
            self.profile_metadata_uri.write(profile_id, metadata_uri);
        }

        fn get_profile_owner_by_id(self: @ContractState, profile_id: u256) -> ContractAddress {
            self.profile_owner.read(profile_id)
        }
        
    }
}
