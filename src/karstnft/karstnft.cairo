use starknet::ContractAddress;
use openzeppelin::{
    token::erc721::{ ERC721Component::{ ERC721Metadata, HasComponent } },
    introspection::src5::SRC5Component,
};

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
pub mod KarstNFT {
    use starknet::{ContractAddress, get_caller_address};
    use karst::interface::Ikarst::IKarst;
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
        token_id: u256,
        user_token_id: LegacyMap<ContractAddress, u256>
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
    impl KarstImpl of IKarst<ContractState> {
        fn mint_karstnft(ref self: ContractState) {
            let caller = get_caller_address();
            let mut current_token_id = self.token_id.read();
            self.erc721._mint(caller, current_token_id);
            self.user_token_id.write(caller, current_token_id);
            current_token_id += 1;
            self.token_id.write(current_token_id);
        }
        fn get_user_token_id(self: @ContractState, caller: ContractAddress) -> u256 {
            self.user_token_id.read(caller)
        }
        fn get_token_id(self: @ContractState) -> u256 {
            self.token_id.read()
        }
    }
}
