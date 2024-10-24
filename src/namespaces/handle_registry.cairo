#[starknet::contract]
pub mod HandleRegistry {
    // *************************************************************************
    //                            IMPORT
    // *************************************************************************
    use core::num::traits::zero::Zero;
    use starknet::{
        ContractAddress, get_caller_address, get_block_timestamp, contract_address_const,
        storage::{
            StoragePointerWriteAccess, StoragePointerReadAccess, Map, StorageMapReadAccess,
            StorageMapWriteAccess
        }
    };
    use coloniz::interfaces::IHandleRegistry::IHandleRegistry;
    use coloniz::interfaces::IERC721::{IERC721Dispatcher, IERC721DispatcherTrait};
    use coloniz::base::{constants::errors::Errors};
    use coloniz::interfaces::IHandle::{IHandleDispatcher, IHandleDispatcherTrait};

    // *************************************************************************
    //                            STORAGE
    // *************************************************************************
    #[storage]
    pub struct Storage {
        handle_address: ContractAddress,
        handle_to_profile_address: Map::<u256, ContractAddress>,
        profile_address_to_handle: Map::<ContractAddress, u256>,
    }

    // *************************************************************************
    //                            EVENTS
    // *************************************************************************
    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        Linked: HandleLinked,
        Unlinked: HandleUnlinked,
    }

    #[derive(Drop, starknet::Event)]
    pub struct HandleLinked {
        pub handle_id: u256,
        pub profile_address: ContractAddress,
        pub caller: ContractAddress,
        pub timestamp: u64
    }

    #[derive(Drop, starknet::Event)]
    pub struct HandleUnlinked {
        pub handle_id: u256,
        pub profile_address: ContractAddress,
        pub caller: ContractAddress,
        pub timestamp: u64
    }

    // *************************************************************************
    //                            CONSTRUCTOR
    // *************************************************************************
    #[constructor]
    fn constructor(ref self: ContractState, handle_address: ContractAddress) {
        self.handle_address.write(handle_address);
    }

    // *************************************************************************
    //                            EXTERNALS
    // *************************************************************************
    #[abi(embed_v0)]
    impl HandleRegistryImpl of IHandleRegistry<ContractState> {
        /// @notice links a profile address to a handle
        /// @param handle_id ID of handle to be linked
        /// @param profile_address address of profile to be linked
        /// TODO: gate link function? only caller?
        fn link(ref self: ContractState, handle_id: u256, profile_address: ContractAddress) {
            self._link(handle_id, profile_address);
        }

        /// @notice unlinks a profile address from a handle
        /// @param handle_id ID of handle to be unlinked
        /// @param profile_address address of profile to be unlinked
        fn unlink(ref self: ContractState, handle_id: u256, profile_address: ContractAddress) {
            let caller = get_caller_address();
            self._unlink(handle_id, profile_address, caller);
        }

        // *************************************************************************
        //                            GETTERS
        // *************************************************************************

        /// @notice resolves a handle to a profile address
        /// @param handle_id ID of handle to be resolved
        fn resolve(self: @ContractState, handle_id: u256) -> ContractAddress {
            let it_exists = IHandleDispatcher { contract_address: self.handle_address.read() }
                .exists(handle_id);
            assert(it_exists, Errors::HANDLE_DOES_NOT_EXIST);
            self.handle_to_profile_address.read(handle_id)
        }

        /// @notice returns the handle linked to a profile address
        /// @param profile_address address of profile to be queried
        fn get_handle(self: @ContractState, profile_address: ContractAddress) -> u256 {
            self.profile_address_to_handle.read(profile_address)
        }
    }

    // *************************************************************************
    //                            PRIVATE FUNCTIONS
    // *************************************************************************
    #[generate_trait]
    impl Private of PrivateTrait {
        /// @notice internal function to link a profile address to a handle
        /// @param handle_id ID of handle to be linked
        /// @param profile_address address of profile to be linked
        fn _link(ref self: ContractState, handle_id: u256, profile_address: ContractAddress) {
            let owner = IERC721Dispatcher { contract_address: self.handle_address.read() }
                .owner_of(handle_id);
            let handle_to_profile = self.handle_to_profile_address.read(handle_id);

            assert(profile_address == owner, Errors::INVALID_PROFILE);
            assert(handle_to_profile.is_zero(), Errors::HANDLE_ALREADY_LINKED);

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

        /// @notice internal function to unlink a profile address from a handle
        /// @param handle_id ID of handle to be unlinked
        /// @param profile_address address of profile to be unlinked
        /// @param caller address of user calling this function
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
    }
}
