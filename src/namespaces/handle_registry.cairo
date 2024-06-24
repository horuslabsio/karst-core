#[starknet::contract]
mod HandleRegistry {
    // *************************************************************************
    //                            IMPORT
    // *************************************************************************
    use core::traits::TryInto;
    use core::num::traits::zero::Zero;
    use starknet::{
        ContractAddress, get_caller_address, get_block_timestamp, contract_address_const
    };
    use karst::interfaces::IHandleRegistry::IHandleRegistry;
    use karst::interfaces::IERC721::{IERC721Dispatcher, IERC721DispatcherTrait};
    use karst::base::{hubrestricted::HubRestricted::hub_only};
    use karst::interfaces::IHandle::{IHandleDispatcher, IHandleDispatcherTrait};
    use karst::base::types::RegistryTypes;
    use karst::base::errors::Errors;

    // *************************************************************************
    //                            STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        karst_hub: ContractAddress,
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
        self.karst_hub.write(hub_address);
        self.handle_address.write(handle_address);
    }

    // *************************************************************************
    //                            EXTERNALS
    // *************************************************************************
    #[abi(embed_v0)]
    impl HandleRegistryImpl of IHandleRegistry<ContractState> {
        fn link(ref self: ContractState, handle_id: u256, profile_address: ContractAddress) {
            hub_only(self.karst_hub.read());
            self._link(handle_id, profile_address);
        }

        fn unlink(ref self: ContractState, handle_id: u256, profile_address: ContractAddress) {
            let caller = get_caller_address();
            self._unlink(handle_id, profile_address, caller);
        }

        // *************************************************************************
        //                            GETTERS
        // *************************************************************************
        fn resolve(ref self: ContractState, handle_id: u256) -> ContractAddress {
            let isExist = IHandleDispatcher { contract_address: self.handle_address.read() }
                .exists(handle_id);
            assert(isExist, 'Handle ID does not exist');
            let resolved_handle_profile_address: ContractAddress = self
                ._resolve_handle_to_profile_address(
                    RegistryTypes::Handle { id: handle_id, collection: self.handle_address.read() }
                );
            resolved_handle_profile_address
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
            let owner = IERC721Dispatcher { contract_address: self.handle_address.read() }
                .owner_of(handle_id);
            let handle_to_profile = self.handle_to_profile_address.read(handle_id);

            assert(profile_address == owner, Errors::INVALID_PROFILE);
            assert(handle_to_profile.is_zero(), Errors::OWNER_NOT_ZERO);

            self.handle_to_profile_address.write(handle_id, profile_address);
            self.profile_address_to_handle.write(profile_address, handle_id);

            self
                .emit(
                    HandleLinked {
                        handle_id,
                        profile_address,
                        caller: get_caller_address(),
                        timestamp: get_block_timestamp()
                    }
                )
        }

        fn _unlink(
            ref self: ContractState,
            handle_id: u256,
            profile_address: ContractAddress,
            caller: ContractAddress
        ) {
            let owner = IERC721Dispatcher { contract_address: self.handle_address.read() }
                .owner_of(handle_id);
            assert(caller == owner, Errors::INVALID_OWNER);

            self.handle_to_profile_address.write(handle_id, contract_address_const::<0>());
            self.profile_address_to_handle.write(profile_address, 0);

            self
                .emit(
                    HandleUnlinked {
                        handle_id,
                        profile_address,
                        caller: get_caller_address(),
                        timestamp: get_block_timestamp()
                    }
                )
        }

        fn _resolve_handle_to_profile_address(
            ref self: ContractState, handle: RegistryTypes::Handle
        ) -> ContractAddress {
            self.handle_to_profile_address.read(handle.id)
        }
    }
}
