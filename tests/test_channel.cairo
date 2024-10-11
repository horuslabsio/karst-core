// // *************************************************************************
// //                               CHANNEL TEST
// // *************************************************************************
// use core::option::OptionTrait;
// use core::starknet::SyscallResultTrait;
// use core::result::ResultTrait;
// use core::traits::{TryInto, Into};
// use starknet::ContractAddress;

// use snforge_std::{
//     declare, start_cheat_caller_address, stop_cheat_caller_address, spy_events,
//     EventSpyAssertionsTrait, ContractClassTrait, DeclareResultTrait, EventSpy
// };

// use karst::channel::channel::ChannelComponent::{
//     Event as ChannelEvent, ChannelCreated, JoinedChannel, LeftChannel, ChannelModAdded,
//     ChannelModRemoved, ChannelBanStatusUpdated
// };
// use karst::base::constants::types::{channelParams, channelMember};
// use karst::interfaces::IChannel::{IChannelDispatcher, IChannelDispatcherTrait};
// use karst::presets::channel;

// const HUB_ADDRESS: felt252 = 'HUB';
// const USER_ONE: felt252 = 'BOB';
// const USER_TWO: felt252 = 'ALICE';
// // these are the channel users
// const USER_THREE: felt252 = 'ROB';
// const USER_FOUR: felt252 = 'DAN';
// const USER_FIVE: felt252 = 'RANDY';
// const USER_SIX: felt252 = 'JOE';
// const MODERATOR1: felt252 = 'MOD1';
// const MODERATOR2: felt252 = 'MOD2';
// const NOTOWNER: felt252 = 'NOTOWNER';
// const NOTMODERATOR: felt252 = 'NOTMODERATOR';
// const MEMBER1: felt252 = 'MEMBER1';
// const MEMBER2: felt252 = 'MEMBER2';

// fn __setup__() -> (ContractAddress, u256, ContractAddress, ByteArray) {
//     let nft_contract = declare("KarstNFT").unwrap().contract_class();
//     let mut calldata: Array<felt252> = array![USER_ONE];

//     let (nft_contract_address, _) = nft_contract.deploy(@calldata).unwrap_syscall();

//     let registry_class_hash = declare("Registry").unwrap().contract_class();
//     let (registry_contract_address, _) = registry_class_hash.deploy(@array![]).unwrap_syscall();

//     let channel_contract = declare("KarstChannel").unwrap().contract_class();

//     let mut channel_constructor_calldata = array![];

//     let (channel_contract_address, _) = channel_contract
//         .deploy(@channel_constructor_calldata)
//         .unwrap_syscall();
//     let account_class_hash = declare("Account").unwrap().contract_class();
//     let follow_nft_classhash = declare("Follow").unwrap().contract_class();
//     let collect_nft_classhash = declare("CollectNFT").unwrap().contract_class();
//     let dispatcher = IChannelDispatcher { contract_address: channel_contract_address };
//     start_cheat_caller_address(channel_contract_address, USER_ONE.try_into().unwrap());
//     let mut spy = spy_events();
//     let metadat_uri: ByteArray = "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaYXr4gQ/";
//     let channel_id: u256 = dispatcher
//         .create_channel(
//             channelParams {
//                 channel_id: 0,
//                 channel_owner: USER_ONE.try_into().unwrap(),
//                 channel_metadata_uri: metadat_uri.clone(),
//                 channel_nft_address: nft_contract_address,
//                 channel_total_members: 1,
//                 channel_censorship: false,
//             }
//         );
//     let mut moderator_array = array![
//         MODERATOR1.try_into().unwrap(), MODERATOR2.try_into().unwrap()
//     ];
//     dispatcher.add_channel_mods(channel_id, moderator_array);
//     stop_cheat_caller_address(channel_contract_address);

//     start_cheat_caller_address(channel_contract_address, MEMBER1.try_into().unwrap());
//     dispatcher.join_channel(channel_id);
//     stop_cheat_caller_address(channel_contract_address);

//     start_cheat_caller_address(channel_contract_address, MEMBER2.try_into().unwrap());
//     dispatcher.join_channel(channel_id);
//     stop_cheat_caller_address(channel_contract_address);
//     return (channel_contract_address, channel_id, USER_ONE.try_into().unwrap(), metadat_uri);
// }

