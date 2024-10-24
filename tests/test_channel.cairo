// *************************************************************************
//                               CHANNEL TEST
// *************************************************************************
use core::option::OptionTrait;
use core::starknet::SyscallResultTrait;
use core::result::ResultTrait;
use core::traits::{TryInto, Into};

use snforge_std::{
    declare, start_cheat_caller_address, stop_cheat_caller_address, spy_events,
    EventSpyAssertionsTrait, ContractClassTrait, DeclareResultTrait
};
use core::starknet::{ContractAddress, contract_address_const, get_block_timestamp};
use coloniz::channel::channel::ChannelComponent;
use coloniz::base::constants::types::{ChannelDetails};
use coloniz::mocks::interfaces::IChannelComposable::{
    IChannelComposableDispatcher, IChannelComposableDispatcherTrait
};

const HUB_ADDRESS: felt252 = 'HUB';
const ADMIN: felt252 = 'ADMIN';
const USER_ONE: felt252 = 'BOB';
const USER_TWO: felt252 = 'ALICE';
const USER_THREE: felt252 = 'ROB';
const USER_FOUR: felt252 = 'DAN';
const USER_FIVE: felt252 = 'RANDY';

fn __setup__() -> ContractAddress {
    let community_nft_class_hash = declare("CommunityNFT").unwrap().contract_class().class_hash;
    let channel_nft_class_hash = declare("ChannelNFT").unwrap().contract_class().class_hash;

    let channel_contract = declare("ColonizChannel").unwrap().contract_class();
    let mut channel_constructor_calldata = array![
        (*(channel_nft_class_hash)).into(), (*(community_nft_class_hash)).into()
    ];
    let (channel_contract_address, _) = channel_contract
        .deploy(@channel_constructor_calldata)
        .unwrap_syscall();
    return channel_contract_address;
}

#[test]
fn test_channel_creation() {
    let channel_contract_address = __setup__();
    let dispatcher = IChannelComposableDispatcher { contract_address: channel_contract_address };
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());

    let community_id = dispatcher.create_community();
    assert(community_id == 1, 'invalid community creation');

    let channel_id = dispatcher.create_channel(community_id);
    assert(channel_id == 1, 'invalid channel creation');
    stop_cheat_caller_address(channel_contract_address);

    let channel_details: ChannelDetails = dispatcher.get_channel(channel_id);
    assert(channel_details.channel_id == 1, 'invalid channel id');
    assert(channel_details.community_id == community_id, 'invalid community id');
    assert(channel_details.channel_owner == USER_ONE.try_into().unwrap(), 'invalid channel
 owner');
    assert(channel_details.channel_metadata_uri == "", 'invalid metadata uri');
    assert(channel_details.channel_total_members == 1, 'invalid total members');
    assert(channel_details.channel_censorship == false, 'invalid censorship status');
}

#[test]
fn test_create_channel_emits_events() {
    let channel_contract_address = __setup__();
    let dispatcher = IChannelComposableDispatcher { contract_address: channel_contract_address };
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let community_id = dispatcher.create_community();
    stop_cheat_caller_address(channel_contract_address);

    let mut spy = spy_events();
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let channel_id = dispatcher.create_channel(community_id);
    assert(channel_id == 1, 'invalid channel creation');
    let channel_details = dispatcher.get_channel(channel_id);
    spy
        .assert_emitted(
            @array![
                (
                    channel_contract_address,
                    ChannelComponent::Event::ChannelCreated(
                        ChannelComponent::ChannelCreated {
                            channel_id: channel_id,
                            channel_owner: USER_ONE.try_into().unwrap(),
                            channel_nft_address: channel_details.channel_nft_address,
                            block_timestamp: get_block_timestamp(),
                        }
                    )
                )
            ]
        );
}

