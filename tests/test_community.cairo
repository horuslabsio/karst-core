// *************************************************************************
//                              COMMUNITY TEST
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

use karst::community::community::CommunityComponent;
use karst::base::constants::types::{GateKeepType, CommunityType};
use karst::interfaces::ICommunity::{ICommunityDispatcher, ICommunityDispatcherTrait};

const HUB_ADDRESS: felt252 = 'HUB';
const USER_ONE: felt252 = 'BOB';
const USER_TWO: felt252 = 'ALICE';
const USER_THREE: felt252 = 'ROB';
const USER_FOUR: felt252 = 'DAN';
const USER_FIVE: felt252 = 'RANDY';
const USER_SIX: felt252 = 'JOE';
const NFT_ONE: felt252 = 'JOE_NFT';

// *************************************************************************
//                              SETUP
// *************************************************************************
fn __setup__() -> ContractAddress {
    // deploy community nft
    let community_nft_class_hash = declare("CommunityNFT").unwrap().contract_class();

    // deploy community preset contract
    let community_contract = declare("KarstCommunity").unwrap().contract_class();
    let mut community_constructor_calldata: Array<felt252> = array![
        (*community_nft_class_hash.class_hash).into(),
    ];
    let (community_contract_address, _) = community_contract
        .deploy(@community_constructor_calldata)
        .unwrap();

    return (community_contract_address);
}

// *************************************************************************
//                              TESTS
// *************************************************************************
#[test]
fn test_community_creation() {
    let community_contract_address = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };
    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_comminuty(CommunityType::Free);
    assert(community_id == 1, 'invalid community creation');
    // TEST TODO: use assert to check for every single item within CommunityDetails structs to
    // ensure they were instantiated with the correct values TEST TODO: check that community nft was
    // deployed correctly and you received an address TEST TODO: use assert to check for every
    // single item within CommunityGateKeepDetails structs to ensure they were instantiated with the
    // correct values
    stop_cheat_caller_address(community_contract_address);
}

// TEST TODO: create a new test fn called `test_community_upgrade_on_creation` where you pass in a
// premium package type and checks upgrade was successful

#[test]
fn test_create_community_emits_events() {
    let community_contract_address = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    // spy on emitted events
    let mut spy = spy_events();
    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_comminuty(CommunityType::Free);
    assert(community_id == 1, 'invalid community creation');
    // get community details
    let community = communityDispatcher.get_community(community_id);
    // check events are emitted
    spy
        .assert_emitted(
            @array![
                (
                    community_contract_address,
                    CommunityComponent::Event::CommunityCreated(
                        CommunityComponent::CommunityCreated {
                            community_id: community_id,
                            community_owner: USER_ONE.try_into().unwrap(),
                            community_nft_address: community.community_nft_address,
                            block_timestamp: get_block_timestamp()
                        }
                    )
                )
            ]
        );
}

#[test]
fn test_join_community() {
    let community_contract_address = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    //create the community
    let community_id = communityDispatcher.create_comminuty(CommunityType::Free);

    let (is_member, _) = communityDispatcher
        .is_community_member(USER_ONE.try_into().unwrap(), community_id);

    assert(is_member == true, 'Not Community Member');
    // TEST TODO: check every single struct item in CommunityMember was instantiated correctly
    // TEST TODO: check that a community NFT was minted to the user joining
    stop_cheat_caller_address(community_contract_address);
}

#[test]
#[should_panic(expected: ('Karst: already a Member',))]
fn test_should_panic_if_a_user_joins_one_community_twice() {
    let community_contract_address = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());

    let community_id = communityDispatcher.create_comminuty(CommunityType::Free);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_THREE.try_into().unwrap());

    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_THREE.try_into().unwrap());
    communityDispatcher.join_community(community_id);
    stop_cheat_caller_address(community_contract_address);
}

