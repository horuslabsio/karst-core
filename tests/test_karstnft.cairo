use core::traits::TryInto;
use core::traits::Into;
use starknet::ContractAddress;
use snforge_std::{declare, ContractClassTrait};
use karst::karstnft::karstnft::IKarstDispatcher;
use karst::karstnft::karstnft::KarstNFT;
use openzeppelin::token::erc721::interface::IERC721MetadataDispatcher;


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
    let contract_address:ContractAddress = deploy_contract("KarstNFT");
    let dispatcher = IERC721MetadataDispatcher{ contract_address };
    let karstnft_name = dispatcher.name();
    assert(karstnft_name == 'KarstNFT', 'invalid');
    
}



