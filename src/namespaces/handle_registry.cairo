#[starknet::contract]
mod HandleRegistry {
    // *************************************************************************
    //                            IMPORT
    // *************************************************************************
    use core::traits::TryInto;
    use starknet::{ContractAddress, get_caller_address};
    use karst::interfaces::IHandleRegistry::IHandleRegistry;

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
            // TODO
            0.try_into().unwrap()
        }

        fn get_handle(self: @ContractState, profile_address: ContractAddress) -> u256 {
            let handle = self.profile_address_to_handle.read(profile_address);
            if(handle == 0) {
                return 0;
            } 
           handle
        }
    }

    // *************************************************************************
    //                            PRIVATE FUNCTIONS
    // ************************************************************************* 
    #[generate_trait]
    impl Private of PrivateTrait {
        fn _link(
            ref self: ContractState, handle_id: u256, profile_address: ContractAddress
        ) { // TODO
        }

        fn _unlink(
            ref self: ContractState,
            handle_id: u256,
            profile_address: ContractAddress,
            caller: ContractAddress
        ) { // TODO
        }
    }
}