// // TEST TODO: test that joining a community emits event
#[test]
fn test_joining_community_emits_event() {
    let community_contract_address = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    // spy on emitted events
    let mut spy = spy_events();

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_comminuty(CommunityType::Free);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_THREE.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    let (_, member_details) = communityDispatcher
        .is_community_member(USER_THREE.try_into().unwrap(), community_id);

    spy
        .assert_emitted(
            @array![
                (
                    community_contract_address,
                    CommunityComponent::Event::JoinedCommunity(
                        CommunityComponent::JoinedCommunity {
                            community_id: community_id,
                            transaction_executor: USER_THREE.try_into().unwrap(),
                            token_id: member_details.community_token_id,
                            profile: USER_THREE.try_into().unwrap(),
                            block_timestamp: get_block_timestamp(),
                        }
                    )
                )
            ]
        );
}


#[test]
fn test_leave_community() {
    let community_contract_address = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    //create the community
    let community_id = communityDispatcher.create_comminuty(CommunityType::Free);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_TWO.try_into().unwrap());

    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    // leave community
    start_cheat_caller_address(community_contract_address, USER_TWO.try_into().unwrap());

    communityDispatcher.leave_community(community_id);

    let (is_member, _) = communityDispatcher
        .is_community_member(USER_TWO.try_into().unwrap(), community_id);

    assert(is_member != true, 'still a community member');

    // TEST TODO: check that community total member reduced
    // TEST TODO: check that user NFT is burned on leaving

    stop_cheat_caller_address(community_contract_address);
}


#[test]
#[should_panic(expected: ('Karst: Not a Community  Member',))]
fn test_should_panic_if_profile_leaving_is_not_a_member() {
    let community_contract_address = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    //create the community
    let community_id = communityDispatcher.create_comminuty(CommunityType::Free);

    stop_cheat_caller_address(community_contract_address);

    // leave community
    start_cheat_caller_address(community_contract_address, USER_TWO.try_into().unwrap());
    communityDispatcher.leave_community(community_id);
}

// // TEST TODO: test that leaving a community emits event
#[test]
fn test_leave_community_emits_event() {
    let community_contract_address = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    // spy on emitted events
    let mut spy = spy_events();

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_comminuty(CommunityType::Free);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_THREE.try_into().unwrap());
    communityDispatcher.join_community(community_id);
    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_THREE.try_into().unwrap());
    let (_, member_details) = communityDispatcher
        .is_community_member(USER_THREE.try_into().unwrap(), community_id);
    communityDispatcher.leave_community(community_id);

    spy
        .assert_emitted(
            @array![
                (
                    community_contract_address,
                    CommunityComponent::Event::LeftCommunity(
                        CommunityComponent::LeftCommunity {
                            community_id: community_id,
                            transaction_executor: USER_THREE.try_into().unwrap(),
                            token_id: member_details.community_token_id,
                            profile: USER_THREE.try_into().unwrap(),
                            block_timestamp: get_block_timestamp(),
                        }
                    )
                )
            ]
        );
}


// #[test]
// fn test_set_community_metadata_uri() {
//     let community_contract_address = __setup__();

//     let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address
//     };

//     start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
//     let community_id = communityDispatcher.create_comminuty(CommunityType::Free);

//     communityDispatcher
//         .set_community_metadata_uri(
//             community_id, "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaYXr4gQ/"
//         );
//     let result_meta_uri = communityDispatcher.get_community_metadata_uri(community_id);
//     assert(
//         result_meta_uri == "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaYXr4gQ/", 'invalid
//         uri'
//     );
//     stop_cheat_caller_address(community_contract_address);
// }

// #[test]
// #[should_panic(expected: ('Karst: Not Community owner',))]
// fn test_should_panic_set_community_metadata_uri() {
//     let community_contract_address = __setup__();

//     let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address
//     };

//     start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
//     let community_id = communityDispatcher.create_comminuty(CommunityType::Free);

//     stop_cheat_caller_address(community_contract_address);

//     start_cheat_caller_address(community_contract_address, USER_THREE.try_into().unwrap());
//     let metadata_uri = "ipfs://helloworld";
//     communityDispatcher.set_community_metadata_uri(community_id, metadata_uri);
// }

