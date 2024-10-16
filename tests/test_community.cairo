// *************************************************************************
//                              COMMUNITY TEST
// *************************************************************************
use core::option::OptionTrait;
use core::result::ResultTrait;
use core::traits::{TryInto, Into};
use starknet::{ContractAddress, get_block_timestamp, contract_address_const};

use snforge_std::{
    declare, start_cheat_caller_address, stop_cheat_caller_address, spy_events,
    EventSpyAssertionsTrait, ContractClassTrait, DeclareResultTrait
};

use karst::community::community::CommunityComponent;
use karst::base::constants::types::{GateKeepType, CommunityType};
use karst::interfaces::ICommunity::{ICommunityDispatcher, ICommunityDispatcherTrait};
use karst::interfaces::IJolt::{IJoltDispatcher, IJoltDispatcherTrait};
use karst::interfaces::IERC20::{IERC20Dispatcher, IERC20DispatcherTrait};
use karst::interfaces::IERC721::{IERC721Dispatcher, IERC721DispatcherTrait};

const HUB_ADDRESS: felt252 = 'HUB';
const ADMIN: felt252 = 'ADMIN';
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
fn __setup__() -> (ContractAddress, ContractAddress) {
    // deploy community nft
    let community_nft_class_hash = declare("CommunityNFT").unwrap().contract_class();

    // deploy community preset contract
    let community_contract = declare("KarstCommunity").unwrap().contract_class();
    let mut community_constructor_calldata: Array<felt252> = array![
        (*community_nft_class_hash.class_hash).into(), ADMIN
    ];
    let (community_contract_address, _) = community_contract
        .deploy(@community_constructor_calldata)
        .unwrap();

    // deploy mock USDT
    let usdt_contract = declare("USDT").unwrap().contract_class();
    let (usdt_contract_address, _) = usdt_contract
        .deploy(@array![1000000000000000000000, 0, USER_ONE])
        .unwrap();

    return (community_contract_address, usdt_contract_address);
}

// *************************************************************************
//                              TESTS
// *************************************************************************
#[test]
fn test_community_creation() {
    let (community_contract_address, _) = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };
    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_community();
    assert(community_id == 1, 'invalid community creation');

    let community_data = communityDispatcher.get_community(community_id);
    assert(community_data.community_id == community_id, 'invalid community ID');
    assert(community_data.community_type == CommunityType::Free, 'invalid community type');
    assert(community_data.community_owner == USER_ONE.try_into().unwrap(), 'invalid owner');
    assert(community_data.community_total_members == 1, 'invalid  total  members');
    assert(community_data.community_premium_status == false, 'invalid premium status');
    assert(
        community_data.community_nft_address != contract_address_const::<0>(),
        'community nft was not deployed'
    );

    let (_, gate_keep_details) = communityDispatcher.is_gatekeeped(community_id);
    assert(gate_keep_details.gate_keep_type == GateKeepType::None, 'invalid community type');
    assert(community_data.community_id == community_id, 'invalid community ID');

    stop_cheat_caller_address(community_contract_address);
}

#[test]
fn test_owner_joins_on_community_creation() {
    let (community_contract_address, _) = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };
    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_community();

    let (is_member, _) = communityDispatcher
        .is_community_member(USER_ONE.try_into().unwrap(), community_id);
    assert(is_member == true, 'owner is not a member');

    let community_data = communityDispatcher.get_community(community_id);
    assert(community_data.community_total_members == 1, 'invalid total members');
}

#[test]
fn test_create_community_emits_events() {
    let (community_contract_address, _) = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    // spy on emitted events
    let mut spy = spy_events();
    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_community();

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
    let (community_contract_address, _) = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    //create the community
    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_community();

    let (is_member, community_member) = communityDispatcher
        .is_community_member(USER_ONE.try_into().unwrap(), community_id);
    assert(is_member == true, 'joining community failed');
    assert(community_member.community_id == community_id, 'invalid community id');
    assert(
        community_member.profile_address == USER_ONE.try_into().unwrap(),
        'invalid community memeber'
    );
    assert(community_member.total_publications == 0, 'invalid  total  publication');
    assert(community_member.community_token_id != 0, 'nft token was not minted');

    stop_cheat_caller_address(community_contract_address);
}

