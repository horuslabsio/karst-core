use core::num::traits::zero::Zero;
use core::starknet::SyscallResultTrait;
use core::traits::{TryInto, Into};
use starknet::{ContractAddress};
use snforge_std::{declare, ContractClassTrait, CheatTarget, start_prank, stop_prank,};

use openzeppelin::{token::erc721::interface::{ERC721ABIDispatcher, ERC721ABIDispatcherTrait}};

use karst::interfaces::IKarstNFT::{IKarstNFTDispatcher, IKarstNFTDispatcherTrait};
use karst::base::{errors::Errors::ALREADY_MINTED};

const ADMIN: felt252 = 'ADMIN';
const USER_ONE: felt252 = 'BOB';

fn __setup__() -> ContractAddress {
    let nft_contract = declare("KarstNFT").unwrap();
    let names: ByteArray = "KarstNFT";
    let symbol: ByteArray = "KNFT";
    let base_uri: ByteArray = "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaYXr4gQ/";
    let mut calldata: Array<felt252> = array![ADMIN];
    names.serialize(ref calldata);
    symbol.serialize(ref calldata);
    base_uri.serialize(ref calldata);
    let (nft_contract_address, _) = nft_contract.deploy(@calldata).unwrap_syscall();
    (nft_contract_address)
}

#[test]
fn test_nft_count_on_init_is_zero() {
    let nft_contract_address = __setup__();

    let erc721_dispatcher = ERC721ABIDispatcher { contract_address: nft_contract_address };

    start_prank(CheatTarget::One(nft_contract_address), ADMIN.try_into().unwrap());

    let balance = erc721_dispatcher.balance_of(USER_ONE.try_into().unwrap());

    assert(balance.is_zero(), ALREADY_MINTED);

    stop_prank(CheatTarget::One(nft_contract_address));
}

#[test]
fn test_last_minted_id_on_init_is_zero() {
    let nft_contract_address = __setup__();

    let dispatcher = IKarstNFTDispatcher { contract_address: nft_contract_address };

    start_prank(CheatTarget::One(nft_contract_address), ADMIN.try_into().unwrap());

    let last_minted_id = dispatcher.get_last_minted_id();

    assert(last_minted_id.is_zero(), 'last minted id not zero');

    stop_prank(CheatTarget::One(nft_contract_address));
}

#[test]
fn test_user_token_id_on_init_is_zero() {
    let nft_contract_address = __setup__();

    let dispatcher = IKarstNFTDispatcher { contract_address: nft_contract_address };

    start_prank(CheatTarget::One(nft_contract_address), ADMIN.try_into().unwrap());

    let user_token_id = dispatcher.get_user_token_id(USER_ONE.try_into().unwrap());

    assert(user_token_id.is_zero(), 'user token id not zero');

    stop_prank(CheatTarget::One(nft_contract_address));
}

#[test]
fn test_mint_karst_nft() {
    let nft_contract_address = __setup__();

    let dispatcher = IKarstNFTDispatcher { contract_address: nft_contract_address };
    let erc721_dispatcher = ERC721ABIDispatcher { contract_address: nft_contract_address };

    start_prank(CheatTarget::One(nft_contract_address), ADMIN.try_into().unwrap());

    dispatcher.mint_karstnft(USER_ONE.try_into().unwrap());
    let balance = erc721_dispatcher.balance_of(USER_ONE.try_into().unwrap());

    assert(balance == 1, 'nft not minted');

    stop_prank(CheatTarget::One(nft_contract_address));
}

#[test]
#[should_panic(expected: ('USER_ALREADY_MINTED',))]
fn test_mint_karst_nft_twice_for_the_same_user() {
    let nft_contract_address = __setup__();

    let dispatcher = IKarstNFTDispatcher { contract_address: nft_contract_address };

    start_prank(CheatTarget::One(nft_contract_address), ADMIN.try_into().unwrap());

    dispatcher.mint_karstnft(USER_ONE.try_into().unwrap());
    dispatcher.mint_karstnft(USER_ONE.try_into().unwrap());

    stop_prank(CheatTarget::One(nft_contract_address));
}

#[test]
fn test_get_last_minted_id_after_minting() {
    let nft_contract_address = __setup__();

    let dispatcher = IKarstNFTDispatcher { contract_address: nft_contract_address };

    start_prank(CheatTarget::One(nft_contract_address), ADMIN.try_into().unwrap());

    dispatcher.mint_karstnft(USER_ONE.try_into().unwrap());
    let last_minted_id = dispatcher.get_last_minted_id();

    assert(last_minted_id == 1, 'invalid last minted id');

    stop_prank(CheatTarget::One(nft_contract_address));
}

#[test]
fn test_get_user_token_id_after_minting() {
    let nft_contract_address = __setup__();

    let dispatcher = IKarstNFTDispatcher { contract_address: nft_contract_address };

    start_prank(CheatTarget::One(nft_contract_address), ADMIN.try_into().unwrap());

    dispatcher.mint_karstnft(USER_ONE.try_into().unwrap());
    let user_token_id = dispatcher.get_user_token_id(USER_ONE.try_into().unwrap());

    assert(user_token_id == 1, 'invalid user token id');

    stop_prank(CheatTarget::One(nft_contract_address));
}
