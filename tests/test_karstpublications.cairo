use core::traits::TryInto;
use core::traits::Into;
use starknet::ContractAddress;
use snforge_std::{declare, ContractClassTrait};
use karst::interface::Ikarst::{IKarstDispatcher, IKarstDispatcherTrait};
use karst::karstnft::karstnft::KarstNFT;
use karst::interface::IERC721::{IERC721Dispatcher, IERC721DispatcherTrait};


fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap();
    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    contract_address
}

#[test]
fn test_post() {
    let contract_address: ContractAddress = deploy_contract("publications");
    let publicationsDispatcher = IKarstDispatcher { contract_address };
    publicationsDispatcher.create_post("test".try_into().unwrap());
    
}