#[test]
#[should_panic(expected: ('Karst: already a Member',))]
fn test_should_panic_if_a_user_joins_one_community_twice() {
    let (community_contract_address, _) = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());

    let community_id = communityDispatcher.create_community();

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_THREE.try_into().unwrap());

    communityDispatcher.join_community(community_id);

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_THREE.try_into().unwrap());
    communityDispatcher.join_community(community_id);
    stop_cheat_caller_address(community_contract_address);
}


#[test]
fn test_joining_community_emits_event() {
    let (community_contract_address, _) = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    // spy on emitted events
    let mut spy = spy_events();

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_community();

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
    let (community_contract_address, _) = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    //create the community
    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_community();
    stop_cheat_caller_address(community_contract_address);

    // join community
    start_cheat_caller_address(community_contract_address, USER_TWO.try_into().unwrap());
    communityDispatcher.join_community(community_id);
    stop_cheat_caller_address(community_contract_address);

    // leave community
    start_cheat_caller_address(community_contract_address, USER_TWO.try_into().unwrap());
    communityDispatcher.leave_community(community_id);

    let (is_member, member) = communityDispatcher
        .is_community_member(USER_TWO.try_into().unwrap(), community_id);

    assert(is_member != true, 'still a community member');
    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_TWO.try_into().unwrap());

    let get_total_members = communityDispatcher.get_total_members(community_id);
    assert(get_total_members == 1, 'No reduction in total member');

    assert(member.community_token_id == 0, 'NFT was not burned');
    stop_cheat_caller_address(community_contract_address);
}

#[test]
#[should_panic(expected: ('Karst: Not a Community  Member',))]
fn test_should_panic_if_profile_leaving_is_not_a_member() {
    let (community_contract_address, _) = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_community();
    stop_cheat_caller_address(community_contract_address);

    // leave community
    start_cheat_caller_address(community_contract_address, USER_TWO.try_into().unwrap());
    communityDispatcher.leave_community(community_id);
}

#[test]
fn test_leave_community_emits_event() {
    let (community_contract_address, _) = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    // spy on emitted events
    let mut spy = spy_events();

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_community();
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


#[test]
fn test_set_community_metadata_uri() {
    let (community_contract_address, _) = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_community();

    communityDispatcher
        .set_community_metadata_uri(
            community_id, "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaYXr4gQ/"
        );
    let result_meta_uri = communityDispatcher.get_community_metadata_uri(community_id);
    assert(
        result_meta_uri == "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaYXr4gQ/",
        'invalid
        uri'
    );
    stop_cheat_caller_address(community_contract_address);
}

#[test]
#[should_panic(expected: ('Karst: Not Community owner',))]
fn test_should_panic_set_community_metadata_uri() {
    let (community_contract_address, _) = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_community();

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_THREE.try_into().unwrap());
    let metadata_uri = "ipfs://helloworld";
    communityDispatcher.set_community_metadata_uri(community_id, metadata_uri);
}

#[test]
fn test_add_community_mod() {
    let (community_contract_address, _) = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_community();
    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_SIX.try_into().unwrap());
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
    assert(is_community_mod == true, 'not a community mod');
    stop_cheat_caller_address(community_contract_address);
}

#[test]
fn test_add_community_mod_emits_event() {
    let (community_contract_address, _) = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    // spy on emitted events
    let mut spy = spy_events();

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_community();
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

#[test]
#[should_panic(expected: ('Karst: Not Community owner',))]
fn test_should_panic_if_caller_adding_mod_is_not_owner() {
    let (community_contract_address, _) = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_community();
    stop_cheat_caller_address(community_contract_address);

    // when a wrong community owner try to add a mod
    start_cheat_caller_address(community_contract_address, USER_TWO.try_into().unwrap());
    let mut moderators = ArrayTrait::new();
    moderators.append(USER_SIX.try_into().unwrap());
    communityDispatcher.add_community_mods(community_id, moderators);
}

#[test]
#[should_panic(expected: ('Karst: Not a Community  Member',))]
fn test_should_panic_if_mod_is_not_member() {
    let (community_contract_address, _) = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_community();
    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_FIVE.try_into().unwrap());
    communityDispatcher.join_community(community_id);
    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let mut moderators = ArrayTrait::new();
    moderators.append(USER_SIX.try_into().unwrap());
    moderators.append(USER_FIVE.try_into().unwrap());

    // add a community mod
    communityDispatcher.add_community_mods(community_id, moderators);
}