#[test]
fn test_add_community_mod() {
    let community_contract_address = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_comminuty(CommunityType::Free);
    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_SIX.try_into().unwrap());
    // join the community
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_FIVE.try_into().unwrap());
    communityDispatcher.join_community(community_id);
    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    // mod array
    let mut moderators = ArrayTrait::new();
    moderators.append(USER_SIX.try_into().unwrap());
    moderators.append(USER_FIVE.try_into().unwrap());

    // add a community mod
    communityDispatcher.add_community_mods(community_id, moderators);

    // check a community mod - is_community_mod
    let is_community_mod = communityDispatcher
        .is_community_mod(USER_SIX.try_into().unwrap(), community_id);
    assert(is_community_mod == true, 'Not a Community Mod');
    stop_cheat_caller_address(community_contract_address);
}

#[test]
fn test_add_community_mod_emits_event() {
    let community_contract_address = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    // spy on emitted events
    let mut spy = spy_events();

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_comminuty(CommunityType::Free);
    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_SIX.try_into().unwrap());
    // join the community first
    communityDispatcher.join_community(community_id);
    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    // mod array
    let mut moderators = ArrayTrait::new();
    moderators.append(USER_SIX.try_into().unwrap());

    // add a community mod
    communityDispatcher.add_community_mods(community_id, moderators);

    spy
        .assert_emitted(
            @array![
                (
                    community_contract_address,
                    CommunityComponent::Event::CommunityModAdded(
                        CommunityComponent::CommunityModAdded {
                            community_id: community_id,
                            transaction_executor: USER_ONE.try_into().unwrap(),
                            mod_address: USER_SIX.try_into().unwrap(),
                            block_timestamp: get_block_timestamp()
                        }
                    )
                )
            ]
        );
}

// #[test]
// #[should_panic(expected: ('Karst: Not Community owner',))]
// fn should_panic_if_caller_adding_mod_is_not_owner() {
//     let community_contract_address = __setup__();

//     let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address
//     };

//     start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
//     let community_id = communityDispatcher.create_comminuty(CommunityType::Free);

//     stop_cheat_caller_address(community_contract_address);

//     // when a wrong community owner try to add a MOD
//     start_cheat_caller_address(community_contract_address, USER_TWO.try_into().unwrap());

//     // mod array
//     let mut moderators = ArrayTrait::new();
//     moderators.append(USER_SIX.try_into().unwrap());
//     // add a community mod
//     communityDispatcher.add_community_mods(community_id, moderators);
// }

// // // TEST TODO: write an extra test called `should_panic_if_mod_is_not_member` to check that a
// mod // // must first be a community member // Karst: Not a Community  Member
#[test]
#[should_panic(expected: ('Karst: Not a Community  Member',))]
fn should_panic_if_mod_is_not_member() {
    let community_contract_address = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_comminuty(CommunityType::Free);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_FIVE.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    // mod array
    let mut moderators = ArrayTrait::new();
    moderators.append(USER_SIX.try_into().unwrap());
    moderators.append(USER_FIVE.try_into().unwrap());

    // add a community mod
    communityDispatcher.add_community_mods(community_id, moderators);
}


