use core::num::traits::zero::Zero;
use core::starknet::SyscallResultTrait;
use core::traits::TryInto;
use starknet::ContractAddress;

use snforge_std::{
    declare, start_cheat_caller_address, stop_cheat_caller_address, ContractClassTrait,
    DeclareResultTrait
};

use openzeppelin::{token::erc721::interface::{ERC721ABIDispatcher, ERC721ABIDispatcherTrait}};

use karst::interfaces::IKarstNFT::{IKarstNFTDispatcher, IKarstNFTDispatcherTrait};

const ADMIN: felt252 = 'ADMIN';
const USER_ONE: felt252 = 'BOB';

fn __setup__() -> ContractAddress {
    let nft_contract = declare("KarstNFT").unwrap().contract_class();
    let mut calldata: Array<felt252> = array![ADMIN];
    let (nft_contract_address, _) = nft_contract.deploy(@calldata).unwrap_syscall();
    (nft_contract_address)
}

#[test]
fn test_metadata() {
    let nft_contract_address = __setup__();
    let dispatcher = ERC721ABIDispatcher { contract_address: nft_contract_address };
    start_cheat_caller_address(nft_contract_address, ADMIN.try_into().unwrap());
    let nft_name = dispatcher.name();
    let nft_symbol = dispatcher.symbol();
    assert(nft_name == "Karst", 'invalid name');
    assert(nft_symbol == "KST", 'invalid symbol');
    stop_cheat_caller_address(nft_contract_address);
}

#[test]
fn test_last_minted_id_on_init_is_zero() {
    let nft_contract_address = __setup__();
    let dispatcher = IKarstNFTDispatcher { contract_address: nft_contract_address };
    start_cheat_caller_address(nft_contract_address, ADMIN.try_into().unwrap());
    let last_minted_id = dispatcher.get_last_minted_id();
    assert(last_minted_id.is_zero(), 'last minted id not zero');
    stop_cheat_caller_address(nft_contract_address);
}

#[test]
fn test_mint_karst_nft() {
    let nft_contract_address = __setup__();
    let dispatcher = IKarstNFTDispatcher { contract_address: nft_contract_address };
    let erc721_dispatcher = ERC721ABIDispatcher { contract_address: nft_contract_address };
    start_cheat_caller_address(nft_contract_address, ADMIN.try_into().unwrap());
    dispatcher.mint_karstnft(USER_ONE.try_into().unwrap());
    let balance = erc721_dispatcher.balance_of(USER_ONE.try_into().unwrap());
    assert(balance == 1, 'nft not minted');
    stop_cheat_caller_address(nft_contract_address);
}

#[test]
#[should_panic(expected: ('Karst: user already minted!',))]
fn test_mint_karst_nft_twice_for_the_same_user() {
    let nft_contract_address = __setup__();
    let dispatcher = IKarstNFTDispatcher { contract_address: nft_contract_address };
    start_cheat_caller_address(nft_contract_address, ADMIN.try_into().unwrap());
    dispatcher.mint_karstnft(USER_ONE.try_into().unwrap());
    dispatcher.mint_karstnft(USER_ONE.try_into().unwrap());
    stop_cheat_caller_address(nft_contract_address);
}

#[test]
fn test_get_last_minted_id_after_minting() {
    let nft_contract_address = __setup__();
    let dispatcher = IKarstNFTDispatcher { contract_address: nft_contract_address };
    start_cheat_caller_address(nft_contract_address, ADMIN.try_into().unwrap());
    dispatcher.mint_karstnft(USER_ONE.try_into().unwrap());
    let last_minted_id = dispatcher.get_last_minted_id();
    assert(last_minted_id == 1, 'invalid last minted id');
    stop_cheat_caller_address(nft_contract_address);
}

#[test]
fn test_get_user_token_id_after_minting() {
    let nft_contract_address = __setup__();
    let dispatcher = IKarstNFTDispatcher { contract_address: nft_contract_address };
    start_cheat_caller_address(nft_contract_address, ADMIN.try_into().unwrap());
    dispatcher.mint_karstnft(USER_ONE.try_into().unwrap());
    let user_token_id = dispatcher.get_user_token_id(USER_ONE.try_into().unwrap());
    assert(user_token_id == 1, 'invalid user token id');
    stop_cheat_caller_address(nft_contract_address);
}