#[test]
fn test_remove_community_mod() {
    let (community_contract_address, _) = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_community();
    stop_cheat_caller_address(community_contract_address);

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
    let mut moderators = ArrayTrait::new();
    moderators.append(USER_SIX.try_into().unwrap());
    moderators.append(USER_FOUR.try_into().unwrap());

    // add a community mod
    communityDispatcher.add_community_mods(community_id, moderators);
    stop_cheat_caller_address(community_contract_address);

    // remove a mod
    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let mut moderators = ArrayTrait::new();
    moderators.append(USER_SIX.try_into().unwrap());
    moderators.append(USER_FOUR.try_into().unwrap());
    communityDispatcher.remove_community_mods(community_id, moderators);

    // check a community mod - is_community_mod
    let is_community_mod = communityDispatcher
        .is_community_mod(USER_FOUR.try_into().unwrap(), community_id);
    assert(is_community_mod == false, 'mod was not removed!');
    stop_cheat_caller_address(community_contract_address);
}

#[test]
fn test_remove_community_mod_emit_event() {
    let (community_contract_address, _) = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    // spy on emitted events
    let mut spy = spy_events();
    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_community();

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
    let mut remove_moderators = ArrayTrait::new();
    remove_moderators.append(USER_SIX.try_into().unwrap());
    remove_moderators.append(USER_FOUR.try_into().unwrap());

    // remove a mod
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
#[should_panic(expected: ('Karst: Not a community mod',))]
fn test_should_panic_if_mod_to_be_removed_is_not_a_mod() {
    let (community_contract_address, _) = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_community();

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
    let mut moderators = ArrayTrait::new();
    moderators.append(USER_SIX.try_into().unwrap());
    moderators.append(USER_FOUR.try_into().unwrap());

    // add a community mod
    communityDispatcher.add_community_mods(community_id, moderators);
    stop_cheat_caller_address(community_contract_address);

    // remove a mod
    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let mut moderators = ArrayTrait::new();
    moderators.append(USER_TWO.try_into().unwrap());
    communityDispatcher.remove_community_mods(community_id, moderators);
}

#[test]
#[should_panic(expected: ('Karst: Not Community owner',))]
fn test_should_panic_if_caller_removing_mod_is_not_owner() {
    let (community_contract_address, _) = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_community();
    stop_cheat_caller_address(community_contract_address);

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
    let mut moderators = ArrayTrait::new();
    moderators.append(USER_SIX.try_into().unwrap());
    moderators.append(USER_FOUR.try_into().unwrap());

    // add a community mod
    communityDispatcher.add_community_mods(community_id, moderators);
    stop_cheat_caller_address(community_contract_address);

    // when a wrong community owner try to remove a mod
    start_cheat_caller_address(community_contract_address, USER_TWO.try_into().unwrap());
    let mut moderators = ArrayTrait::new();
    moderators.append(USER_SIX.try_into().unwrap());
    moderators.append(USER_FOUR.try_into().unwrap());
    communityDispatcher.remove_community_mods(community_id, moderators);
}

#[test]
fn test_set_censorship_status() {
    let (community_contract_address, _) = __setup__();
    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    //create the community
    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_community();

    // set censorship status
    communityDispatcher.set_community_censorship_status(community_id, true);

    // check censorship status was set to true
    let censorship_status = communityDispatcher.get_community_censorship_status(community_id);
    assert(censorship_status == true, 'invalid censorship status');
    stop_cheat_caller_address(community_contract_address);
}

#[test]
#[should_panic(expected: ('Karst: user unauthorized!',))]
fn test_only_owner_can_set_censorship_status() {
    let (community_contract_address, _) = __setup__();
    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    //create the community
    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_community();
    stop_cheat_caller_address(community_contract_address);

    // set censorship status
    communityDispatcher.set_community_censorship_status(community_id, true);
}

#[test]
fn test_set_ban_status_by_owner() {
    let (community_contract_address, _) = __setup__();
    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    //create the community
    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_community();

    // join the community
    start_cheat_caller_address(community_contract_address, USER_FOUR.try_into().unwrap());
    communityDispatcher.join_community(community_id);
    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_SIX.try_into().unwrap());
    communityDispatcher.join_community(community_id);
    stop_cheat_caller_address(community_contract_address);

    // set ban status
    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let mut profiles = ArrayTrait::new();
    profiles.append(USER_SIX.try_into().unwrap());
    profiles.append(USER_FOUR.try_into().unwrap());

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
    let (community_contract_address, _) = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_SIX.try_into().unwrap());
    let community_id = communityDispatcher.create_community();
    stop_cheat_caller_address(community_contract_address);

    // join the community
    start_cheat_caller_address(community_contract_address, USER_FOUR.try_into().unwrap());
    communityDispatcher.join_community(community_id);
    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    communityDispatcher.join_community(community_id);
    stop_cheat_caller_address(community_contract_address);

    // add a community mod
    start_cheat_caller_address(community_contract_address, USER_SIX.try_into().unwrap());
    let mut moderators = ArrayTrait::new();
    moderators.append(USER_FOUR.try_into().unwrap());

    communityDispatcher.add_community_mods(community_id, moderators);
    stop_cheat_caller_address(community_contract_address);

    // set ban status
    start_cheat_caller_address(community_contract_address, USER_FOUR.try_into().unwrap());
    let mut profiles = ArrayTrait::new();
    profiles.append(USER_ONE.try_into().unwrap());

    let mut ban_statuses = ArrayTrait::new();
    ban_statuses.append(true);

    communityDispatcher.set_ban_status(community_id, profiles, ban_statuses);

    let is_ban = communityDispatcher.get_ban_status(USER_ONE.try_into().unwrap(), community_id);
    assert(is_ban == true, 'Community Member is not banned');
    stop_cheat_caller_address(community_contract_address);
}