// // writing the test for the set_channel_metadata_uri :
// #[test]
// fn test_set_channel_metadata_uri_check_owner() {
//     let (channel_contract_address, channel_id, owner, metadata_uri) = __setup__();
//     let dispatcher = IChannelDispatcher { contract_address: channel_contract_address };
//     let metadat_uri: ByteArray = "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaYXr4gH/";
//     start_cheat_caller_address(channel_contract_address, owner);
//     dispatcher.set_channel_metadata_uri(channel_id, metadat_uri.clone());
//     stop_cheat_caller_address(channel_contract_address);
//     let channel_metadata_uri = dispatcher.get_channel_metadata_uri(channel_id);
//     assert(channel_metadata_uri == metadat_uri, 'invalid channel uri ');
// }

// #[test]
// fn test_set_channel_metadata_uri_check_moderator() {
//     let (channel_contract_address, channel_id, owner, metadata_uri) = __setup__();
//     let dispatcher = IChannelDispatcher { contract_address: channel_contract_address };
//     let metadat_uri: ByteArray = "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaYXr4gH/";
//     start_cheat_caller_address(channel_contract_address, MODERATOR1.try_into().unwrap());
//     dispatcher.set_channel_metadata_uri(channel_id, metadat_uri.clone());
//     stop_cheat_caller_address(channel_contract_address);
//     // check the metadata uri
//     let channel_metadata_uri = dispatcher.get_channel_metadata_uri(channel_id);
//     assert(channel_metadata_uri == metadat_uri, 'invalid channel uri ');
// }

// #[test]
// #[should_panic(expected: ('Karst : Unauthorized access',))]
// fn test_set_channel_metadata_uri_check_not_owner_or_moderator() {
//     let (channel_contract_address, channel_id, owner, metadata_uri) = __setup__();
//     let dispatcher = IChannelDispatcher { contract_address: channel_contract_address };
//     let metadat_uri: ByteArray = "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaYXr4gH/";
//     start_cheat_caller_address(channel_contract_address, NOTOWNER.try_into().unwrap());
//     dispatcher.set_channel_metadata_uri(channel_id, metadat_uri.clone());
//     stop_cheat_caller_address(channel_contract_address);
// }

// // writing the test for the add_channel_mods()
// #[test]
// fn test_add_channel_mods_owner() {
//     let (channel_contract_address, channel_id, owner, metadata_uri) = __setup__();
//     let dispatcher = IChannelDispatcher { contract_address: channel_contract_address };
//     let mut moderator_array = array![
//         MODERATOR1.try_into().unwrap(), MODERATOR2.try_into().unwrap()
//     ];
//     start_cheat_caller_address(channel_contract_address, owner);
//     dispatcher.add_channel_mods(channel_id, moderator_array);
//     stop_cheat_caller_address(channel_contract_address);
//     // check the moderator
//     assert(
//         dispatcher.is_channel_mod(MODERATOR1.try_into().unwrap(), channel_id) == true,
//         'user_two is not mod'
//     );
//     assert(
//         dispatcher.is_channel_mod(MODERATOR2.try_into().unwrap(), channel_id) == true,
//         'user_three isnt mod'
//     );
// }

// #[test]
// #[should_panic(expected: ('Channel: not channel owner',))]
// fn test_add_channel_mods_not_owner() {
//     let (channel_contract_address, channel_id, owner, metadata_uri) = __setup__();
//     let dispatcher = IChannelDispatcher { contract_address: channel_contract_address };
//     let mut moderator_array = array![
//         MODERATOR1.try_into().unwrap(), MODERATOR2.try_into().unwrap()
//     ];
//     start_cheat_caller_address(channel_contract_address, NOTOWNER.try_into().unwrap());
//     dispatcher.add_channel_mods(channel_id, moderator_array);
//     stop_cheat_caller_address(channel_contract_address);
// }

