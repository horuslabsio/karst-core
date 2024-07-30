// *************************************************************************
//                              FOLLOW NFT TEST
// *************************************************************************
use core::option::OptionTrait;
use core::starknet::SyscallResultTrait;
use core::result::ResultTrait;
use core::traits::{TryInto, Into};
use starknet::{ContractAddress};
use snforge_std::{
    declare, ContractClassTrait, CheatTarget, start_prank, stop_prank, start_warp, stop_warp
};

use karst::interfaces::IFollowNFT::{IFollowNFTDispatcher, IFollowNFTDispatcherTrait};
use karst::follownft::follownft::Follow;
use karst::base::constants::types::FollowData;
use karst::interfaces::IERC721::{IERC721Dispatcher, IERC721DispatcherTrait};

const HUB_ADDRESS: felt252 = 24205;
const ADMIN: felt252 = 13245;
const FOLLOWED_ADDRESS: felt252 = 1234;
const FOLLOWER1: felt252 = 53453;
const FOLLOWER2: felt252 = 24252;
const FOLLOWER3: felt252 = 24552;
const FOLLOWER4: felt252 = 24262;

fn __setup__() -> ContractAddress {
    let follow_nft_contract = declare("Follow").unwrap();
    let mut follow_nft_constructor_calldata = array![HUB_ADDRESS, FOLLOWED_ADDRESS, ADMIN];
    let (follow_nft_contract_address, _) = follow_nft_contract
        .deploy(@follow_nft_constructor_calldata)
        .unwrap();
    return (follow_nft_contract_address);
}

// *************************************************************************
//                              TEST
// *************************************************************************
#[test]
fn test_follower_count_on_init_is_zero() {
    let follow_nft_contract_address = __setup__();
    let dispatcher = IFollowNFTDispatcher { contract_address: follow_nft_contract_address };
    let follower_count = dispatcher.get_follower_count();
    assert(follower_count == 0, 'invalid_follower_count');
}

#[test]
#[should_panic(expected: ('Karst: caller is not Hub!',))]
fn test_cannot_call_follow_if_not_hub() {
    let follow_nft_contract_address = __setup__();
    let dispatcher = IFollowNFTDispatcher { contract_address: follow_nft_contract_address };
    start_prank(CheatTarget::One(follow_nft_contract_address), FOLLOWER2.try_into().unwrap());
    dispatcher.follow(FOLLOWER1.try_into().unwrap());
    stop_prank(CheatTarget::One(follow_nft_contract_address));
}

#[test]
#[should_panic(expected: ('Karst: caller is not Hub!',))]
fn test_cannot_call_unfollow_if_not_hub() {
    let follow_nft_contract_address = __setup__();
    let dispatcher = IFollowNFTDispatcher { contract_address: follow_nft_contract_address };
    start_prank(CheatTarget::One(follow_nft_contract_address), FOLLOWER2.try_into().unwrap());
    dispatcher.unfollow(FOLLOWER1.try_into().unwrap());
    stop_prank(CheatTarget::One(follow_nft_contract_address));
}

#[test]
#[should_panic(expected: ('Karst: user already following!',))]
fn test_cannot_follow_if_already_following() {
    let follow_nft_contract_address = __setup__();
    let dispatcher = IFollowNFTDispatcher { contract_address: follow_nft_contract_address };
    start_prank(CheatTarget::One(follow_nft_contract_address), HUB_ADDRESS.try_into().unwrap());
    // follow
    dispatcher.follow(FOLLOWER1.try_into().unwrap());
    // try to follow again
    dispatcher.follow(FOLLOWER1.try_into().unwrap());
    stop_prank(CheatTarget::One(follow_nft_contract_address));
}

