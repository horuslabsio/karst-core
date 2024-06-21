#[starknet::contract]
mod HandleRegistry {
    // *************************************************************************
    //                            IMPORT
    // *************************************************************************
    use core::traits::TryInto;
    use starknet::{ContractAddress, get_caller_address};
    use karst::interfaces::IHandleRegistry::IHandleRegistry;
    use karst::interfaces::IHandleNFT::IHandleNFTDispatcher; // Import the IHandleNFT interface
    use karst::base::errors::Errors;

    // *************************************************************************
    //                            STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        hub_address: ContractAddress,
        handle_address: ContractAddress,
        handle_to_profile_address: LegacyMap::<u256, ContractAddress>,
        profile_address_to_handle: LegacyMap::<ContractAddress, u256>,
    }

    // *************************************************************************
    //                            EVENTS
    // *************************************************************************
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Linked: HandleLinked,
        Unlinked: HandleUnlinked,
    }

    #[derive(Drop, starknet::Event)]
    struct HandleLinked {
        handle_id: u256,
        profile_address: ContractAddress,
        caller: ContractAddress,
        timestamp: u64
    }

    #[derive(Drop, starknet::Event)]
    struct HandleUnlinked {
        handle_id: u256,
        profile_address: ContractAddress,
        caller: ContractAddress,
        timestamp: u64
    }

    // *************************************************************************
    //                            CONSTRUCTOR
    // *************************************************************************
    #[constructor]
    fn constructor(
        ref self: ContractState, hub_address: ContractAddress, handle_address: ContractAddress
    ) {
        self.hub_address.write(hub_address);
        self.handle_address.write(handle_address);
    }

    // *************************************************************************
    //                            EXTERNALS
    // *************************************************************************
    #[abi(embed_v0)]
    impl HandleRegistryImpl of IHandleRegistry<ContractState> {
        fn link(ref self: ContractState, handle_id: u256, profile_address: ContractAddress) {
            self._link(handle_id, profile_address);
        }

        fn unlink(ref self: ContractState, handle_id: u256, profile_address: ContractAddress) {
            let caller = get_caller_address();
            self._unlink(handle_id, profile_address, caller);
        }

        // *************************************************************************
        //                            GETTERS
        // *************************************************************************
        fn resolve(self: @ContractState, handle_id: u256) -> ContractAddress {
            self.handle_to_profile_address.read(handle_id)
        }

        fn get_handle(self: @ContractState, profile_address: ContractAddress) -> u256 {
            self.profile_address_to_handle.read(profile_address)
        }
    }

    // *************************************************************************
    //                            PRIVATE FUNCTIONS
    // ************************************************************************* 
    #[generate_trait]
    impl Private of PrivateTrait {
        fn _link(ref self: ContractState, handle_id: u256, profile_address: ContractAddress) {
            // Dispatcher to call ownerOf on the handle NFT contract
            let owner = IHandleNFTDispatcher {
                contract_address: self.handle_address.read(),
            }.owner_of(handle_id);

            // Check if the owner of the NFT is the profile_address
            assert(owner == profile_address, Errors::PROFILE_DOESNT_OWN_NFT);

            self.handle_to_profile_address.write(handle_id, profile_address);
            self.profile_address_to_handle.write(profile_address, handle_id);
            let caller = get_caller_address();
            let timestamp = starknet::get_block_timestamp();
            // Emit the Linked event using self.emit
            self.emit(Event::Linked(HandleLinked { handle_id, profile_address, caller, timestamp }));
        }

        fn _unlink(ref self: ContractState,handle_id: u256,profile_address: ContractAddress,caller: ContractAddress) {
            // Check that handle_id and profile_address are not zero
            assert(handle_id != 0,Errors::HANDLEID_NOT_ZERO );
            assert(profile_address != ContractAddress::zero(), Errors::PROFILEADDRESS_NOT_ZERO);
        
            // Dispatcher to call ownerOf on the handle NFT contract
            let owner = IHandleNFTDispatcher {
                contract_address: self.handle_address.read(),
            }.owner_of(handle_id);
        
            // Check that the profile_address owns the NFT and is equal to the caller
            assert(owner == profile_address,  Errors::PROFILE_DOESNT_OWN_NFT);
            assert(profile_address == caller, Errors::CALLER_NOT_OWNER_OF_NFT);
        
            self.handle_to_profile_address.write(handle_id, ContractAddress::zero());
            self.profile_address_to_handle.write(profile_address, 0);
            let timestamp = starknet::get_block_timestamp();
            self.emit(Event::Unlinked(HandleUnlinked { handle_id, profile_address, caller, timestamp }));
        }
    }
}