// // total number of the moderator fucntion is usefull .
// // then this test is usefull
// // #[test]
// // fn test_add_channel_mods_duplicate_moderator() {
// //     let (channel_contract_address , channel_id , owner , metadata_uri ) = __setup__();
// //     let dispatcher = IChannelDispatcher { contract_address: channel_contract_address };
// //     let mut moderator_array = array![MODERATOR1.try_into().unwrap() ,
// //     MODERATOR1.try_into().unwrap()];
// //     start_cheat_caller_address(channel_contract_address , owner);
// //     dispatcher.add_channel_mods(channel_id , moderator_array);
// //     stop_cheat_caller_address(channel_contract_address);
// //     // check the moderator
// //     assert(
// //         dispatcher.is_channel_mod(MODERATOR1.try_into().unwrap(), channel_id) == true,
// //         'user_two is not mod'
// //     );
// //     assert(
// //         dispatcher.is_channel_mod(MODERATOR2.try_into().unwrap(), channel_id) == true,
// //         'user_three isnt mod'
// //     );

// //     // add the moderator again
// //     start_cheat_caller_address(channel_contract_address , owner);
// //     dispatcher.add_channel_mods(channel_id , moderator_array);
// //     stop_cheat_caller_address(channel_contract_address);
// //     // check the moderator
// //     let total_mod = dispatcher.total_mod_of_channel(channel_id);

// //     assert(
// //         total_mod.len() == 2 ,
// //         'user_two is not mod'
// //     );
// // }

// // now writing the test for the remove channel mods
// #[test]
// fn test_remove_channel_mods_owner() {
//     let (channel_contract_address, channel_id, owner, metadata_uri) = __setup__();
//     let dispatcher = IChannelDispatcher { contract_address: channel_contract_address };
//     let mut moderator_array = array![
//         MODERATOR1.try_into().unwrap(), MODERATOR2.try_into().unwrap()
//     ];
//     start_cheat_caller_address(channel_contract_address, owner);
//     dispatcher.add_channel_mods(channel_id, moderator_array);
//     stop_cheat_caller_address(channel_contract_address);

//     // remove the moderator
//     start_cheat_caller_address(channel_contract_address, owner);
//     dispatcher.remove_channel_mods(channel_id, array![MODERATOR1.try_into().unwrap()]);
//     stop_cheat_caller_address(channel_contract_address);
//     // check the moderator
//     assert(
//         dispatcher.is_channel_mod(MODERATOR1.try_into().unwrap(), channel_id) == false,
//         'user_two is not mod'
//     );
//     assert(
//         dispatcher.is_channel_mod(MODERATOR2.try_into().unwrap(), channel_id) == true,
//         'user_three isnt mod'
//     );
// }

// // not the owner of the channel
// #[test]
// #[should_panic(expected: ('Channel: not channel owner',))]
// fn test_remove_channel_mods_not_owner() {
//     let (channel_contract_address, channel_id, owner, metadata_uri) = __setup__();
//     let dispatcher = IChannelDispatcher { contract_address: channel_contract_address };
//     let mut moderator_array = array![
//         MODERATOR1.try_into().unwrap(), MODERATOR2.try_into().unwrap()
//     ];
//     start_cheat_caller_address(channel_contract_address, owner);
//     dispatcher.add_channel_mods(channel_id, moderator_array);
//     stop_cheat_caller_address(channel_contract_address);

//     // remove the moderator
//     start_cheat_caller_address(channel_contract_address, NOTOWNER.try_into().unwrap());
//     dispatcher.remove_channel_mods(channel_id, array![MODERATOR1.try_into().unwrap()]);
//     stop_cheat_caller_address(channel_contract_address);
//     // check the moderator
//     assert(
//         dispatcher.is_channel_mod(MODERATOR1.try_into().unwrap(), channel_id) == true,
//         'user_two is not mod'
//     );
//     assert(
//         dispatcher.is_channel_mod(MODERATOR2.try_into().unwrap(), channel_id) == true,
//         'user_three isnt mod'
//     );
// }
// // also test the moderator is not in the channel
// #[test]
// fn test_remove_channel_mods_not_moderator() {
//     let (channel_contract_address, channel_id, owner, metadata_uri) = __setup__();
//     let dispatcher = IChannelDispatcher { contract_address: channel_contract_address };
//     let mut moderator_array = array![
//         MODERATOR1.try_into().unwrap(), MODERATOR2.try_into().unwrap()
//     ];
//     start_cheat_caller_address(channel_contract_address, owner);
//     dispatcher.add_channel_mods(channel_id, moderator_array);
//     stop_cheat_caller_address(channel_contract_address);