#[test]
fn test_set_ban_status_emit_event() {
    let (community_contract_address, _) = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_SIX.try_into().unwrap());
    let community_id = communityDispatcher.create_community();
    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_FOUR.try_into().unwrap());
    communityDispatcher.join_community(community_id);
    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    communityDispatcher.join_community(community_id);
    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_SIX.try_into().unwrap());
    let mut profiles = ArrayTrait::new();
    profiles.append(USER_FOUR.try_into().unwrap());
    profiles.append(USER_ONE.try_into().unwrap());

    let mut ban_statuses = ArrayTrait::new();
    ban_statuses.append(true);
    ban_statuses.append(true);

    // set ban and spy on emitted event
    let mut spy = spy_events();
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
                            profile: USER_FOUR.try_into().unwrap(),
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
    let (community_contract_address, _) = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_community();
    stop_cheat_caller_address(community_contract_address);

    // join the community
    start_cheat_caller_address(community_contract_address, USER_FOUR.try_into().unwrap());
    communityDispatcher.join_community(community_id);
    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_SIX.try_into().unwrap());
    communityDispatcher.join_community(community_id);
    stop_cheat_caller_address(community_contract_address);

    // add community mod
    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let mut moderators = ArrayTrait::new();
    moderators.append(USER_SIX.try_into().unwrap());
    communityDispatcher.add_community_mods(community_id, moderators);
    stop_cheat_caller_address(community_contract_address);

    // set ban status
    start_cheat_caller_address(community_contract_address, USER_THREE.try_into().unwrap());
    let mut ban_statuses = ArrayTrait::new();
    ban_statuses.append(true);

    let mut profiles = ArrayTrait::new();
    profiles.append(USER_FOUR.try_into().unwrap());

    communityDispatcher.set_ban_status(community_id, profiles, ban_statuses);
}

#[test]
#[should_panic(expected: ('Karst: Not a Community  Member',))]
fn test_can_only_set_ban_status_for_members() {
    let (community_contract_address, _) = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_community();
    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_SIX.try_into().unwrap());
    communityDispatcher.join_community(community_id);
    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_TWO.try_into().unwrap());
    communityDispatcher.join_community(community_id);
    stop_cheat_caller_address(community_contract_address);

    // set ban status
    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let mut profiles = ArrayTrait::new();
    profiles.append(USER_SIX.try_into().unwrap());
    profiles.append(USER_FOUR.try_into().unwrap());

    let mut ban_statuses = ArrayTrait::new();
    ban_statuses.append(true);
    ban_statuses.append(true);

    communityDispatcher.set_ban_status(community_id, profiles, ban_statuses);
}


