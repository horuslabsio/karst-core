// *************************************************************************
//                               CHANNEL TEST
// *************************************************************************
use core::option::OptionTrait;
use core::starknet::SyscallResultTrait;
use core::result::ResultTrait;
use core::traits::{TryInto, Into};
use starknet::{ContractAddress, get_block_timestamp};


use snforge_std::{
    declare, start_cheat_caller_address, stop_cheat_caller_address, spy_events,
    EventSpyAssertionsTrait, ContractClassTrait, DeclareResultTrait, EventSpy
};


use karst::channel::channel::ChannelComponent::{
    Event as ChannelEvent, ChannelCreated, JoinedChannel, LeftChannel, ChannelModAdded,
    ChannelModRemoved, ChannelBanStatusUpdated
};
use karst::base::constants::types::{channelParams, channelMember};
use karst::interfaces::IChannel::{IChannelDispatcher, IChannelDispatcherTrait};
use karst::presets::channel;

const HUB_ADDRESS: felt252 = 'HUB';
const USER_ONE: felt252 = 'BOB';
const USER_TWO: felt252 = 'ALICE';
// these are the channel users
const USER_THREE: felt252 = 'ROB';
const USER_FOUR: felt252 = 'DAN';
const USER_FIVE: felt252 = 'RANDY';
const USER_SIX: felt252 = 'JOE';


fn __setup__() -> (ContractAddress, u256, ContractAddress, ByteArray) {
    let nft_contract = declare("KarstNFT").unwrap().contract_class();
    let mut calldata: Array<felt252> = array![USER_ONE];

    let (nft_contract_address, _) = nft_contract.deploy(@calldata).unwrap_syscall();

    let registry_class_hash = declare("Registry").unwrap().contract_class();
    let (registry_contract_address, _) = registry_class_hash.deploy(@array![]).unwrap_syscall();

    let channel_contract = declare("KarstChannel").unwrap().contract_class();

    let mut channel_constructor_calldata = array![];

    let (channel_contract_address, _) = channel_contract
        .deploy(@channel_constructor_calldata)
        .unwrap_syscall();

    // declare account
    let account_class_hash = declare("Account").unwrap().contract_class();

    // declare follownft
    let follow_nft_classhash = declare("Follow").unwrap().contract_class();

    //declare collectnft
    let collect_nft_classhash = declare("CollectNFT").unwrap().contract_class();

    let dispatcher = IChannelDispatcher { contract_address: channel_contract_address };

    // create channel for the use1
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let mut spy = spy_events();
    let metadat_uri: ByteArray = "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaYXr4gQ/";
    let channel_id: u256 = dispatcher
        .create_channel(
            channelParams {
                channel_id: 0,
                channel_owner: USER_ONE.try_into().unwrap(),
                channel_metadata_uri: metadat_uri.clone(),
                channel_nft_address: nft_contract_address,
                channel_total_members: 1,
                channel_censorship: false,
            }
        );

    stop_cheat_caller_address(channel_contract_address);

    return (channel_contract_address, channel_id, USER_ONE.try_into().unwrap(), metadat_uri);
}





// leave channel testing
#[test]
fn test_leave_channel() {
    let (channel_contract_address, channel_id, owner, _) = __setup__();
    let dispatcher = IChannelDispatcher { contract_address: channel_contract_address };
    // to leave the channel first join the channel

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_THREE.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_FOUR.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);
    // check is member
    assert(
        dispatcher.is_channel_member(USER_TWO.try_into().unwrap(), channel_id) == true,
        'invalid channel member'
    );

    // leave the channel
    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.leave_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    // not the member of that
    assert(
        !dispatcher.is_channel_member(USER_TWO.try_into().unwrap(), channel_id) == true,
        'channel not leaved'
    );
}