#[test]
fn test_follow() {
    let follow_nft_contract_address = __setup__();
    let dispatcher = IFollowNFTDispatcher { contract_address: follow_nft_contract_address };
    start_prank(CheatTarget::One(follow_nft_contract_address), HUB_ADDRESS.try_into().unwrap());
    dispatcher.follow(FOLLOWER1.try_into().unwrap());
    let follow_id = dispatcher.get_follow_id(FOLLOWER1.try_into().unwrap());
    let follower_profile_address = dispatcher.get_follower_profile_address(follow_id);
    assert(follow_id == 1, 'invalid follow ID');
    assert(follower_profile_address == FOLLOWER1.try_into().unwrap(), 'invalid follower profile');
    stop_prank(CheatTarget::One(follow_nft_contract_address));
}

#[test]
fn test_follower_count() {
    let follow_nft_contract_address = __setup__();
    let dispatcher = IFollowNFTDispatcher { contract_address: follow_nft_contract_address };
    start_prank(CheatTarget::One(follow_nft_contract_address), HUB_ADDRESS.try_into().unwrap());
    dispatcher.follow(FOLLOWER1.try_into().unwrap());
    dispatcher.follow(FOLLOWER2.try_into().unwrap());
    dispatcher.follow(FOLLOWER3.try_into().unwrap());
    dispatcher.follow(FOLLOWER4.try_into().unwrap());
    let follower_count = dispatcher.get_follower_count();
    assert(follower_count == 4, 'invalid follower count');
    stop_prank(CheatTarget::One(follow_nft_contract_address));
}

#[test]
fn test_is_following() {
    let follow_nft_contract_address = __setup__();
    let dispatcher = IFollowNFTDispatcher { contract_address: follow_nft_contract_address };
    start_prank(CheatTarget::One(follow_nft_contract_address), HUB_ADDRESS.try_into().unwrap());
    dispatcher.follow(FOLLOWER1.try_into().unwrap());
    let is_following_should_be_true = dispatcher.is_following(FOLLOWER1.try_into().unwrap());
    let is_following_should_be_false = dispatcher.is_following(FOLLOWER2.try_into().unwrap());
    assert(is_following_should_be_true == true, 'invalid result');
    assert(is_following_should_be_false == false, 'invalid result');
}

#[test]
fn test_follow_data() {
    let follow_nft_contract_address = __setup__();
    let dispatcher = IFollowNFTDispatcher { contract_address: follow_nft_contract_address };
    start_prank(CheatTarget::One(follow_nft_contract_address), HUB_ADDRESS.try_into().unwrap());
    start_warp(CheatTarget::One(follow_nft_contract_address), 100);
    dispatcher.follow(FOLLOWER1.try_into().unwrap());
    let follow_id = dispatcher.get_follow_id(FOLLOWER1.try_into().unwrap());
    let follow_data = dispatcher.get_follow_data(follow_id);
    let data = FollowData {
        followed_profile_address: FOLLOWED_ADDRESS.try_into().unwrap(),
        follower_profile_address: FOLLOWER1.try_into().unwrap(),
        follow_timestamp: 100,
        block_status: false
    };
    assert(
        follow_data.followed_profile_address == data.followed_profile_address,
        'invalid followed profile'
    );
    assert(
        follow_data.follower_profile_address == data.follower_profile_address,
        'invalid follower profile'
    );
    assert(follow_data.follow_timestamp == data.follow_timestamp, 'invalid follow timestamp');
    assert(follow_data.block_status == data.block_status, 'invalid block status');
    stop_prank(CheatTarget::One(follow_nft_contract_address));
    stop_warp(CheatTarget::One(follow_nft_contract_address));
}

#[test]
fn test_unfollow() {
    let follow_nft_contract_address = __setup__();
    let dispatcher = IFollowNFTDispatcher { contract_address: follow_nft_contract_address };
    start_prank(CheatTarget::One(follow_nft_contract_address), HUB_ADDRESS.try_into().unwrap());
    dispatcher.follow(FOLLOWER1.try_into().unwrap());
    dispatcher.follow(FOLLOWER2.try_into().unwrap());
    dispatcher.unfollow(FOLLOWER1.try_into().unwrap());
    let follow_id = dispatcher.get_follow_id(FOLLOWER1.try_into().unwrap());
    let follower_count = dispatcher.get_follower_count();
    assert(follow_id == 0, 'unfollow operation failed');
    assert(follower_count == 1, 'invalid follower count');
    stop_prank(CheatTarget::One(follow_nft_contract_address));
}