#[test]
#[should_panic(expected: ('Karst: array mismatch',))]
fn test_should_set_ban_status_for_invalid_array_length() {
    let (community_contract_address, _) = __setup__();

    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_community();
    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_SIX.try_into().unwrap());
    communityDispatcher.join_community(community_id);
    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_TWO.try_into().unwrap());
    communityDispatcher.join_community(community_id);
    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let mut profiles = ArrayTrait::new();
    profiles.append(USER_SIX.try_into().unwrap());

    let mut ban_statuses = ArrayTrait::new();
    ban_statuses.append(true);
    ban_statuses.append(true);

    communityDispatcher.set_ban_status(community_id, profiles, ban_statuses);
}

// TODO: create subscription
// TODO: test joining paid communities, nft gated communities, permissioned communities
#[test]
fn test_community_upgrade() {
    let (community_contract_address, usdt_contract_address) = __setup__();
    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };
    let joltDispatcher = IJoltDispatcher { contract_address: community_contract_address };
    let erc20_dispatcher = IERC20Dispatcher { contract_address: usdt_contract_address };

    // create subscription
    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let sub_id = joltDispatcher
        .create_subscription(ADMIN.try_into().unwrap(), 1000000000000000000, usdt_contract_address);
    stop_cheat_caller_address(community_contract_address);

    // approve contract to spend amount
    start_cheat_caller_address(usdt_contract_address, USER_ONE.try_into().unwrap());
    erc20_dispatcher.approve(community_contract_address, 4000000000000000000);
    stop_cheat_caller_address(usdt_contract_address);

    // upgrade community
    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_community();
    communityDispatcher.upgrade_community(community_id, CommunityType::Standard, sub_id, false, 0);

    let community = communityDispatcher.get_community(community_id);
    assert(community.community_type == CommunityType::Standard, 'Community Upgrade failed');
    assert(community.community_premium_status == true, 'community should be premium');
    stop_cheat_caller_address(community_contract_address);
}

#[test]
#[should_panic(expected: ('Karst: Not Community owner',))]
fn test_should_panic_if_caller_upgrading_is_not_owner() {
    let (community_contract_address, _) = __setup__();
    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_community();

    stop_cheat_caller_address(community_contract_address);

    start_cheat_caller_address(community_contract_address, USER_TWO.try_into().unwrap());
    communityDispatcher.upgrade_community(community_id, CommunityType::Standard, 123, false, 0);
}

#[test]
fn test_community_upgrade_emits_event() {
    let (community_contract_address, usdt_contract_address) = __setup__();
    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };
    let joltDispatcher = IJoltDispatcher { contract_address: community_contract_address };
    let erc20_dispatcher = IERC20Dispatcher { contract_address: usdt_contract_address };

    // create subscription
    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let sub_id = joltDispatcher
        .create_subscription(ADMIN.try_into().unwrap(), 1000000000000000000, usdt_contract_address);
    stop_cheat_caller_address(community_contract_address);

    // approve contract to spend amount
    start_cheat_caller_address(usdt_contract_address, USER_ONE.try_into().unwrap());
    erc20_dispatcher.approve(community_contract_address, 4000000000000000000);
    stop_cheat_caller_address(usdt_contract_address);

    // spy on emitted events
    let mut spy = spy_events();

    // upgrade community
    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_community();
    communityDispatcher.upgrade_community(community_id, CommunityType::Standard, sub_id, false, 0);

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
    let (community_contract_address, _) = __setup__();
    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    let mut permission_addresses = ArrayTrait::new();
    permission_addresses.append(USER_SIX.try_into().unwrap());
    permission_addresses.append(USER_FIVE.try_into().unwrap());
    permission_addresses.append(USER_THREE.try_into().unwrap());

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_community();
    communityDispatcher
        .gatekeep(
            community_id,
            GateKeepType::PermissionedGating,
            contract_address_const::<0>(),
            permission_addresses,
            (contract_address_const::<0>(), 0)
        );

    // check is_gatekeeped
    let (is_gatekeeped, _) = communityDispatcher.is_gatekeeped(community_id);
    assert(is_gatekeeped == true, 'Community gatekeep failed');
    stop_cheat_caller_address(community_contract_address);
}