#[test]
fn test_remove_community_mod() {
    let community_contract_address = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_comminuty(CommunityType::Free);
    // join commmunity
    start_cheat_caller_address(community_contract_address, USER_FIVE.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_SIX.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_FOUR.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    // add mod array
    let mut moderators = ArrayTrait::new();
    moderators.append(USER_SIX.try_into().unwrap());
    moderators.append(USER_FOUR.try_into().unwrap());

    // add a community mod
    communityDispatcher.add_community_mods(community_id, moderators);
    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    // remove mod array
    let mut moderators = ArrayTrait::new();
    moderators.append(USER_SIX.try_into().unwrap());
    moderators.append(USER_FOUR.try_into().unwrap());
    // REMOVE A MOD
    communityDispatcher.remove_community_mods(community_id, moderators);

    // check a community mod - is_community_mod
    let is_community_mod = communityDispatcher
        .is_community_mod(USER_FOUR.try_into().unwrap(), community_id);
    assert(is_community_mod == false, 'Community Mod Not Remove');
    stop_cheat_caller_address(community_contract_address);
}

#[test]
fn test_remove_community_mod_emit_event() {
    let community_contract_address = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    // spy on emitted events
    let mut spy = spy_events();
    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_comminuty(CommunityType::Free);

    // join commmunity
    start_cheat_caller_address(community_contract_address, USER_FIVE.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_SIX.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_FOUR.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    // add mod array
    let mut moderators = ArrayTrait::new();
    moderators.append(USER_SIX.try_into().unwrap());
    moderators.append(USER_FIVE.try_into().unwrap());
    moderators.append(USER_FOUR.try_into().unwrap());

    // add a community mod
    communityDispatcher.add_community_mods(community_id, moderators);
    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    // remove mod array
    let mut remove_moderators = ArrayTrait::new();
    remove_moderators.append(USER_SIX.try_into().unwrap());
    remove_moderators.append(USER_FOUR.try_into().unwrap());
    // REMOVE A MOD
    communityDispatcher.remove_community_mods(community_id, remove_moderators);

    spy
        .assert_emitted(
            @array![
                (
                    community_contract_address,
                    CommunityComponent::Event::CommunityModRemoved(
                        CommunityComponent::CommunityModRemoved {
                            community_id: community_id,
                            transaction_executor: USER_ONE.try_into().unwrap(),
                            mod_address: USER_FOUR.try_into().unwrap(),
                            block_timestamp: get_block_timestamp()
                        }
                    )
                )
            ]
        );
}

#[test]
#[should_panic(expected: ('Karst: Not a Community  Member',))]
fn should_panic_if_caller_removing_mod_not_community_member() {
    let community_contract_address = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_comminuty(CommunityType::Free);
    // join commmunity
    start_cheat_caller_address(community_contract_address, USER_FIVE.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_SIX.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_FOUR.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    // add mod array
    let mut moderators = ArrayTrait::new();
    moderators.append(USER_SIX.try_into().unwrap());
    moderators.append(USER_FOUR.try_into().unwrap());

    // add a community mod
    communityDispatcher.add_community_mods(community_id, moderators);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());

    // remove mod array
    let mut moderators = ArrayTrait::new();
    moderators.append(USER_SIX.try_into().unwrap());
    moderators.append(USER_TWO.try_into().unwrap());
    // REMOVE A MOD
    communityDispatcher.remove_community_mods(community_id, moderators);
}

#[test]
#[should_panic(expected: ('Karst: Not Community owner',))]
fn should_panic_if_caller_removing_mod_is_not_owner() {
    let community_contract_address = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_comminuty(CommunityType::Free);
    // join commmunity
    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_FIVE.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_SIX.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_FOUR.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());

    // add mod array
    let mut moderators = ArrayTrait::new();
    moderators.append(USER_SIX.try_into().unwrap());
    moderators.append(USER_FOUR.try_into().unwrap());

    // add a community mod
    communityDispatcher.add_community_mods(community_id, moderators);
    stop_cheat_caller_address(community_contract_address);

    // when a wrong community owner try to REMOVE a MOD
    start_cheat_caller_address(community_contract_address, USER_TWO.try_into().unwrap());
    // remove mod array
    let mut moderators = ArrayTrait::new();
    moderators.append(USER_SIX.try_into().unwrap());
    moderators.append(USER_FOUR.try_into().unwrap());
    // REMOVE A MOD
    communityDispatcher.remove_community_mods(community_id, moderators);
}

#[test]
fn test_set_ban_status_by_owner() {
    let community_contract_address = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    //create the community
    let community_id = communityDispatcher.create_comminuty(CommunityType::Free);
    // join the community
    start_cheat_caller_address(community_contract_address, USER_FOUR.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_SIX.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_TWO.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_THREE.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    // ban profile list
    let mut profiles = ArrayTrait::new();
    profiles.append(USER_SIX.try_into().unwrap());
    profiles.append(USER_FOUR.try_into().unwrap());

    // ban status list
    let mut ban_statuses = ArrayTrait::new();
    ban_statuses.append(true);
    ban_statuses.append(true);

    communityDispatcher.set_ban_status(community_id, profiles, ban_statuses);

    let is_ban = communityDispatcher.get_ban_status(USER_FOUR.try_into().unwrap(), community_id);

    assert(is_ban == true, 'Community Member is not banned');

    stop_cheat_caller_address(community_contract_address);
}

#[test]
fn test_set_ban_status_by_mod() {
    let community_contract_address = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_SIX.try_into().unwrap());

    let community_id = communityDispatcher.create_comminuty(CommunityType::Free);

    stop_cheat_caller_address(community_contract_address);

    // join the community
    start_cheat_caller_address(community_contract_address, USER_FOUR.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_TWO.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_THREE.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_SIX.try_into().unwrap());
    // add a community mod
    // add mod array
    let mut moderators = ArrayTrait::new();
    moderators.append(USER_FOUR.try_into().unwrap());

    // add a community mod
    communityDispatcher.add_community_mods(community_id, moderators);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_FOUR.try_into().unwrap());

    // ban profile list
    let mut profiles = ArrayTrait::new();
    profiles.append(USER_THREE.try_into().unwrap());
    profiles.append(USER_TWO.try_into().unwrap());

    // ban status list
    let mut ban_statuses = ArrayTrait::new();
    ban_statuses.append(true);
    ban_statuses.append(true);

    communityDispatcher.set_ban_status(community_id, profiles, ban_statuses);

    let is_ban = communityDispatcher.get_ban_status(USER_TWO.try_into().unwrap(), community_id);

    assert(is_ban == true, 'Community Member is not banned');

    stop_cheat_caller_address(community_contract_address);
}