//     // remove the moderator
//     start_cheat_caller_address(channel_contract_address, owner);
//     dispatcher
//         .remove_channel_mods(
//             channel_id, array![NOTMODERATOR.try_into().unwrap(), MODERATOR2.try_into().unwrap()]
//         );
//     stop_cheat_caller_address(channel_contract_address);
//     // check the moderator

//     assert(
//         dispatcher.is_channel_mod(MODERATOR1.try_into().unwrap(), channel_id) == true,
//         'user_two is not mod'
//     );
//     assert(
//         dispatcher.is_channel_mod(MODERATOR2.try_into().unwrap(), channel_id) == false,
//         'user_three isnt mod'
//     );
// }

// // checking about the persistance  state of the moderator
// #[test]
// fn test_remove_channel_mods_persistance_state() {
//     let (channel_contract_address, channel_id, owner, metadata_uri) = __setup__();
//     let dispatcher = IChannelDispatcher { contract_address: channel_contract_address };
//     let mut moderator_array = array![
//         MODERATOR1.try_into().unwrap(), MODERATOR2.try_into().unwrap()
//     ];
//     start_cheat_caller_address(channel_contract_address, owner);
//     dispatcher.add_channel_mods(channel_id, moderator_array.clone());
//     dispatcher.remove_channel_mods(channel_id, moderator_array.clone());
//     stop_cheat_caller_address(channel_contract_address);
//     // check the moderator
//     assert(
//         dispatcher.is_channel_mod(MODERATOR1.try_into().unwrap(), channel_id) == false,
//         'user_two is not mod'
//     );
//     assert(
//         dispatcher.is_channel_mod(MODERATOR2.try_into().unwrap(), channel_id) == false,
//         'user_three isnt mod'
//     );
// }

// // set censorship to test
// #[test]
// fn test_set_channel_censorship_status_owner() {
//     let (channel_contract_address, channel_id, owner, metadata_uri) = __setup__();
//     let dispatcher = IChannelDispatcher { contract_address: channel_contract_address };
//     start_cheat_caller_address(channel_contract_address, owner);
//     dispatcher.set_channel_censorship_status(channel_id, true);
//     stop_cheat_caller_address(channel_contract_address);
//     // check the censorship status
//     let censorship_status = dispatcher.get_channel_censorship_status(channel_id);
//     assert(censorship_status == true, 'invalid censorship status');
// }
// // not owner of the channel
// #[test]
// #[should_panic(expected: ('Channel: not channel owner',))]
// fn test_set_channel_censorship_status_not_owner() {
//     let (channel_contract_address, channel_id, owner, metadata_uri) = __setup__();
//     let dispatcher = IChannelDispatcher { contract_address: channel_contract_address };
//     start_cheat_caller_address(channel_contract_address, NOTOWNER.try_into().unwrap());
//     dispatcher.set_channel_censorship_status(channel_id, true);
//     stop_cheat_caller_address(channel_contract_address);
//     // check the censorship status
//     let censorship_status = dispatcher.get_channel_censorship_status(channel_id);
//     assert(censorship_status == true, 'invalid censorship status');
// }

// // test for set_ban_status
// #[test]
// fn test_set_ban_status_owner() {
//     let (channel_contract_address, channel_id, owner, metadata_uri) = __setup__();
//     let dispatcher = IChannelDispatcher { contract_address: channel_contract_address };

//     start_cheat_caller_address(channel_contract_address, owner);
//     dispatcher.set_ban_status(channel_id, MEMBER1.try_into().unwrap(), true);
//     stop_cheat_caller_address(channel_contract_address);
//     // check the ban status
//     let ban_status = dispatcher.get_ban_status(MEMBER1.try_into().unwrap(), channel_id);
//     assert(ban_status == true, 'invalid ban status');
// }

// #[test]
// #[should_panic(expected: ('Karst : Unauthorized access',))]
// fn test_set_ban_status_owner_or_moderator() {
//     let (channel_contract_address, channel_id, owner, metadata_uri) = __setup__();
//     let dispatcher = IChannelDispatcher { contract_address: channel_contract_address };

//     start_cheat_caller_address(channel_contract_address, NOTOWNER.try_into().unwrap());

//     dispatcher.set_ban_status(channel_id, MEMBER1.try_into().unwrap(), true);
//     stop_cheat_caller_address(channel_contract_address);
// }

