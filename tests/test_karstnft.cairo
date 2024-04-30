use core::traits::TryInto;
use core::traits::Into;
use starknet::ContractAddress;
use snforge_std::{declare, ContractClassTrait};
use karst::interface::Ikarst::{IKarstDispatcher, IKarstDispatcherTrait};
use karst::karstnft::karstnft::KarstNFT;
use karst::interface::IERC721::{IERC721Dispatcher, IERC721DispatcherTrait};


fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap();
    let admin: ContractAddress = 123.try_into().unwrap();
    let names: ByteArray = "KarstNFT";
    let symbol: ByteArray = "KNFT";
    let base_uri: ByteArray = "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaYXr4gQ/";
    let mut calldata: Array<felt252> = array![admin.into()];
    names.serialize(ref calldata);
    symbol.serialize(ref calldata);
    base_uri.serialize(ref calldata);

    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    contract_address
}
#[test]
fn test_constructor_func() {
    let contract_address: ContractAddress = deploy_contract("KarstNFT");
    let dispatcher = IERC721Dispatcher { contract_address };
    let nft_name = dispatcher.name();
    let nft_symbol = dispatcher.symbol();
    assert(nft_name == "KarstNFT", 'error');
    assert(nft_symbol == "KNFT", 'error');
}

#[test]
fn test_token_uri() {
    let contract_address: ContractAddress = deploy_contract("KarstNFT");
    let karstDispatcher = IKarstDispatcher { contract_address };
    let dispatcher = IERC721Dispatcher { contract_address };
    karstDispatcher.mint_karstnft();
    let token_id = karstDispatcher.token_id();
    let base_uri = dispatcher.token_uri(token_id);
    assert(token_id == 0, 'error');
    assert(base_uri == "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaYXr4gQ/0", 'error');
}

