#[starknet::contract]
mod HandleRegistry {
    // *************************************************************************
    //                            IMPORT
    // *************************************************************************
    use core::traits::TryInto;
    use starknet::{ContractAddress, get_caller_address, emit_event};
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
            self.handle_to_profile_address.write(handle_id, profile_address);
            self.profile_address_to_handle.write(profile_address, handle_id);
            let caller = get_caller_address();
            let timestamp = starknet::get_block_timestamp();
            emit_event(
                Event::Linked(HandleLinked { handle_id, profile_address, caller, timestamp, })
            );
        }

        fn _unlink(
            ref self: ContractState,
            handle_id: u256,
            profile_address: ContractAddress,
            caller: ContractAddress
        ) {
            self.handle_to_profile_address.remove(handle_id);
            self.profile_address_to_handle.remove(profile_address);
            let timestamp = starknet::get_block_timestamp();
            emit_event(
                Event::Unlinked(HandleUnlinked { handle_id, profile_address, caller, timestamp, })
            );
        }
    }
}