// #[test]
// #[should_panic(expected: ('Channel: not channel member',))]
// fn test_set_ban_status_profile_is_not_member() {
//     let (channel_contract_address, channel_id, owner, metadata_uri) = __setup__();
//     let dispatcher = IChannelDispatcher { contract_address: channel_contract_address };
//     start_cheat_caller_address(channel_contract_address, owner);
//     dispatcher.set_ban_status(channel_id, USER_THREE.try_into().unwrap(), true);
//     stop_cheat_caller_address(channel_contract_address);
// }

// #[test]
// fn test_leave_channel_member() {
//     let (channel_contract_address, channel_id, owner, _) = __setup__();
//     let dispatcher = IChannelDispatcher { contract_address: channel_contract_address };

//     start_cheat_caller_address(channel_contract_address, MEMBER1.try_into().unwrap());
//     dispatcher.leave_channel(channel_id);
//     stop_cheat_caller_address(channel_contract_address);

//     // not the member of that
//     assert(
//         !dispatcher.is_channel_member(MEMBER1.try_into().unwrap(), channel_id) == true,
//         'channel not leaved'
//     );
// }

// #[test]
// #[should_panic(expected: ('Channel: not channel member',))]
// fn test_leave_channel_not_member() {
//     let (channel_contract_address, channel_id, owner, _) = __setup__();
//     let dispatcher = IChannelDispatcher { contract_address: channel_contract_address };

//     start_cheat_caller_address(channel_contract_address, USER_FOUR.try_into().unwrap());
//     dispatcher.leave_channel(channel_id);
//     stop_cheat_caller_address(channel_contract_address);
// }

// // joining the channel testing
// #[test]
// fn test_joining_channel() {
//     let (channel_contract_address, channel_id, owner, _) = __setup__();
//     let dispatcher = IChannelDispatcher { contract_address: channel_contract_address };

//     let is_channel_member = dispatcher.is_channel_member(MEMBER1.try_into().unwrap(),
//     channel_id);
//     assert(is_channel_member == true, 'invalid channel member 1');

//     let is_channel_member = dispatcher.is_channel_member(MEMBER2.try_into().unwrap(),
//     channel_id);
//     assert(is_channel_member == true, 'invalid channel member 2');
// }

// // // counting of the member of the channel .
// #[test]
// fn test_joining_channel_total_members() {
//     let (channel_contract_address, channel_id, owner, _) = __setup__();
//     let dispatcher = IChannelDispatcher { contract_address: channel_contract_address };

//     // join the channel
//     start_cheat_caller_address(channel_contract_address, USER_TWO.try_into().unwrap());
//     dispatcher.join_channel(channel_id);
//     stop_cheat_caller_address(channel_contract_address);

//     // join the channel
//     start_cheat_caller_address(channel_contract_address, USER_THREE.try_into().unwrap());
//     dispatcher.join_channel(channel_id);
//     stop_cheat_caller_address(channel_contract_address);

//     // join the channel
//     start_cheat_caller_address(channel_contract_address, USER_FOUR.try_into().unwrap());
//     dispatcher.join_channel(channel_id);
//     stop_cheat_caller_address(channel_contract_address);

//     // join the channel
//     start_cheat_caller_address(channel_contract_address, USER_FIVE.try_into().unwrap());
//     dispatcher.join_channel(channel_id);
//     stop_cheat_caller_address(channel_contract_address);

//     // join the channel
//     start_cheat_caller_address(channel_contract_address, USER_SIX.try_into().unwrap());
//     dispatcher.join_channel(channel_id);
//     stop_cheat_caller_address(channel_contract_address);

//     // check the total member of the channel
//     let total_members = dispatcher.get_total_members(channel_id);
//     assert(total_members == 7, 'invalid total members');
// }

// #[test]
// #[should_panic(expected: ('Channel has no members',))]
// fn test_leave_channel_less_then_one() {
//     let (channel_contract_address, channel_id, owner, _) = __setup__();
//     let dispatcher = IChannelDispatcher { contract_address: channel_contract_address };

//     start_cheat_caller_address(channel_contract_address, MEMBER1.try_into().unwrap());
//     dispatcher.leave_channel(channel_id);
//     stop_cheat_caller_address(channel_contract_address);

//     start_cheat_caller_address(channel_contract_address, MEMBER2.try_into().unwrap());
//     dispatcher.leave_channel(channel_id);
//     stop_cheat_caller_address(channel_contract_address);
// }