#[test]
fn test_paid_gatekeeping() {
    let (community_contract_address, usdt_contract_address) = __setup__();
    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };
    let joltDispatcher = IJoltDispatcher { contract_address: community_contract_address };
    let erc20_dispatcher = IERC20Dispatcher { contract_address: usdt_contract_address };

    // create subscription
    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let sub_id = joltDispatcher
        .create_subscription(ADMIN.try_into().unwrap(), 1000000000000000000, usdt_contract_address);
    stop_cheat_caller_address(community_contract_address);

    // approve contract to spend amount
    start_cheat_caller_address(usdt_contract_address, USER_ONE.try_into().unwrap());
    erc20_dispatcher.approve(community_contract_address, 4000000000000000000);
    stop_cheat_caller_address(usdt_contract_address);

    // upgrade community
    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_community();
    communityDispatcher.upgrade_community(community_id, CommunityType::Standard, sub_id, false, 0);

    // gatekeep community
    communityDispatcher
        .gatekeep(
            community_id,
            GateKeepType::PaidGating,
            contract_address_const::<0>(),
            array![contract_address_const::<0>()],
            (usdt_contract_address, 100)
        );

    // check is_gatekeeped
    let (is_gatekeeped, gatekeep_details) = communityDispatcher.is_gatekeeped(community_id);
    assert(is_gatekeeped == true, 'Community gatekeep failed');
    let (erc20_contract, amount) = gatekeep_details.paid_gating_details;
    assert(erc20_contract == usdt_contract_address, 'invalid paid gating');
    assert(amount == 100, 'invalid paid gating');
    stop_cheat_caller_address(community_contract_address);
}

#[test]
fn test_nft_gatekeeping() {
    let (community_contract_address, usdt_contract_address) = __setup__();
    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };
    let joltDispatcher = IJoltDispatcher { contract_address: community_contract_address };
    let erc20_dispatcher = IERC20Dispatcher { contract_address: usdt_contract_address };

    // create subscription
    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let sub_id = joltDispatcher
        .create_subscription(ADMIN.try_into().unwrap(), 1000000000000000000, usdt_contract_address);
    stop_cheat_caller_address(community_contract_address);

    // approve contract to spend amount
    start_cheat_caller_address(usdt_contract_address, USER_ONE.try_into().unwrap());
    erc20_dispatcher.approve(community_contract_address, 4000000000000000000);
    stop_cheat_caller_address(usdt_contract_address);

    // upgrade community
    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_community();
    communityDispatcher.upgrade_community(community_id, CommunityType::Business, sub_id, false, 0);

    // gatekeep community
    communityDispatcher
        .gatekeep(
            community_id,
            GateKeepType::NFTGating,
            123.try_into().unwrap(),
            array![contract_address_const::<0>()],
            (contract_address_const::<0>(), 0)
        );

    // check is_gatekeeped
    let (is_gatekeeped, gatekeep_details) = communityDispatcher.is_gatekeeped(community_id);
    assert(is_gatekeeped == true, 'Community gatekeep failed');
    assert(
        gatekeep_details.gate_keep_type == GateKeepType::NFTGating, 'Community NFT Gatekeep Failed'
    );
    assert(gatekeep_details.gatekeep_nft_address == 123.try_into().unwrap(), 'gatekeeping failed');

    stop_cheat_caller_address(community_contract_address);
}

#[test]
#[should_panic(expected: ('Karst: only premium communities',))]
fn test_only_premium_communities_can_be_paid_gated() {
    let (community_contract_address, _) = __setup__();
    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    let mut permission_addresses = ArrayTrait::new();
    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_community();
    communityDispatcher
        .gatekeep(
            community_id,
            GateKeepType::PaidGating,
            contract_address_const::<0>(),
            permission_addresses,
            (1.try_into().unwrap(), 100)
        );
}

#[test]
#[should_panic(expected: ('Karst: only premium communities',))]
fn test_only_premium_communities_can_be_nft_gated() {
    let (community_contract_address, _) = __setup__();
    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    let mut permission_addresses = ArrayTrait::new();
    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_community();
    communityDispatcher
        .gatekeep(
            community_id,
            GateKeepType::PaidGating,
            NFT_ONE.try_into().unwrap(),
            permission_addresses,
            (contract_address_const::<0>(), 0)
        );
}

#[test]
#[should_panic(expected: ('Karst: Not Community owner',))]
fn test_should_panic_if_caller_to_gatekeep_is_not_owner() {
    let (community_contract_address, _) = __setup__();
    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    let mut permission_addresses = ArrayTrait::new();

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_community();
    stop_cheat_caller_address(community_contract_address);

    // Wrong owner trying to gate keep
    start_cheat_caller_address(community_contract_address, USER_TWO.try_into().unwrap());
    communityDispatcher
        .gatekeep(
            community_id,
            GateKeepType::PaidGating,
            NFT_ONE.try_into().unwrap(),
            permission_addresses,
            (contract_address_const::<0>(), 0)
        );
}

