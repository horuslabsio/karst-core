#[starknet::contract]
pub mod KarstNFT {
    // *************************************************************************
    //                             IMPORTS
    // *************************************************************************
    use starknet::{
        ContractAddress, get_block_timestamp,
        storage::{
            StoragePointerWriteAccess, StoragePointerReadAccess, Map, StorageMapReadAccess,
            StorageMapWriteAccess
        }
    };
    use core::num::traits::zero::Zero;
    use karst::interfaces::IKarstNFT;
    use karst::base::{
        constants::errors::Errors::ALREADY_MINTED,
        token_uris::profile_token_uri::ProfileTokenUri::get_token_uri,
    };
    use openzeppelin::{
        access::ownable::OwnableComponent, token::erc721::{ERC721Component, ERC721HooksEmptyImpl},
        introspection::{src5::SRC5Component}
    };
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
        admin: ContractAddress,
        last_minted_id: u256,
        mint_timestamp: Map<u256, u64>,
        user_token_id: Map<ContractAddress, u256>,
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
    fn constructor(ref self: ContractState, admin: ContractAddress,) {
        self.admin.write(admin);
        self.erc721.initializer("Karst", "KST", "");
    }

    #[abi(embed_v0)]
    impl KarstImpl of IKarstNFT::IKarstNFT<ContractState> {
        // *************************************************************************
        //                            EXTERNAL
        // *************************************************************************
        /// @notice mints the karst NFT
        /// @param address address of user trying to mint the karst NFT
        fn mint_karstnft(ref self: ContractState, address: ContractAddress) {
            let balance = self.erc721.balance_of(address);
            assert(balance.is_zero(), ALREADY_MINTED);

            let mut token_id = self.last_minted_id.read() + 1;
            self.erc721.mint(address, token_id);
            let timestamp: u64 = get_block_timestamp();

            self.user_token_id.write(address, token_id);
            self.last_minted_id.write(token_id);
            self.mint_timestamp.write(token_id, timestamp);
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

        // *************************************************************************
        //                            METADATA
        // *************************************************************************
        /// @notice returns the collection name
        fn name(self: @ContractState) -> ByteArray {
            return "Karst";
        }

        /// @notice returns the collection symbol
        fn symbol(self: @ContractState) -> ByteArray {
            return "KST";
        }

        /// @notice returns the token_uri for a particular token_id
        fn token_uri(self: @ContractState, token_id: u256) -> ByteArray {
            let mint_timestamp: u64 = self.get_token_mint_timestamp(token_id);
            get_token_uri(token_id, mint_timestamp)
        }
    }
}
