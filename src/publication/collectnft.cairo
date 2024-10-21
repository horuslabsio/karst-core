#[starknet::contract]
pub mod CollectNFT {
    // *************************************************************************
    //                             IMPORTS
    // *************************************************************************
    use core::array::ArrayTrait;
    use core::traits::Into;
    use core::option::OptionTrait;
    use core::traits::TryInto;
    use starknet::{ContractAddress, get_block_timestamp};
    use core::num::traits::zero::Zero;
    use karst::interfaces::ICollectNFT::ICollectNFT;
    use karst::interfaces::IHub::{IHubDispatcher, IHubDispatcherTrait};
    use karst::base::{
        constants::errors::Errors::{ALREADY_MINTED, TOKEN_DOES_NOT_EXIST},
        utils::base64_extended::convert_into_byteArray
    };
    use starknet::storage::{
        Map, StoragePointerWriteAccess, StoragePointerReadAccess, StorageMapReadAccess,
        StorageMapWriteAccess
    };
    use openzeppelin::{
        access::ownable::OwnableComponent, token::erc721::{ERC721Component, ERC721HooksEmptyImpl},
        introspection::{src5::SRC5Component}
    };

    // *************************************************************************
    //                             COMPONENTS
    // *************************************************************************
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);

    // allow to check what interface is supported
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;
    impl SRC5InternalImpl = SRC5Component::InternalImpl<ContractState>;

    // make it a NFT
    #[abi(embed_v0)]
    impl ERC721Impl = ERC721Component::ERC721Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721CamelOnlyImpl = ERC721Component::ERC721CamelOnlyImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    // add an owner
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;


    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        karst_hub: ContractAddress,
        last_minted_id: u256,
        mint_timestamp: Map<u256, u64>,
        user_token_id: Map<ContractAddress, u256>,
        profile_address: ContractAddress,
        pub_id: u256,
    }

    // *************************************************************************
    //                              EVENTS
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
    }

    // *************************************************************************
    //                              CONSTRUCTOR
    // *************************************************************************
    #[constructor]
    fn constructor(
        ref self: ContractState,
        karst_hub: ContractAddress,
        profile_address: ContractAddress,
        pub_id: u256,
    ) {
        self.karst_hub.write(karst_hub);
        self.profile_address.write(profile_address);
        self.pub_id.write(pub_id);
    }

    #[abi(embed_v0)]
    impl CollectNFTImpl of ICollectNFT<ContractState> {
        // *************************************************************************
        //                            EXTERNAL
        // *************************************************************************
        /// @notice mints the collect NFT
        /// @param address address of user trying to mint the collect NFT
        fn mint_nft(ref self: ContractState, address: ContractAddress) -> u256 {
            let balance = self.erc721.balance_of(address);
            assert(balance.is_zero(), ALREADY_MINTED);

            let mut token_id = self.last_minted_id.read() + 1;
            self.erc721.mint(address, token_id);
            let timestamp: u64 = get_block_timestamp();
            self.user_token_id.write(address, token_id);
            self.last_minted_id.write(token_id);
            self.mint_timestamp.write(token_id, timestamp);
            self.last_minted_id.read()
        }

        // *************************************************************************
        //                            GETTERS
        // *************************************************************************
        /// @notice gets the token ID for a user address
        /// @param user address of user to retrieve token ID for
        fn get_user_token_id(self: @ContractState, user: ContractAddress) -> u256 {
            self.user_token_id.read(user)
        }

        fn get_token_mint_timestamp(self: @ContractState, token_id: u256) -> u64 {
            self.mint_timestamp.read(token_id)
        }

        /// @notice gets the last minted NFT
        fn get_last_minted_id(self: @ContractState) -> u256 {
            self.last_minted_id.read()
        }
        ///@notice get source publication pointer
        ///
        fn get_source_publication_pointer(self: @ContractState) -> (ContractAddress, u256) {
            let profile_address = self.profile_address.read();
            let pub_id = self.pub_id.read();
            (profile_address, pub_id)
        }
        // *************************************************************************
        //                            METADATA
        // *************************************************************************
        /// @notice returns the collection name
        fn name(self: @ContractState) -> ByteArray {
            let mut collection_name = ArrayTrait::<felt252>::new();
            let profile_address_felt252: felt252 = self.profile_address.read().into();
            let pub_id_felt252: felt252 = self.pub_id.read().try_into().unwrap();
            collection_name.append('Karst Collect | Profile #');
            collection_name.append(profile_address_felt252);
            collection_name.append('- Publication #');
            collection_name.append(pub_id_felt252);
            let collection_name_byte = convert_into_byteArray(ref collection_name);
            collection_name_byte
        }

        /// @notice returns the collection symbol
        fn symbol(self: @ContractState) -> ByteArray {
            return "KARST:COLLECT";
        }

        /// @notice returns the token_uri for a particular token_id
        fn token_uri(self: @ContractState, token_id: u256) -> ByteArray {
            assert(self.erc721.exists(token_id), TOKEN_DOES_NOT_EXIST);
            let profile_address = self.profile_address.read();
            let pub_id = self.pub_id.read();
            let karst_hub = self.karst_hub.read();
            let token_uri = IHubDispatcher { contract_address: karst_hub }
                .get_publication_content_uri(profile_address, pub_id);
            token_uri
        }
    }
}