#[test]
fn test_community_gatekeep_emits_event() {
    let (community_contract_address, _) = __setup__();
    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    let mut permission_addresses = ArrayTrait::new();
    permission_addresses.append(USER_SIX.try_into().unwrap());
    permission_addresses.append(USER_FIVE.try_into().unwrap());
    permission_addresses.append(USER_THREE.try_into().unwrap());

    // spy on emitted events
    let mut spy = spy_events();

    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_community();
    communityDispatcher
        .gatekeep(
            community_id,
            GateKeepType::PermissionedGating,
            NFT_ONE.try_into().unwrap(),
            permission_addresses,
            (contract_address_const::<0>(), 0)
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

#[test]
#[should_panic(expected: ('Karst: user unauthorized!',))]
fn test_permissioned_gating_is_enforced_on_joining() {
    let (community_contract_address, _) = __setup__();
    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };

    let mut permission_addresses = ArrayTrait::new();
    permission_addresses.append(USER_SIX.try_into().unwrap());
    permission_addresses.append(USER_FIVE.try_into().unwrap());
    permission_addresses.append(USER_THREE.try_into().unwrap());

    // create community
    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_community();

    // gatekeep community
    communityDispatcher
        .gatekeep(
            community_id,
            GateKeepType::PermissionedGating,
            contract_address_const::<0>(),
            permission_addresses,
            (contract_address_const::<0>(), 0)
        );

    // try to join a community when not permissioned
    start_cheat_caller_address(community_contract_address, USER_TWO.try_into().unwrap());
    communityDispatcher.join_community(community_id);
    stop_cheat_caller_address(community_contract_address);
}

#[test]
#[should_panic(expected: ('Karst: user unauthorized!',))]
fn test_nft_gating_is_enforced_on_joining() {
    let (community_contract_address, usdt_contract_address) = __setup__();
    let communityDispatcher = ICommunityDispatcher { contract_address: community_contract_address };
    let joltDispatcher = IJoltDispatcher { contract_address: community_contract_address };
    let erc20_dispatcher = IERC20Dispatcher { contract_address: usdt_contract_address };

    // deploy nft to be used for gating
    let erc721_contract = declare("ERC721").unwrap().contract_class();
    let mut erc721_constructor_calldata = array!['TEST_NFT', 'NFT'];
    let (erc721_contract_address, _) = erc721_contract
        .deploy(@erc721_constructor_calldata)
        .unwrap();

    // mint nft to a permissioned user
    let dispatcher = IERC721Dispatcher { contract_address: erc721_contract_address };
    dispatcher.mint(USER_TWO.try_into().unwrap(), 1.try_into().unwrap());

    // create subscription
    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let sub_id = joltDispatcher
        .create_subscription(ADMIN.try_into().unwrap(), 1000000000000000000, usdt_contract_address);
    stop_cheat_caller_address(community_contract_address);

    // approve contract to spend amount
    start_cheat_caller_address(usdt_contract_address, USER_ONE.try_into().unwrap());
    erc20_dispatcher.approve(community_contract_address, 4000000000000000000);
    stop_cheat_caller_address(usdt_contract_address);

    // upgrade community
    start_cheat_caller_address(community_contract_address, USER_ONE.try_into().unwrap());
    let community_id = communityDispatcher.create_community();
    communityDispatcher.upgrade_community(community_id, CommunityType::Business, sub_id, false, 0);

    // gatekeep community
    communityDispatcher
        .gatekeep(
            community_id,
            GateKeepType::NFTGating,
            erc721_contract_address,
            array![contract_address_const::<0>()],
            (contract_address_const::<0>(), 0)
        );

    // try to join community with an address that has the required NFT
    start_cheat_caller_address(community_contract_address, USER_TWO.try_into().unwrap());
    communityDispatcher.join_community(community_id);
    stop_cheat_caller_address(community_contract_address);

    // check user joined successfully
    let (is_member, _) = communityDispatcher
        .is_community_member(USER_TWO.try_into().unwrap(), community_id);
    assert(is_member == true, 'owner is not a member');

    // try joining with another address that does not have the required NFT
    start_cheat_caller_address(community_contract_address, USER_THREE.try_into().unwrap());
    communityDispatcher.join_community(community_id);
    stop_cheat_caller_address(community_contract_address);
}
