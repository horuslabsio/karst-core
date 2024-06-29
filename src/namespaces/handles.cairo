// *************************************************************************
//                            OZ ERC721
// *************************************************************************
use openzeppelin::{
    token::erc721::{ERC721Component::{ERC721Metadata, ERC721Mixin, HasComponent}},
    introspection::src5::SRC5Component,
};
use alexandria_bytes::{Bytes, BytesTrait};
// use alexandria_encoding::{ BytesTrait};
// use starknet::ByteArray;

#[starknet::interface]
trait IERC721Metadata<TState> {
    fn name(self: @TState) -> ByteArray;
    fn symbol(self: @TState) -> ByteArray;
}

#[starknet::embeddable]
impl IERC721MetadataImpl<
    TContractState,
    +HasComponent<TContractState>,
    +SRC5Component::HasComponent<TContractState>,
    +Drop<TContractState>
> of IERC721Metadata<TContractState> {
    fn name(self: @TContractState) -> ByteArray {
        let component = HasComponent::get_component(self);
        ERC721Metadata::name(component)
    }

    fn symbol(self: @TContractState) -> ByteArray {
        let component = HasComponent::get_component(self);
        ERC721Metadata::symbol(component)
    }
}


#[starknet::contract]
mod Handles {
    // *************************************************************************
    //                            IMPORT
    // *************************************************************************
    use core::traits::TryInto;
    use core::poseidon::PoseidonTrait;
    use core::hash::{HashStateTrait, HashStateExTrait};
    use starknet::{ContractAddress, get_caller_address, get_block_timestamp};
    use openzeppelin::{
        account, access::ownable::OwnableComponent,
        token::erc721::{
            ERC721Component, erc721::ERC721Component::InternalTrait as ERC721InternalTrait
        },
        introspection::{src5::SRC5Component}
    };
    use karst::base::errors::Errors;
    use karst::interfaces::IKarstNFT::{IKarstNFTDispatcher, IKarstNFTDispatcherTrait};
    use karst::interfaces::IHandle::IHandle;

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);

    // allow to check what interface is supported
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;
    impl SRC5InternalImpl = SRC5Component::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl ERC721Impl = ERC721Component::ERC721Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721CamelOnlyImpl = ERC721Component::ERC721CamelOnlyImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721MetadataImpl = ERC721Component::ERC721MetadataImpl<ContractState>;

    // add an owner
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    // *************************************************************************
    //                            STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        admin: ContractAddress,
        total_supply: u256,
        local_names: LegacyMap::<u256, felt252>,
        karst_hub: ContractAddress,
    }

    // *************************************************************************
    //                            CONSTANTS
    // *************************************************************************
    const MAX_LOCAL_NAME_LENGTH: u256 = 26;
    const NAMESPACE: felt252 = 'karst';

    // *************************************************************************
    //                            EVENTS
    // *************************************************************************
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        HandleMinted: HandleMinted,
        HandleBurnt: HandleBurnt,
    }

    #[derive(Drop, starknet::Event)]
    pub struct HandleMinted {
        local_name: felt252,
        token_id: u256,
        to: ContractAddress,
        block_timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct HandleBurnt {
        local_name: felt252,
        token_id: u256,
        owner: ContractAddress,
        block_timestamp: u64,
    }

    // *************************************************************************
    //                            CONSTRUCTOR
    // *************************************************************************
    #[constructor]
    fn constructor(
        ref self: ContractState,
        admin: ContractAddress, // to perform upgrade
        hub_address: ContractAddress
    ) {
        self.admin.write(admin);
        self.karst_hub.write(hub_address);
        self.erc721.initializer("KARST HANDLES", "KARST", "");
    }

    // *************************************************************************
    //                            EXTERNAL FUNCTIONS
    // *************************************************************************
    #[abi(embed_v0)]
    impl HandlesImpl of IHandle<ContractState> {
        fn mint_handle(
            ref self: ContractState, address: ContractAddress, local_name: felt252,
        ) -> u256 {
            // self._validate_local_name(local_name) - This is waiting for #17
            let token_id = self._mint_handle(address, local_name);
            token_id
        }

        fn burn_handle(ref self: ContractState, token_id: u256) {
            assert(get_caller_address() == self.erc721.owner_of(token_id), Errors::INVALID_OWNER);
            let current_supply = self.total_supply.read();
            let local_name = self.local_names.read(token_id);
            self.erc721._burn(token_id);
            self.total_supply.write(current_supply - 1);
            self.local_names.write(token_id, 0);
            self
                .emit(
                    HandleBurnt {
                        local_name: local_name,
                        owner: get_caller_address(),
                        token_id: token_id,
                        block_timestamp: get_block_timestamp()
                    }
                );
        }

        // *************************************************************************
        //                            GETTERS
        // *************************************************************************
        fn get_namespace(self: @ContractState) -> felt252 {
            return NAMESPACE;
        }

        fn get_local_name(self: @ContractState, token_id: u256) -> felt252 {
            self.local_names.read(token_id)
        }

        fn get_handle(self: @ContractState, token_id: u256) -> felt252 {
            let local_name = self.get_local_name(token_id);
            let handle = NAMESPACE + '@/' + local_name;
            handle
        }

        fn exists(self: @ContractState, token_id: u256) -> bool {
            self.erc721._exists(token_id)
        }

        fn total_supply(self: @ContractState) -> u256 {
            self.total_supply.read()
        }

        fn get_token_id(self: @ContractState, local_name: felt252) -> u256 {
            let hash: u256 = PoseidonTrait::new()
                .update_with(local_name)
                .finalize()
                .try_into()
                .unwrap();
            hash
        }

        fn get_handle_token_uri(
            self: @ContractState, token_id: u256, local_name: felt252
        ) -> ByteArray {
            // TODO 
            // add namespace
            let bytes = BytesTrait::new();
            bytes.append(local_name);
            bytes.append(token_id);

            let byte_array = ByteArray::new();
            
            for byte in bytes {
               byte_array.append(byte.read_u8())
            }

            let base64_encoded = alexandria_encoding::base64::encode(byte_array);

            let mut result_byte_array = ByteArray::new();
            for byte in base64_encoded {
                result_byte_array.append_byte(byte);
            }
            let result_string = result_byte_array.to_string();

            result_string 
        }
    }


    // *************************************************************************
    //                            PRIVATE FUNCTIONS
    // *************************************************************************
    #[generate_trait]
    impl Private of PrivateTrait {
        fn _mint_handle(
            ref self: ContractState, address: ContractAddress, local_name: felt252,
        ) -> u256 {
            let token_id = self.get_token_id(local_name);
            let mut current_total_supply = self.total_supply.read();
            current_total_supply += 1;
            self.total_supply.write(current_total_supply);

            self.erc721._mint(address, token_id);
            self.local_names.write(token_id, local_name);

            self
                .emit(
                    HandleMinted {
                        local_name: local_name,
                        to: address,
                        token_id: token_id,
                        block_timestamp: get_block_timestamp()
                    }
                );
            token_id
        }

        fn _validate_local_name(ref self: ContractState, local_name: felt252) { // TODO
        }

        fn _is_alpha_numeric(self: @ContractState, char: felt252) -> bool {
            // TODO
            return false;
        }
    }
}
