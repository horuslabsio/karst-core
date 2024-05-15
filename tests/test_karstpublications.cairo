use core::traits::TryInto;
use core::traits::Into;
use starknet::ContractAddress;
use snforge_std::{declare, ContractClassTrait};
use karst::interface::Ikarst::{IKarstDispatcher, IKarstDispatcherTrait};
use karst::interface::IkarstPublications::{IkarstPublicationsDispatcher, IkarstPublicationsDispatcherTrait};
use karst::interface::IERC721::{IERC721Dispatcher, IERC721DispatcherTrait};


fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name);
    let (contract_address, _) = contract.deploy(@array![]).unwrap();
    contract_address
}

#[test]
fn test_post() {
    let contract_address: ContractAddress = deploy_contract("publications");
    let publicationsDispatcher = IkarstPublicationsDispatcher { contract_address };
    publicationsDispatcher.post("test".try_into().unwrap());
    println!("deployed address: {:?}", contract_address);
}