#[test]
#[should_panic(expected: ('Karst: user not following!',))]
fn test_cannot_unfollow_if_not_following() {
    let follow_nft_contract_address = __setup__();
    let dispatcher = IFollowNFTDispatcher { contract_address: follow_nft_contract_address };
    start_prank(CheatTarget::One(follow_nft_contract_address), HUB_ADDRESS.try_into().unwrap());
    dispatcher.unfollow(FOLLOWER1.try_into().unwrap());
    stop_prank(CheatTarget::One(follow_nft_contract_address));
}

#[test]
fn test_process_block() {
    let follow_nft_contract_address = __setup__();
    let dispatcher = IFollowNFTDispatcher { contract_address: follow_nft_contract_address };
    start_prank(CheatTarget::One(follow_nft_contract_address), HUB_ADDRESS.try_into().unwrap());
    dispatcher.follow(FOLLOWER1.try_into().unwrap());
    dispatcher.process_block(FOLLOWER1.try_into().unwrap());
    let follow_id = dispatcher.get_follow_id(FOLLOWER1.try_into().unwrap());
    let follow_data = dispatcher.get_follow_data(follow_id);
    assert(follow_data.block_status == true, 'block operation failed');
    stop_prank(CheatTarget::One(follow_nft_contract_address));
}

#[test]
fn test_process_unblock() {
    let follow_nft_contract_address = __setup__();
    let dispatcher = IFollowNFTDispatcher { contract_address: follow_nft_contract_address };
    start_prank(CheatTarget::One(follow_nft_contract_address), HUB_ADDRESS.try_into().unwrap());
    dispatcher.follow(FOLLOWER1.try_into().unwrap());
    dispatcher.process_unblock(FOLLOWER1.try_into().unwrap());
    let follow_id = dispatcher.get_follow_id(FOLLOWER1.try_into().unwrap());
    let follow_data = dispatcher.get_follow_data(follow_id);
    assert(follow_data.block_status == false, 'unblock operation failed');
    stop_prank(CheatTarget::One(follow_nft_contract_address));
}

#[test]
fn test_metadata() {
    let follow_nft_contract_address = __setup__();
    let dispatcher = IFollowNFTDispatcher { contract_address: follow_nft_contract_address };
    let nft_name = dispatcher.name();
    let nft_symbol = dispatcher.symbol();
    assert(nft_name == "KARST:FOLLOWER", 'invalid name');
    assert(nft_symbol == "KFL", 'invalid symbol');
    stop_prank(CheatTarget::One(follow_nft_contract_address));
}

#[test]
fn test_is_blocked(){
    let follow_nft_contract_address = __setup__();
    let dispatcher = IFollowNFTDispatcher { contract_address: follow_nft_contract_address };
    start_prank(CheatTarget::One(follow_nft_contract_address), HUB_ADDRESS.try_into().unwrap());
    dispatcher.follow(FOLLOWER1.try_into().unwrap());
    dispatcher.process_block(FOLLOWER1.try_into().unwrap());
    assert(dispatcher.is_blocked(FOLLOWER1.try_into().unwrap()) == true, 'incorrect value for is_blocked');
    stop_prank(CheatTarget::One(follow_nft_contract_address));
}

#[test]
fn test_follow_mints_nft(){
    let follow_nft_contract_address = __setup__();
    let dispatcher = IFollowNFTDispatcher { contract_address: follow_nft_contract_address };
    let _erc721Dispatcher = IERC721Dispatcher { contract_address: follow_nft_contract_address };
    start_prank(CheatTarget::One(follow_nft_contract_address), HUB_ADDRESS.try_into().unwrap());
    dispatcher.follow(FOLLOWER1.try_into().unwrap());
    let follow_id = dispatcher.get_follow_id(FOLLOWER1.try_into().unwrap());
    let follower_profile_address = dispatcher.get_follower_profile_address(follow_id);
    assert(_erc721Dispatcher.owner_of(follow_id) == follower_profile_address, 'Follow did not mint NFT');
}
