use starknet::ContractAddress;

#[starknet::interface]
trait IERC721<TContractState> {
    fn mint(ref self: TContractState, to: ContractAddress, token_id: u256);
    fn burn(ref self: TContractState, token_id: u256);
}


#[starknet::contract]
pub mod CommunityNft {
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc721::{ERC721Component, ERC721HooksEmptyImpl};
    use starknet::ContractAddress;
    use karst::interfaces::ICommunityNft::ICommunityNft;

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
        src5: SRC5Component::Storage
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
    fn constructor(ref self: ContractState, name: felt252, symbol: felt252) {
        self.erc721.initializer(name, symbol, "https://api.karst.com/v1/");
    }

    #[abi(embed_v0)]
    impl CommunityNft of ICommunityNft<ContractState> {
        fn mint(ref self: ContractState, to: ContractAddress, token_id: u256) {
            self.erc721.mint(to, token_id);
        }
        fn burn(ref self: ContractState, token_id: u256) {
            self.erc721.burn(token_id);
        }
    }
}
