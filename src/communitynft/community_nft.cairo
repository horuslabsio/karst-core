#[starknet::contract]
pub mod CommunityNft {
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address};
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc721::{ERC721Component, ERC721HooksEmptyImpl};

    use karst::interfaces::ICommunityNft::ICommunityNft;
    use karst::interfaces::IHub::{IHubDispatcher, IHubDispatcherTrait};
    use karst::base::{
        constants::errors::Errors::{ALREADY_MINTED, NOT_TOKEN_OWNER, TOKEN_DOES_NOT_EXIST},
        utils::base64_extended::convert_into_byteArray
    };
    use starknet::storage::{
        Map, StoragePointerWriteAccess, StoragePointerReadAccess, StorageMapReadAccess,
        StorageMapWriteAccess
    };
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    // ERC721 Mixin
    #[abi(embed_v0)]
    impl ERC721MixinImpl = ERC721Component::ERC721MixinImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        karst_hub: ContractAddress,
        last_minted_id: u256,
        mint_timestamp: Map<u256, u64>,
        user_token_id: Map<ContractAddress, u256>,
        profile_address: ContractAddress,
        community_id: u256
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        karst_hub: ContractAddress,
        profile_address: ContractAddress,
        community_id: u256
    ) {
        self.karst_hub.write(karst_hub);
        self.profile_address.write(profile_address);
        self.community_id.write(community_id);
    }

    #[abi(embed_v0)]
    impl CommunityNft of ICommunityNft<ContractState> {
        // *************************************************************************
        //                            EXTERNAL
        // *************************************************************************

        /// @notice mints the user community NFT
        /// @param address address of user trying to mint the community NFT token
        fn mint(ref self: ContractState, user_address: ContractAddress) -> u256 {
            let balance = self.erc721.balance_of(user_address);
            assert(balance.is_zero(), ALREADY_MINTED);

            let mut token_id = self.last_minted_id.read() + 1;
            self.erc721.mint(user_address, token_id);
            let timestamp: u64 = get_block_timestamp();
            self.user_token_id.write(user_address, token_id);
            self.last_minted_id.write(token_id);
            self.mint_timestamp.write(token_id, timestamp);
            self.last_minted_id.read()
        }

        /// @notice burn the user community NFT
        /// @param address address of user trying to burn the community NFT token
        fn burn(ref self: ContractState, user_address: ContractAddress, token_id: u256) {
            let user_token_id = self.user_token_id.read();
            assert(user_token_id == token_id, NOT_TOKEN_OWNER);
            // check the token exist in erc721
            assert(self.erc721.exists(token_id), TOKEN_DOES_NOT_EXIST);
            self.erc721.burn(token_id);
            self.user_token_id.write(user_address, 0);
        }

        // *************************************************************************
        //                            GETTERS
        // *************************************************************************
        /// @notice gets the token ID for a user address
        /// @param user address of user to retrieve token ID for
        fn get_user_token_id(self: @ContractState, user_address: ContractAddress) -> u256 {
            self.user_token_id.read(user_address)
        }

        // *************************************************************************
        //                            METADATA
        // *************************************************************************
        /// @notice returns the community name
        fn name(self: @ContractState) -> ByteArray {
            let mut collection_name = ArrayTrait::<felt252>::new();
            let profile_address_felt252: felt252 = self.profile_address.read().into();
            let community_id_felt252: felt252 = self.community_id.read().try_into().unwrap();
            collection_name.append('Karst Community | Profile #');
            collection_name.append(profile_address_felt252);
            collection_name.append('- Community #');
            collection_name.append(community_id_felt252);
            let collection_name_byte = convert_into_byteArray(ref collection_name);
            collection_name_byte
        }

        /// @notice returns the collection symbol
        fn symbol(self: @ContractState) -> ByteArray {
            return "KARST:COMMUNITY";
        }

        /// @notice returns the token_uri for a particular token_id
        fn token_uri(self: @ContractState, token_id: u256) -> ByteArray {
            assert(self.erc721.exists(token_id), TOKEN_DOES_NOT_EXIST);
            let profile_address = self.profile_address.read();
            let community_id = self.community_id.read();
            let karst_hub = self.karst_hub.read();
            let token_uri = IHubDispatcher { contract_address: karst_hub }
                .get_publication_content_uri(profile_address, community_id);
            token_uri
        }
    }
}