// // counting of the member of the channel .
#[test]
fn test_total_members() {
    let (channel_contract_address, channel_id, owner, _) = __setup__();
    let dispatcher = IChannelDispatcher { contract_address: channel_contract_address };

    // join the channel
    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    // join the channel
    start_cheat_caller_address(channel_contract_address, USER_THREE.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    // join the channel
    start_cheat_caller_address(channel_contract_address, USER_FOUR.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    // join the channel
    start_cheat_caller_address(channel_contract_address, USER_FIVE.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    // join the channel
    start_cheat_caller_address(channel_contract_address, USER_SIX.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    // check the total member of the channel
    let total_members = dispatcher.get_total_members(channel_id);
    assert(total_members == 5, 'invalid total members');
}

#[test]
fn test_adding_modeartor() {
    // user 1 is the owner of the channel
    let (channel_contract_address, channel_id, owner, _) = __setup__();
    let dispatcher = IChannelDispatcher { contract_address: channel_contract_address };

    // let say add the 2 more user 2 and user3 as the moderator
    start_cheat_caller_address(channel_contract_address, owner);
    dispatcher.add_channel_mods(channel_id, USER_TWO.try_into().unwrap());
    dispatcher.add_channel_mods(channel_id, USER_THREE.try_into().unwrap());
    stop_cheat_caller_address(channel_contract_address);
    // check the moderator

    assert(
        dispatcher.is_channel_mod(USER_TWO.try_into().unwrap(), channel_id) == true,
        'user_two is not mod'
    );
    assert(
        dispatcher.is_channel_mod(USER_THREE.try_into().unwrap(), channel_id) == true,
        'user_three isnt mod'
    );

    // // remove the moderator user_two and keep the use three

    start_cheat_caller_address(channel_contract_address, owner);
    dispatcher.remove_channel_mods(channel_id, USER_TWO.try_into().unwrap());
    stop_cheat_caller_address(channel_contract_address);

    // check the moderator
    assert(
        dispatcher.is_channel_mod(USER_TWO.try_into().unwrap(), channel_id) == false,
        'user_two should not be mod'
    );
    assert(
        dispatcher.is_channel_mod(USER_THREE.try_into().unwrap(), channel_id) == true,
        'user_three should be mod'
    );
}


// joining the channel testing
#[test]
fn test_joining_channel() {
    let (channel_contract_address, channel_id, owner, _) = __setup__();
    let dispatcher = IChannelDispatcher { contract_address: channel_contract_address };

    // user
    start_cheat_caller_address(channel_contract_address, USER_THREE.try_into().unwrap());
    // try to join the channel
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    // is channel member of the channel

    start_cheat_caller_address(channel_contract_address, USER_THREE.try_into().unwrap());
    let is_channel_member = dispatcher
        .is_channel_member(USER_THREE.try_into().unwrap(), channel_id);
    assert(is_channel_member == true, 'invalid channel member');
    stop_cheat_caller_address(channel_contract_address);
}

//todo working fine failed through the contract assert  
// if aleready ban does not able to join the channel
// #[test]
// fn test_already_ban_cannot_join_channel() {
//     let (channel_contract_address, channel_id, owner, _) = __setup__();
//     let dispatcher = IChannelDispatcher { contract_address: channel_contract_address };

//     // moderator
//     start_cheat_caller_address(channel_contract_address, owner);
//     dispatcher.set_ban_status(channel_id, USER_THREE.try_into().unwrap(), true);
//     stop_cheat_caller_address(channel_contract_address);


//     // user
//     // cannot able to join 
//     start_cheat_caller_address(channel_contract_address, USER_THREE.try_into().unwrap());
//     dispatcher.join_channel(channel_id);
//     stop_cheat_caller_address(channel_contract_address);

//     // is channel member of the channel

// }


#[test]
fn test_channel_member() {
    let (channel_contract_address, channel_id, owner, _) = __setup__();
    let dispatcher = IChannelDispatcher { contract_address: channel_contract_address };
    start_cheat_caller_address(channel_contract_address, owner);
    let is_channel_member = dispatcher.is_channel_member(owner, channel_id);
    assert(is_channel_member == true, 'invalid channel member');
}

#[test]
fn test_create_channel() {
    let (channel_contract_address, channel_id, _, metadata_uri) = __setup__();

    let dispatcher = IChannelDispatcher { contract_address: channel_contract_address };

    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let channel_metadata_uri = dispatcher.get_channel_metadata_uri(channel_id);
    assert(channel_metadata_uri == metadata_uri, 'invalid channel uri ');
    stop_cheat_caller_address(channel_contract_address);
}