#[test]
fn test_create_channel_by_community_member() {
    let channel_contract_address = __setup__();
    let dispatcher = IChannelComposableDispatcher { contract_address: channel_contract_address };
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let community_id = dispatcher.create_community();
    assert(community_id == 1, 'invalid community creation');

    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_community(community_id);
    let channel_id = dispatcher.create_channel(community_id);
    assert(channel_id == 1, 'invalid channel creation');
    stop_cheat_caller_address(channel_contract_address);

    let channel_details: ChannelDetails = dispatcher.get_channel(channel_id);
    assert(channel_details.channel_id == 1, 'invalid channel id');
    assert(channel_details.community_id == community_id, 'invalid community id');
    assert(channel_details.channel_owner == USER_TWO.try_into().unwrap(), 'invalid channel
 owner');
    assert(channel_details.channel_metadata_uri == "", 'invalid metadata uri');
    assert(channel_details.channel_total_members == 1, 'invalid total members');
    assert(channel_details.channel_censorship == false, 'invalid censorship status');
}

#[test]
#[should_panic(expected: ('coloniz: Not Community Member',))]
fn test_should_panic_if_channel_creator_is_not_community_member() {
    let channel_contract_address = __setup__();
    let dispatcher = IChannelComposableDispatcher { contract_address: channel_contract_address };
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let community_id = dispatcher.create_community();
    assert(community_id == 1, 'invalid community creation');

    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    // dispatcher.join_community(community_id);
    let channel_id = dispatcher.create_channel(community_id);
    assert(channel_id == 1, 'invalid channel creation');
    stop_cheat_caller_address(channel_contract_address);

    let channel_details: ChannelDetails = dispatcher.get_channel(channel_id);
    assert(channel_details.channel_id == 1, 'invalid channel id');
    assert(channel_details.community_id == community_id, 'invalid community id');
    assert(channel_details.channel_owner == USER_TWO.try_into().unwrap(), 'invalid channel
 owner');
    assert(channel_details.channel_metadata_uri == "", 'invalid metadata uri');
    assert(channel_details.channel_total_members == 1, 'invalid total members');
    assert(channel_details.channel_censorship == false, 'invalid censorship status');
}

#[test]
fn test_profile_can_join_channel() {
    let channel_contract_address = __setup__();
    let dispatcher = IChannelComposableDispatcher { contract_address: channel_contract_address };
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let community_id = dispatcher.create_community();
    let channel_id = dispatcher.create_channel(community_id);
    stop_cheat_caller_address(channel_contract_address);

    // join the community first
    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    // join channel
    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);
    let (is_member, channel_member) = dispatcher
        .is_channel_member(USER_TWO.try_into().unwrap(), channel_id);
    assert(is_member == true, 'Not Channel Member');

    assert(channel_member.profile == USER_TWO.try_into().unwrap(), 'Invalid Channel Member');
    assert(channel_member.channel_id == channel_id, 'Invalid Channel Id');
    assert(channel_member.total_publications == 0, 'Invalid Total Publication');
    assert(channel_member.channel_token_id != 0, 'Invalid nft mint token ');
}

#[test]
fn test_channel_nft_minted_to_profile_on_joining() {
    let channel_contract_address = __setup__();
    let dispatcher = IChannelComposableDispatcher { contract_address: channel_contract_address };

    // create a community
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let community_id = dispatcher.create_community();
    stop_cheat_caller_address(channel_contract_address);

    // create a channel
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let channel_id = dispatcher.create_channel(community_id);
    stop_cheat_caller_address(channel_contract_address);

    // join the community
    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    // join the channel
    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    // check that nft is minted to the profile
    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    let (_, channel_member) = dispatcher
        .is_channel_member(USER_TWO.try_into().unwrap(), channel_id);
    assert(channel_member.channel_token_id != 0, 'Invalid nft mint token ');
}

#[test]
fn test_channel_nft_is_burnt_on_leaving_channel() {
    let channel_contract_address = __setup__();
    let dispatcher = IChannelComposableDispatcher { contract_address: channel_contract_address };

    // create a community
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let community_id = dispatcher.create_community();
    stop_cheat_caller_address(channel_contract_address);

    // create a channel
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let channel_id = dispatcher.create_channel(community_id);
    stop_cheat_caller_address(channel_contract_address);

    // join the community
    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    // join the channel
    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    // leave the channel
    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.leave_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    let (_, channel_member) = dispatcher
        .is_channel_member(USER_TWO.try_into().unwrap(), channel_id);
    assert(channel_member.channel_token_id == 0, 'nft is burned ');
}

#[test]
#[should_panic(expected: ('coloniz: already a Member',))]
fn test_should_panic_if_a_user_joins_one_channel_twice() {
    let channel_contract_address = __setup__();
    let dispatcher = IChannelComposableDispatcher { contract_address: channel_contract_address };
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let community_id = dispatcher.create_community();
    let channel_id = dispatcher.create_channel(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);
}
#[test]
#[should_panic(expected: ('coloniz: banned from channel',))]
fn test_should_panic_if_banned_members_join_a_channel() {
    let channel_contract_address = __setup__();
    let dispatcher = IChannelComposableDispatcher { contract_address: channel_contract_address };
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let community_id = dispatcher.create_community();
    let channel_id = dispatcher.create_channel(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    dispatcher
        .set_channel_ban_status(channel_id, array![USER_TWO.try_into().unwrap()], array![true]);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);
}

#[test]
#[should_panic(expected: ('coloniz: banned from channel',))]
fn test_should_panic_if_banned_user_tries_to_leave_channel_and_then_rejoin() {
    let channel_contract_address = __setup__();
    let dispatcher = IChannelComposableDispatcher { contract_address: channel_contract_address };
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let community_id = dispatcher.create_community();
    let channel_id = dispatcher.create_channel(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    // banned
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    dispatcher
        .set_channel_ban_status(channel_id, array![USER_TWO.try_into().unwrap()], array![true]);
    stop_cheat_caller_address(channel_contract_address);

    // leave channel
    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.leave_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    // join channel again
    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_channel(channel_id);
}

#[test]
fn test_channel_total_members() {
    let channel_contract_address = __setup__();
    let dispatcher = IChannelComposableDispatcher { contract_address: channel_contract_address };
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let community_id = dispatcher.create_community();
    let channel_id = dispatcher.create_channel(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_THREE.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_THREE.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_FOUR.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_FOUR.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_FIVE.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_FIVE.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    let total_members = dispatcher.get_total_channel_members(channel_id);
    assert(total_members == 5, 'invalid total members');
}

#[test]
fn test_joining_channel_emits_event() {
    let channel_contract_address = __setup__();
    let dispatcher = IChannelComposableDispatcher { contract_address: channel_contract_address };
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let community_id = dispatcher.create_community();
    let channel_id = dispatcher.create_channel(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    let mut spy = spy_events();
    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    let (_, channel_member) = dispatcher
        .is_channel_member(USER_TWO.try_into().unwrap(), channel_id);
    spy
        .assert_emitted(
            @array![
                (
                    channel_contract_address,
                    ChannelComponent::Event::JoinedChannel(
                        ChannelComponent::JoinedChannel {
                            channel_id: channel_id,
                            transaction_executor: USER_TWO.try_into().unwrap(),
                            profile: channel_member.profile,
                            token_id: channel_member.channel_token_id,
                            block_timestamp: get_block_timestamp(),
                        }
                    )
                )
            ]
        );
}

#[test]
fn test_leave_channel() {
    let channel_contract_address = __setup__();
    let dispatcher = IChannelComposableDispatcher { contract_address: channel_contract_address };
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let community_id = dispatcher.create_community();
    let channel_id = dispatcher.create_channel(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.leave_channel(channel_id);
    let (is_member, channel_member) = dispatcher
        .is_channel_member(USER_TWO.try_into().unwrap(), channel_id);
    assert(is_member != true, 'still a Channel Member');
    stop_cheat_caller_address(channel_contract_address);
    let get_total_channel_members = dispatcher.get_total_channel_members(channel_id);
    assert(get_total_channel_members == 1, 'No reduction in total members');
    assert(channel_member.channel_token_id == 0, 'NFT is not burn ');
    assert(channel_member.total_publications == 0, 'Invalid Total Publication');
    assert(channel_member.profile == contract_address_const::<0>(), 'Invalid Channel Member');
    assert(channel_member.channel_id == 0, 'Invalid Channel Id');
}

#[test]
#[should_panic(expected: ('coloniz: not channel member',))]
fn test_should_panic_if_profile_leaving_is_not_a_member() {
    let channel_contract_address = __setup__();
    let dispatcher = IChannelComposableDispatcher { contract_address: channel_contract_address };
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let community_id = dispatcher.create_community();
    let channel_id = dispatcher.create_channel(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.leave_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);
}

#[test]
#[should_panic(expected: ('coloniz: channel has no members',))]
fn test_channel_have_members_before_leaving() {
    let channel_contract_address = __setup__();
    let dispatcher = IChannelComposableDispatcher { contract_address: channel_contract_address };

    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let community_id = dispatcher.create_community();
    let channel_id = dispatcher.create_channel(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    dispatcher.leave_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);
}

#[test]
fn test_leave_channel_emits_event() {
    let channel_contract_address = __setup__();
    let dispatcher = IChannelComposableDispatcher { contract_address: channel_contract_address };
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let community_id = dispatcher.create_community();
    let channel_id = dispatcher.create_channel(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    let mut spy = spy_events();
    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    let (_, channel_member) = dispatcher
        .is_channel_member(USER_TWO.try_into().unwrap(), channel_id);
    let channel_token_id = channel_member.channel_token_id;
    dispatcher.leave_channel(channel_id);
    spy
        .assert_emitted(
            @array![
                (
                    channel_contract_address,
                    ChannelComponent::Event::LeftChannel(
                        ChannelComponent::LeftChannel {
                            channel_id: channel_id,
                            transaction_executor: USER_TWO.try_into().unwrap(),
                            profile: USER_TWO.try_into().unwrap(),
                            token_id: channel_token_id,
                            block_timestamp: get_block_timestamp(),
                        }
                    )
                )
            ]
        );
}

#[test]
fn test_channel_metadata_uri_with_owner() {
    let channel_contract_address = __setup__();
    let dispatcher = IChannelComposableDispatcher { contract_address: channel_contract_address };
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let community_id = dispatcher.create_community();
    let channel_id = dispatcher.create_channel(community_id);
    stop_cheat_caller_address(channel_contract_address);

    let metadat_uri: ByteArray = "ipfs://demo";
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    dispatcher.set_channel_metadata_uri(channel_id, metadat_uri.clone());
    stop_cheat_caller_address(channel_contract_address);
    let channel_metadata_uri = dispatcher.get_channel_metadata_uri(channel_id);
    assert(channel_metadata_uri == metadat_uri, 'invalid channel uri ');
}

#[test]
fn test_set_channel_metadata_with_moderator() {
    let channel_contract_address = __setup__();
    let dispatcher = IChannelComposableDispatcher { contract_address: channel_contract_address };
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let community_id = dispatcher.create_community();
    let channel_id = dispatcher.create_channel(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    dispatcher.add_channel_mods(channel_id, array![USER_TWO.try_into().unwrap()]);
    stop_cheat_caller_address(channel_contract_address);

    let metadat_uri: ByteArray = "ipfs://demo";
    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.set_channel_metadata_uri(channel_id, metadat_uri.clone());
    stop_cheat_caller_address(channel_contract_address);

    let channel_metadata_uri = dispatcher.get_channel_metadata_uri(channel_id);
    assert(channel_metadata_uri == metadat_uri, 'invalid channel uri ');
}

#[test]
#[should_panic(expected: ('coloniz: user unauthorized!',))]
fn test_set_metadata_should_panic_if_caller_is_not_owner_or_moderator() {
    let channel_contract_address = __setup__();
    let dispatcher = IChannelComposableDispatcher { contract_address: channel_contract_address };
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let community_id = dispatcher.create_community();
    let channel_id = dispatcher.create_channel(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    let metadat_uri: ByteArray = "ipfs://demo";
    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.set_channel_metadata_uri(channel_id, metadat_uri.clone());
    stop_cheat_caller_address(channel_contract_address);
}

#[test]
fn test_add_channel_mods() {
    let channel_contract_address = __setup__();
    let dispatcher = IChannelComposableDispatcher { contract_address: channel_contract_address };
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let community_id = dispatcher.create_community();
    let channel_id = dispatcher.create_channel(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_THREE.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_THREE.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    let mut moderator_array = array![USER_TWO.try_into().unwrap(), USER_THREE.try_into().unwrap()];
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    dispatcher.add_channel_mods(channel_id, moderator_array);
    stop_cheat_caller_address(channel_contract_address);

    assert(
        dispatcher.is_channel_mod(USER_TWO.try_into().unwrap(), channel_id) == true,
        'user_two is not mod'
    );
    assert(
        dispatcher.is_channel_mod(USER_THREE.try_into().unwrap(), channel_id) == true,
        'user_three isnt mod'
    );
}

#[test]
#[should_panic(expected: ('coloniz: not channel owner',))]
fn test_only_owner_can_add_channel_mod() {
    let channel_contract_address = __setup__();
    let dispatcher = IChannelComposableDispatcher { contract_address: channel_contract_address };
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let community_id = dispatcher.create_community();
    let channel_id = dispatcher.create_channel(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_THREE.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_THREE.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_FOUR.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_FOUR.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    let mut moderator_array = array![USER_TWO.try_into().unwrap(), USER_THREE.try_into().unwrap()];
    start_cheat_caller_address(channel_contract_address, USER_FOUR.try_into().unwrap());
    dispatcher.add_channel_mods(channel_id, moderator_array);
    stop_cheat_caller_address(channel_contract_address);
}

#[test]
#[should_panic(expected: ('coloniz: not channel member',))]
fn test_should_panic_if_mod_is_not_member() {
    let channel_contract_address = __setup__();
    let dispatcher = IChannelComposableDispatcher { contract_address: channel_contract_address };
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let community_id = dispatcher.create_community();
    let channel_id = dispatcher.create_channel(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    let mut moderator_array = array![USER_TWO.try_into().unwrap()];

    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    dispatcher.add_channel_mods(channel_id, moderator_array);
    stop_cheat_caller_address(channel_contract_address);
}

#[test]
fn test_add_channel_mods_emits_event() {
    let channel_contract_address = __setup__();
    let dispatcher = IChannelComposableDispatcher { contract_address: channel_contract_address };
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let community_id = dispatcher.create_community();
    let channel_id = dispatcher.create_channel(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);
    let mut spy = spy_events();
    let mut moderator_array = array![USER_TWO.try_into().unwrap()];
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    dispatcher.add_channel_mods(channel_id, moderator_array.clone());
    spy
        .assert_emitted(
            @array![
                (
                    channel_contract_address,
                    ChannelComponent::Event::ChannelModAdded(
                        ChannelComponent::ChannelModAdded {
                            channel_id: channel_id,
                            transaction_executor: USER_ONE.try_into().unwrap(),
                            mod_address: *moderator_array[0],
                            block_timestamp: get_block_timestamp(),
                        }
                    )
                )
            ]
        );
}

#[test]
fn test_remove_channel_mods() {
    let channel_contract_address = __setup__();
    let dispatcher = IChannelComposableDispatcher { contract_address: channel_contract_address };
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let community_id = dispatcher.create_community();
    let channel_id = dispatcher.create_channel(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_THREE.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_THREE.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    let mut moderator_array = array![USER_TWO.try_into().unwrap(), USER_THREE.try_into().unwrap()];
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    dispatcher.add_channel_mods(channel_id, moderator_array);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    dispatcher.remove_channel_mods(channel_id, array![USER_TWO.try_into().unwrap()]);
    stop_cheat_caller_address(channel_contract_address);

    assert(
        dispatcher.is_channel_mod(USER_TWO.try_into().unwrap(), channel_id) == false,
        'Channel Mod Not Remove'
    );
}

#[test]
#[should_panic(expected: ('coloniz: not channel owner',))]
fn test_only_owner_can_remove_channel_mod() {
    let channel_contract_address = __setup__();
    let dispatcher = IChannelComposableDispatcher { contract_address: channel_contract_address };
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let community_id = dispatcher.create_community();
    let channel_id = dispatcher.create_channel(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_THREE.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_THREE.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    let mut moderator_array = array![USER_TWO.try_into().unwrap(), USER_THREE.try_into().unwrap()];
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    dispatcher.add_channel_mods(channel_id, moderator_array);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_FOUR.try_into().unwrap());
    dispatcher.remove_channel_mods(channel_id, array![USER_TWO.try_into().unwrap()]);
    stop_cheat_caller_address(channel_contract_address);
}

#[test]
#[should_panic(expected: ('coloniz: not channel moderator',))]
fn test_should_panic_if_profile_to_be_removed_is_not_mod() {
    let channel_contract_address = __setup__();
    let dispatcher = IChannelComposableDispatcher { contract_address: channel_contract_address };
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let community_id = dispatcher.create_community();
    let channel_id = dispatcher.create_channel(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_THREE.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_THREE.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_FOUR.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_FOUR.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    let mut moderator_array = array![USER_TWO.try_into().unwrap(), USER_FOUR.try_into().unwrap()];
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    dispatcher.add_channel_mods(channel_id, moderator_array);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    dispatcher
        .remove_channel_mods(
            channel_id, array![USER_THREE.try_into().unwrap(), USER_FOUR.try_into().unwrap()]
        );
}

#[test]
fn test_remove_channel_mod_emit_event() {
    let channel_contract_address = __setup__();
    let dispatcher = IChannelComposableDispatcher { contract_address: channel_contract_address };
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let community_id = dispatcher.create_community();
    let channel_id = dispatcher.create_channel(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_THREE.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_THREE.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    let mut moderator_array = array![USER_TWO.try_into().unwrap(), USER_THREE.try_into().unwrap()];
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    dispatcher.add_channel_mods(channel_id, moderator_array);
    stop_cheat_caller_address(channel_contract_address);

    let mut spy = spy_events();
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    dispatcher.remove_channel_mods(channel_id, array![USER_TWO.try_into().unwrap()]);
    spy
        .assert_emitted(
            @array![
                (
                    channel_contract_address,
                    ChannelComponent::Event::ChannelModRemoved(
                        ChannelComponent::ChannelModRemoved {
                            channel_id: channel_id,
                            mod_address: USER_TWO.try_into().unwrap(),
                            transaction_executor: USER_ONE.try_into().unwrap(),
                            block_timestamp: get_block_timestamp(),
                        }
                    )
                )
            ]
        );
}

#[test]
fn test_set_channel_censorship_status() {
    let channel_contract_address = __setup__();
    let dispatcher = IChannelComposableDispatcher { contract_address: channel_contract_address };
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let community_id = dispatcher.create_community();
    let channel_id = dispatcher.create_channel(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    dispatcher.set_channel_censorship_status(channel_id, true);
    stop_cheat_caller_address(channel_contract_address);

    let censorship_status = dispatcher.get_channel_censorship_status(channel_id);
    assert(censorship_status == true, 'invalid censorship status');
}

#[test]
#[should_panic(expected: ('coloniz: not channel owner',))]
fn test_set_channel_censorship_status_not_owner() {
    let channel_contract_address = __setup__();
    let dispatcher = IChannelComposableDispatcher { contract_address: channel_contract_address };
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let community_id = dispatcher.create_community();
    let channel_id = dispatcher.create_channel(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.set_channel_censorship_status(channel_id, true);
}

#[test]
fn test_set_ban_status_by_owner() {
    let channel_contract_address = __setup__();
    let dispatcher = IChannelComposableDispatcher { contract_address: channel_contract_address };
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let community_id = dispatcher.create_community();
    let channel_id = dispatcher.create_channel(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_THREE.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_THREE.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    let mut profiles = ArrayTrait::new();
    profiles.append(USER_TWO.try_into().unwrap());
    profiles.append(USER_THREE.try_into().unwrap());

    let mut ban_statuses = ArrayTrait::new();
    ban_statuses.append(true);
    ban_statuses.append(true);

    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    dispatcher.set_channel_ban_status(channel_id, profiles, ban_statuses);
    stop_cheat_caller_address(channel_contract_address);

    let ban_status = dispatcher.get_channel_ban_status(USER_TWO.try_into().unwrap(), channel_id);
    assert(ban_status == true, 'Channel Member is not ban');
    stop_cheat_caller_address(channel_contract_address);
}

#[test]
fn test_set_ban_status_by_mod() {
    let channel_contract_address = __setup__();
    let dispatcher = IChannelComposableDispatcher { contract_address: channel_contract_address };
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let community_id = dispatcher.create_community();
    let channel_id = dispatcher.create_channel(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_THREE.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_THREE.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    let mut moderator_array = array![USER_TWO.try_into().unwrap()];
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    dispatcher.add_channel_mods(channel_id, moderator_array.clone());
    stop_cheat_caller_address(channel_contract_address);

    let mut profiles = ArrayTrait::new();
    profiles.append(USER_THREE.try_into().unwrap());

    let mut ban_statuses = ArrayTrait::new();
    ban_statuses.append(true);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.set_channel_ban_status(channel_id, profiles, ban_statuses);
    stop_cheat_caller_address(channel_contract_address);

    let ban_status = dispatcher.get_channel_ban_status(USER_THREE.try_into().unwrap(), channel_id);
    assert(ban_status == true, 'Channel Member is not ban');
    stop_cheat_caller_address(channel_contract_address);
}

#[test]
fn test_set_ban_status_emit_event() {
    let channel_contract_address = __setup__();
    let dispatcher = IChannelComposableDispatcher { contract_address: channel_contract_address };
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let community_id = dispatcher.create_community();
    let channel_id = dispatcher.create_channel(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    let mut profiles = ArrayTrait::new();
    profiles.append(USER_TWO.try_into().unwrap());

    let mut ban_statuses = ArrayTrait::new();
    ban_statuses.append(true);

    let mut spy = spy_events();
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    dispatcher.set_channel_ban_status(channel_id, profiles, ban_statuses);

    spy
        .assert_emitted(
            @array![
                (
                    channel_contract_address,
                    ChannelComponent::Event::ChannelBanStatusUpdated(
                        ChannelComponent::ChannelBanStatusUpdated {
                            channel_id: channel_id,
                            transaction_executor: USER_ONE.try_into().unwrap(),
                            profile: USER_TWO.try_into().unwrap(),
                            ban_status: true,
                            block_timestamp: get_block_timestamp()
                        }
                    )
                )
            ]
        );
}

#[test]
#[should_panic(expected: ('coloniz: user unauthorized!',))]
fn test_should_panic_if_caller_to_set_ban_status_is_not_owner_or_mod() {
    let channel_contract_address = __setup__();
    let dispatcher = IChannelComposableDispatcher { contract_address: channel_contract_address };
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let community_id = dispatcher.create_community();
    let channel_id = dispatcher.create_channel(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_THREE.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_THREE.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    let mut profiles = ArrayTrait::new();
    profiles.append(USER_TWO.try_into().unwrap());
    profiles.append(USER_THREE.try_into().unwrap());

    let mut ban_statuses = ArrayTrait::new();
    ban_statuses.append(true);
    ban_statuses.append(true);

    start_cheat_caller_address(channel_contract_address, USER_FOUR.try_into().unwrap());
    dispatcher.set_channel_ban_status(channel_id, profiles, ban_statuses);
}

#[test]
#[should_panic(expected: ('coloniz: not channel member',))]
fn test_can_only_set_ban_status_for_members() {
    let channel_contract_address = __setup__();
    let dispatcher = IChannelComposableDispatcher { contract_address: channel_contract_address };
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let community_id = dispatcher.create_community();
    let channel_id = dispatcher.create_channel(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    let mut profiles = ArrayTrait::new();
    profiles.append(USER_TWO.try_into().unwrap());
    profiles.append(USER_THREE.try_into().unwrap());

    let mut ban_statuses = ArrayTrait::new();
    ban_statuses.append(true);
    ban_statuses.append(true);

    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    dispatcher.set_channel_ban_status(channel_id, profiles, ban_statuses);
}

#[test]
#[should_panic(expected: ('coloniz: array mismatch',))]
fn test_should_not_set_ban_status_for_invalid_array_length() {
    let channel_contract_address = __setup__();
    let dispatcher = IChannelComposableDispatcher { contract_address: channel_contract_address };
    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    let community_id = dispatcher.create_community();
    let channel_id = dispatcher.create_channel(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_community(community_id);
    stop_cheat_caller_address(channel_contract_address);

    start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
    dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(channel_contract_address);

    let mut profiles = ArrayTrait::new();
    profiles.append(USER_TWO.try_into().unwrap());

    let mut ban_statuses = ArrayTrait::new();
    ban_statuses.append(true);
    ban_statuses.append(true);

    start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
    dispatcher.set_channel_ban_status(channel_id, profiles, ban_statuses);
}