#[test]
fn test_set_ban_status_emit_event() {
    let community_contract_address = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };
    //

    // spy on emitted events
    let mut spy = spy_events();
    start_cheat_caller_address(community_contract_address, USER_SIX.try_into().unwrap());
    let community_id = communityDispatcher.create_comminuty(CommunityType::Free);
    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_FOUR.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_TWO.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_THREE.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_SIX.try_into().unwrap());
    // add a community mod
    // add mod array
    let mut moderators = ArrayTrait::new();
    moderators.append(USER_FOUR.try_into().unwrap());

    // add a community mod
    communityDispatcher.add_community_mods(community_id, moderators);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_SIX.try_into().unwrap());
    // ban profile list
    let mut profiles = ArrayTrait::new();
    profiles.append(USER_THREE.try_into().unwrap());
    profiles.append(USER_TWO.try_into().unwrap());

    // ban status list
    let mut ban_statuses = ArrayTrait::new();
    ban_statuses.append(true);
    ban_statuses.append(true);

    // set ban
    communityDispatcher.set_ban_status(community_id, profiles, ban_statuses);

    spy
        .assert_emitted(
            @array![
                (
                    community_contract_address,
                    CommunityComponent::Event::CommunityBanStatusUpdated(
                        CommunityComponent::CommunityBanStatusUpdated {
                            community_id: community_id,
                            transaction_executor: USER_SIX.try_into().unwrap(),
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
#[should_panic(expected: ('Karst: user unauthorized!',))]
fn test_should_panic_if_caller_to_set_ban_status_is_not_owner_or_mod() {
    let community_contract_address = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    //create the community
    let community_id = communityDispatcher.create_comminuty(CommunityType::Free);

    stop_cheat_caller_address(community_contract_address);

    // join the community
    start_cheat_caller_address(community_contract_address, USER_FOUR.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_SIX.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_TWO.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_THREE.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_FIVE.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    // mode array
    let mut moderators = ArrayTrait::new();
    moderators.append(USER_SIX.try_into().unwrap());
    moderators.append(USER_FIVE.try_into().unwrap());

    // add a community mod
    communityDispatcher.add_community_mods(community_id, moderators);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_THREE.try_into().unwrap());
    // ban status list
    let mut ban_statuses = ArrayTrait::new();
    ban_statuses.append(true);
    ban_statuses.append(true);

    // ban profile list
    let mut profiles = ArrayTrait::new();
    profiles.append(USER_FOUR.try_into().unwrap());
    profiles.append(USER_TWO.try_into().unwrap());
    // set ban
    communityDispatcher.set_ban_status(community_id, profiles, ban_statuses);
}

// TEST TODO: create a test fn called `test_can_only_set_ban_status_for_members` to check that you
// can only ban existing members // Karst: Not a Community  Member
#[test]
#[should_panic(expected: ('Karst: Not a Community  Member',))]
fn test_can_only_set_ban_status_for_members() {
    let community_contract_address = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    //create the community
    let community_id = communityDispatcher.create_comminuty(CommunityType::Free);
    // join the community
    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_SIX.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_TWO.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_THREE.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());

    // ban profile list
    let mut profiles = ArrayTrait::new();
    profiles.append(USER_SIX.try_into().unwrap());
    profiles.append(USER_FOUR.try_into().unwrap());

    // ban status list
    let mut ban_statuses = ArrayTrait::new();
    ban_statuses.append(true);
    ban_statuses.append(true);

    communityDispatcher.set_ban_status(community_id, profiles, ban_statuses);
}


// TEST TODO: TEST To make sure length of ban status and profiles are same
#[test]
#[should_panic(expected: ('Karst: Invalid Length',))]
fn test_should_set_ban_status_for_invalid_array_length() {
    let community_contract_address = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    //create the community
    let community_id = communityDispatcher.create_comminuty(CommunityType::Free);
    // join the community
    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_SIX.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_TWO.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_THREE.try_into().unwrap());
    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    // ban profile list
    let mut profiles = ArrayTrait::new();
    profiles.append(USER_SIX.try_into().unwrap());

    // ban status list
    let mut ban_statuses = ArrayTrait::new();
    ban_statuses.append(true);
    ban_statuses.append(true);

    communityDispatcher.set_ban_status(community_id, profiles, ban_statuses);
}


#[test]
fn test_community_upgrade() {
    let community_contract_address = __setup__();
    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_comminuty(CommunityType::Free);
    communityDispatcher.upgrade_community(community_id, CommunityType::Standard);
    let community = communityDispatcher.get_community(community_id);
    assert(community.community_type == CommunityType::Standard, 'Community Upgrade failed');
    // TEST TODO: check that upgraded communities have a premium status
    stop_cheat_caller_address(community_contract_address);
}

#[test]
#[should_panic(expected: ('Karst: Not Community owner',))]
fn test_should_panic_if_caller_upgrading_is_not_owner() {
    let community_contract_address = __setup__();
    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_comminuty(CommunityType::Free);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_TWO.try_into().unwrap());
    communityDispatcher.upgrade_community(community_id, CommunityType::Standard);
    let community = communityDispatcher.get_community(community_id);
    assert(community.community_type == CommunityType::Standard, 'Community Upgrade failed');
}

#[test]
fn test_community_upgrade_emits_event() {
    let community_contract_address = __setup__();
    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    // spy on emitted events
    let mut spy = spy_events();

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_comminuty(CommunityType::Free);
    communityDispatcher.upgrade_community(community_id, CommunityType::Standard);

    // check events are emitted
    spy
        .assert_emitted(
            @array![
                (
                    community_contract_address,
                    CommunityComponent::Event::CommunityUpgraded(
                        CommunityComponent::CommunityUpgraded {
                            community_id: community_id,
                            transaction_executor: USER_ONE.try_into().unwrap(),
                            premiumType: CommunityType::Standard,
                            block_timestamp: get_block_timestamp()
                        }
                    )
                )
            ]
        );
}

#[test]
fn test_permissioned_gatekeeping() {
    let community_contract_address = __setup__();
    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    let mut permission_addresses = ArrayTrait::new();
    permission_addresses.append(USER_SIX.try_into().unwrap());
    permission_addresses.append(USER_FIVE.try_into().unwrap());
    permission_addresses.append(USER_THREE.try_into().unwrap());

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_comminuty(CommunityType::Free);
    communityDispatcher
        .gatekeep(
            community_id,
            GateKeepType::PermissionedGating,
            NFT_ONE.try_into().unwrap(),
            permission_addresses,
            0
        );

    // check is_gatekeeped
    let (is_gatekeeped, _) = communityDispatcher.is_gatekeeped(community_id);
    assert(is_gatekeeped == true, 'Community gatekeep failed');
    stop_cheat_caller_address(community_contract_address);
}

#[test]
fn test_paid_gatekeeping() {
    let community_contract_address = __setup__();
    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    let mut permission_addresses = ArrayTrait::new();
    permission_addresses.append(USER_SIX.try_into().unwrap());
    permission_addresses.append(USER_FIVE.try_into().unwrap());
    permission_addresses.append(USER_THREE.try_into().unwrap());
    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_comminuty(CommunityType::Free);
    communityDispatcher.upgrade_community(community_id, CommunityType::Standard);
    communityDispatcher
        .gatekeep(
            community_id,
            GateKeepType::PaidGating,
            NFT_ONE.try_into().unwrap(),
            permission_addresses,
            450
        );

    // check is_gatekeeped
    let (is_gatekeeped, _) = communityDispatcher.is_gatekeeped(community_id);
    assert(is_gatekeeped == true, 'Community gatekeep failed');
    stop_cheat_caller_address(community_contract_address);
}

// TEST TODO: add test fn `test_nft_gatekeeping` for NFTGating
#[test]
fn test_paid_gatekeeping_nft_gating() {
    let community_contract_address = __setup__();
    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    let mut permission_addresses = ArrayTrait::new();
    permission_addresses.append(USER_SIX.try_into().unwrap());
    permission_addresses.append(USER_FIVE.try_into().unwrap());
    permission_addresses.append(USER_THREE.try_into().unwrap());
    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_comminuty(CommunityType::Free);
    communityDispatcher.upgrade_community(community_id, CommunityType::Standard);
    communityDispatcher
        .gatekeep(
            community_id,
            GateKeepType::NFTGating,
            NFT_ONE.try_into().unwrap(),
            permission_addresses,
            450
        );

    // check is_gatekeeped
    let (is_gatekeeped, gatekeep_details) = communityDispatcher.is_gatekeeped(community_id);
    assert(
        gatekeep_details.gate_keep_type == GateKeepType::NFTGating, 'Community NFT Gatekeep Failed'
    );
    stop_cheat_caller_address(community_contract_address);
}

// TEST TODO: add test fn `test_only_premium_communities_can_be_paid_gated` to test that only
// premium communities can enforce PaidGating
#[test]
fn test_only_premium_communities_can_be_paid_gated() {
    let community_contract_address = __setup__();
    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    let mut permission_addresses = ArrayTrait::new();
    permission_addresses.append(USER_SIX.try_into().unwrap());
    permission_addresses.append(USER_FIVE.try_into().unwrap());
    permission_addresses.append(USER_THREE.try_into().unwrap());
    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_comminuty(CommunityType::Free);
    communityDispatcher.upgrade_community(community_id, CommunityType::Standard);
    communityDispatcher
        .gatekeep(
            community_id,
            GateKeepType::PaidGating,
            NFT_ONE.try_into().unwrap(),
            permission_addresses,
            450
        );

    // check is_gatekeeped
    let (is_gatekeeped, gatekeep_details) = communityDispatcher.is_gatekeeped(community_id);
    assert(
        gatekeep_details.gate_keep_type == GateKeepType::PaidGating,
        'Community Paid Gatekeep Failed'
    );
    stop_cheat_caller_address(community_contract_address);
}


// TEST TODO: add test fn
// `test_only_premium_communities_can_be_nft_gated` to test that only premium communities can
// enforce NFTGating

#[test]
#[should_panic(expected: ('Karst: only premium communities',))]
fn test_should_panic_only_premium_communities_can_be_paid_gated() {
    let community_contract_address = __setup__();
    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    let mut permission_addresses = ArrayTrait::new();
    permission_addresses.append(USER_SIX.try_into().unwrap());
    permission_addresses.append(USER_FIVE.try_into().unwrap());
    permission_addresses.append(USER_THREE.try_into().unwrap());
    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_comminuty(CommunityType::Free);
    communityDispatcher
        .gatekeep(
            community_id,
            GateKeepType::PaidGating,
            NFT_ONE.try_into().unwrap(),
            permission_addresses,
            450
        );

    // check is_gatekeeped
    let (is_gatekeeped, gatekeep_details) = communityDispatcher.is_gatekeeped(community_id);
    assert(
        gatekeep_details.gate_keep_type == GateKeepType::PaidGating,
        'Community Paid Gatekeep Failed'
    );
    stop_cheat_caller_address(community_contract_address);
}

#[test]
#[should_panic(expected: ('Karst: only premium communities',))]
fn test_should_panic_only_premium_communities_can_be_nft_gated() {
    let community_contract_address = __setup__();
    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    let mut permission_addresses = ArrayTrait::new();
    permission_addresses.append(USER_SIX.try_into().unwrap());
    permission_addresses.append(USER_FIVE.try_into().unwrap());
    permission_addresses.append(USER_THREE.try_into().unwrap());
    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_comminuty(CommunityType::Free);
    communityDispatcher
        .gatekeep(
            community_id,
            GateKeepType::PaidGating,
            NFT_ONE.try_into().unwrap(),
            permission_addresses,
            450
        );

    // check is_gatekeeped
    let (is_gatekeeped, gatekeep_details) = communityDispatcher.is_gatekeeped(community_id);
    assert(
        gatekeep_details.gate_keep_type == GateKeepType::PaidGating,
        'Community Paid Gatekeep Failed'
    );
    stop_cheat_caller_address(community_contract_address);
}


#[test]
#[should_panic(expected: ('Karst: Not Community owner',))]
fn test_should_panic_if_caller_to_gatekeep_is_not_owner() {
    let community_contract_address = __setup__();
    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    let mut permission_addresses = ArrayTrait::new();
    permission_addresses.append(USER_SIX.try_into().unwrap());
    permission_addresses.append(USER_FIVE.try_into().unwrap());
    permission_addresses.append(USER_THREE.try_into().unwrap());

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_comminuty(CommunityType::Free);

    stop_cheat_caller_address(community_contract_address);

    // Wrong owner trying to gate keep
    start_cheat_caller_address(community_contract_address, USER_TWO.try_into().unwrap());
    communityDispatcher
        .gatekeep(
            community_id,
            GateKeepType::PaidGating,
            NFT_ONE.try_into().unwrap(),
            permission_addresses,
            450
        );
}

#[test]
fn test_community_gatekeep_emits_event() {
    let community_contract_address = __setup__();
    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    let mut permission_addresses = ArrayTrait::new();
    permission_addresses.append(USER_SIX.try_into().unwrap());
    permission_addresses.append(USER_FIVE.try_into().unwrap());
    permission_addresses.append(USER_THREE.try_into().unwrap());

    // spy on emitted events
    let mut spy = spy_events();

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_comminuty(CommunityType::Free);
    communityDispatcher
        .gatekeep(
            community_id,
            GateKeepType::PermissionedGating,
            NFT_ONE.try_into().unwrap(),
            permission_addresses,
            0
        );

    // check events are emitted
    spy
        .assert_emitted(
            @array![
                (
                    community_contract_address,
                    CommunityComponent::Event::CommunityGatekeeped(
                        CommunityComponent::CommunityGatekeeped {
                            community_id: community_id,
                            transaction_executor: USER_ONE.try_into().unwrap(),
                            gatekeepType: GateKeepType::PermissionedGating,
                            block_timestamp: get_block_timestamp()
                        }
                    )
                )
            ]
        );
}

