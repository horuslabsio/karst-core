use core::option::OptionTrait;
use core::starknet::SyscallResultTrait;
use core::result::ResultTrait;
use core::traits::TryInto;
use core::traits::Into;
use starknet::{ContractAddress};
use karst::publications::publications::Publications;
use snforge_std::{
    declare, ContractClassTrait, CheatTarget, start_prank, stop_prank, spy_events, SpyOn, EventSpy,
    EventAssertions
};
use karst::interface::IkarstPublications::{
    IKarstPublicationsDispatcher, IKarstPublicationsDispatcherTrait
};
use karst::interface::IERC721::{IERC721Dispatcher, IERC721DispatcherTrait};


fn deploy_contract(name: ByteArray) -> ContractAddress {
    let contract = declare(name).unwrap();
    let (contract_address, _) = contract.deploy(@array![]).unwrap_syscall();
    contract_address
}

const user1: felt252 = 'user_one';
const user2: felt252 = 'user_two';
const user3: felt252 = 'user_three';
const user4: felt252 = 'user_four';

#[test]
fn test_post() {
    let contract_address: ContractAddress = deploy_contract("Publications");
    let publicationsDispatcher = IKarstPublicationsDispatcher { contract_address };
    let mut spy = spy_events(SpyOn::One(contract_address));
    start_prank(CheatTarget::One(contract_address), user1.try_into().unwrap());
    publicationsDispatcher.post('test'.into());
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    Publications::Event::Post(
                        Publications::Post {
                            post: 'test'.into(),
                            publication_id: 0,
                            transaction_executor: user1.try_into().unwrap(),
                            block_timestamp: 0,
                        }
                    )
                )
            ]
        );
    assert(spy.events.len() == 0, 'There should be no events');
    println!("deployed address: {:?}", contract_address);
    stop_prank(CheatTarget::One(contract_address));
}


