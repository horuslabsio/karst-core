use starknet::ContractAddress;

#[starknet::interface]
pub trait IKarst<TState> {
    fn mint_karstnft(ref self: TState);
}



#[starknet::contract]
pub mod KarstNFT {
    use starknet::{ContractAddress, get_caller_address};
    use openzeppelin::{
        account, access::ownable::OwnableComponent,
        token::erc721::{
            ERC721Component, erc721::ERC721Component::InternalTrait as ERC721InternalTrait
        },
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
    // allow to query name of nft collection
    #[abi(embed_v0)]
    impl ERC721MetadataImpl = ERC721Component::ERC721MetadataImpl<ContractState>;

    // add an owner
    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        admin: ContractAddress,
        tokenId: u256
    }

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


    #[constructor]
    fn constructor(
        ref self: ContractState,
        admin: ContractAddress,
        name: ByteArray,
        symbol: ByteArray,
        base_uri: ByteArray
    ) {
        self.admin.write(admin);
        self.erc721.initializer(name, symbol, base_uri);
    }
    #[abi(embed_v0)]
    impl KarstImpl of super::IKarst<ContractState> {
        fn mint_karstnft(ref self: ContractState) {
            let caller = get_caller_address();
            let mut current_token_id = self.tokenId.read();
            self.erc721._mint(caller, current_token_id);
            current_token_id += 1;
        }

        
    }
}
