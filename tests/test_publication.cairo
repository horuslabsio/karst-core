// *************************************************************************
//                              PUBLICATION TEST
// *************************************************************************
use core::option::OptionTrait;
use core::starknet::SyscallResultTrait;
use core::result::ResultTrait;
use core::traits::{TryInto, Into};
use starknet::{ContractAddress, get_block_timestamp};
use core::hash::HashStateTrait;
use core::pedersen::PedersenTrait;
use snforge_std::{
    declare, start_cheat_caller_address, stop_cheat_caller_address, spy_events,
    EventSpyAssertionsTrait, ContractClassTrait, DeclareResultTrait, EventSpy
};
use karst::publication::publication::PublicationComponent::{
    Event as PublicationEvent, Post, CommentCreated, RepostCreated, Upvoted, Downvoted
};
use karst::mocks::interfaces::IComposable::{IComposableDispatcher, IComposableDispatcherTrait};
use karst::base::constants::types::{
    PostParams, RepostParams, CommentParams, PublicationType, UpVoteParams, DownVoteParams,
    TipParams, CollectParams
};
use karst::interfaces::ICollectNFT::{ICollectNFTDispatcher, ICollectNFTDispatcherTrait};
use karst::interfaces::ICommunity::{ICommunityDispatcher, ICommunityDispatcherTrait};
use karst::interfaces::IChannel::{IChannelDispatcher, IChannelDispatcherTrait};
use karst::interfaces::IERC20::{IERC20Dispatcher, IERC20DispatcherTrait};


const HUB_ADDRESS: felt252 = 'HUB';
const USER_ONE: felt252 = 'BOB';
const USER_TWO: felt252 = 'ALICE';
const USER_THREE: felt252 = 'ROB';
const USER_FOUR: felt252 = 'DAN';
const USER_FIVE: felt252 = 'RANDY';
const USER_SIX: felt252 = 'JOE';
const ADMIN: felt252 = 'ADMIN';


// *************************************************************************
//                              SETUP
// *************************************************************************
fn __setup__() -> (
    ContractAddress,
    ContractAddress,
    ContractAddress,
    felt252,
    felt252,
    felt252,
    EventSpy,
    ContractAddress
) {
    // deploy NFT
    let nft_contract = declare("KarstNFT").unwrap().contract_class();
    let mut calldata: Array<felt252> = array![USER_ONE];

    let (nft_contract_address, _) = nft_contract.deploy(@calldata).unwrap_syscall();

    // deploy registry
    let registry_class_hash = declare("Registry").unwrap().contract_class();
    let (registry_contract_address, _) = registry_class_hash.deploy(@array![]).unwrap_syscall();
    // declare follownft
    let follow_nft_classhash = declare("Follow").unwrap().contract_class();
    // declare channel_nft
    let channel_nft_classhash = declare("ChannelNFT").unwrap().contract_class();
    // declare community_nft
    let community_nft_classhash = declare("CommunityNFT").unwrap().contract_class();
    // deploy publication preset
    let publication_contract = declare("KarstPublication").unwrap().contract_class();
    let mut publication_constructor_calldata = array![
        nft_contract_address.into(),
        HUB_ADDRESS,
        (*follow_nft_classhash.class_hash).into(),
        (*channel_nft_classhash.class_hash).into(),
        (*community_nft_classhash.class_hash).into(),
        ADMIN
    ];

    let (publication_contract_address, _) = publication_contract
        .deploy(@publication_constructor_calldata)
        .unwrap_syscall();
    // deploy mock USDT
    let usdt_contract = declare("USDT").unwrap().contract_class();
    let (usdt_contract_address, _) = usdt_contract
        .deploy(@array![1000000000000000000000, 0, USER_TWO])
        .unwrap();

    // declare account
    let account_class_hash = declare("Account").unwrap().contract_class();

    //declare collectnft
    let collect_nft_classhash = declare("CollectNFT").unwrap().contract_class();
    // spy
    let mut spy = spy_events();
    return (
        nft_contract_address,
        registry_contract_address,
        publication_contract_address,
        (*registry_class_hash.class_hash).into(),
        (*account_class_hash.class_hash).into(),
        (*collect_nft_classhash.class_hash).into(),
        spy,
        usdt_contract_address
    );
}

// *************************************************************************
//                              TEST
// *************************************************************************

#[test]
fn test_post() {
    let (
        nft_contract_address,
        _,
        publication_contract_address,
        registry_class_hash,
        account_class_hash,
        _,
        _,
        _
    ) =
        __setup__();
    let publication_dispatcher = IComposableDispatcher {
        contract_address: publication_contract_address
    };
    let channel_dispatcher = IChannelDispatcher { contract_address: publication_contract_address };
    let community_dispatcher = ICommunityDispatcher {
        contract_address: publication_contract_address
    };
    let content_URI: ByteArray = "ipfs://helloworld";

    start_cheat_caller_address(publication_contract_address, USER_ONE.try_into().unwrap());
    // Create profile
    let user_one_profile_address = publication_dispatcher
        .create_profile(nft_contract_address, registry_class_hash, account_class_hash, 2478);
    // Check if community is created
    let community_id = community_dispatcher.create_community();
    // Check if community is created
    let channel_id = channel_dispatcher.create_channel(community_id);
    // Attempt to post
    let pub_assigned_id = publication_dispatcher
        .post(
            PostParams {
                content_URI: content_URI,
                profile_address: user_one_profile_address,
                channel_id: channel_id,
                community_id: community_id
            }
        );
    assert(pub_assigned_id == 1, 'invalid_publication_id');
    stop_cheat_caller_address(publication_contract_address);
}
#[test]
fn test_upvote() {
    let (
        nft_contract_address,
        _,
        publication_contract_address,
        registry_class_hash,
        account_class_hash,
        _,
        _,
        _
    ) =
        __setup__();
    let publication_dispatcher = IComposableDispatcher {
        contract_address: publication_contract_address
    };
    let channel_dispatcher = IChannelDispatcher { contract_address: publication_contract_address };
    let community_dispatcher = ICommunityDispatcher {
        contract_address: publication_contract_address
    };
    let content_URI2: ByteArray = "ipfs://helloworld";

    start_cheat_caller_address(publication_contract_address, USER_TWO.try_into().unwrap());
    let user_two_profile_address = publication_dispatcher
        .create_profile(nft_contract_address, registry_class_hash, account_class_hash, 2478);
    let community_id = community_dispatcher.create_community();
    let channel_id = channel_dispatcher.create_channel(community_id);
    let pub_assigned_id = publication_dispatcher
        .post(
            PostParams {
                content_URI: content_URI2,
                profile_address: user_two_profile_address,
                channel_id: channel_id,
                community_id: community_id
            }
        );
    publication_dispatcher
        .upvote(
            UpVoteParams {
                profile_address: user_two_profile_address,
                channel_id: channel_id,
                community_id: community_id,
                pub_id: pub_assigned_id
            }
        );
    let upvote_count = publication_dispatcher
        .get_upvote_count(user_two_profile_address, pub_assigned_id);
    assert(upvote_count == 1, 'invalid upvote count');
    stop_cheat_caller_address(publication_contract_address);
}

#[test]
fn test_downvote() {
    let (
        nft_contract_address,
        _,
        publication_contract_address,
        registry_class_hash,
        account_class_hash,
        _,
        _,
        _
    ) =
        __setup__();
    let publication_dispatcher = IComposableDispatcher {
        contract_address: publication_contract_address
    };
    let channel_dispatcher = IChannelDispatcher { contract_address: publication_contract_address };
    let community_dispatcher = ICommunityDispatcher {
        contract_address: publication_contract_address
    };
    let content_URI2: ByteArray = "ipfs://helloworld";

    start_cheat_caller_address(publication_contract_address, USER_TWO.try_into().unwrap());
    let user_two_profile_address = publication_dispatcher
        .create_profile(nft_contract_address, registry_class_hash, account_class_hash, 2478);
    let community_id = community_dispatcher.create_community();
    let channel_id = channel_dispatcher.create_channel(community_id);
    let pub_assigned_id = publication_dispatcher
        .post(
            PostParams {
                content_URI: content_URI2,
                profile_address: user_two_profile_address,
                channel_id: channel_id,
                community_id: community_id
            }
        );
    publication_dispatcher
        .downvote(
            DownVoteParams {
                profile_address: user_two_profile_address,
                channel_id: channel_id,
                community_id: community_id,
                pub_id: pub_assigned_id
            }
        );
    let downvote_count = publication_dispatcher
        .get_downvote_count(user_two_profile_address, pub_assigned_id);
    assert(downvote_count == 1, 'invalid upvote count');
    stop_cheat_caller_address(publication_contract_address);
}
#[test]
fn test_upvote_event_emission() {
    let (
        nft_contract_address,
        _,
        publication_contract_address,
        registry_class_hash,
        account_class_hash,
        _,
        spy,
        _
    ) =
        __setup__();

    let mut spy = spy;
    let publication_dispatcher = IComposableDispatcher {
        contract_address: publication_contract_address
    };

    let channel_dispatcher = IChannelDispatcher { contract_address: publication_contract_address };
    let community_dispatcher = ICommunityDispatcher {
        contract_address: publication_contract_address
    };
    let content_URI: ByteArray = "ipfs://helloworld";
    start_cheat_caller_address(publication_contract_address, USER_ONE.try_into().unwrap());
    let user_one_profile_address = publication_dispatcher
        .create_profile(nft_contract_address, registry_class_hash, account_class_hash, 2478);

    let community_id = community_dispatcher.create_community();
    let channel_id = channel_dispatcher.create_channel(community_id);
    let pub_assigned_id = publication_dispatcher
        .post(
            PostParams {
                content_URI: content_URI,
                profile_address: user_one_profile_address,
                channel_id: channel_id,
                community_id: community_id
            }
        );
    stop_cheat_caller_address(publication_contract_address);

    start_cheat_caller_address(publication_contract_address, USER_TWO.try_into().unwrap());
    community_dispatcher.join_community(community_id);
    channel_dispatcher.join_channel(channel_id);
    publication_dispatcher
        .upvote(
            UpVoteParams {
                profile_address: user_one_profile_address,
                channel_id: channel_id,
                community_id: community_id,
                pub_id: pub_assigned_id
            }
        );
    let expected_event = PublicationEvent::Upvoted(
        Upvoted {
            publication_id: pub_assigned_id,
            transaction_executor: USER_TWO.try_into().unwrap(),
            block_timestamp: get_block_timestamp()
        }
    );
    spy.assert_emitted(@array![(publication_contract_address, expected_event)]);
    stop_cheat_caller_address(publication_contract_address);
}

#[test]
fn test_downvote_event_emission() {
    let (
        nft_contract_address,
        _,
        publication_contract_address,
        registry_class_hash,
        account_class_hash,
        _,
        spy,
        _
    ) =
        __setup__();

    let mut spy = spy;
    let publication_dispatcher = IComposableDispatcher {
        contract_address: publication_contract_address
    };

    let channel_dispatcher = IChannelDispatcher { contract_address: publication_contract_address };
    let community_dispatcher = ICommunityDispatcher {
        contract_address: publication_contract_address
    };
    let content_URI: ByteArray = "ipfs://helloworld";
    start_cheat_caller_address(publication_contract_address, USER_ONE.try_into().unwrap());
    let user_one_profile_address = publication_dispatcher
        .create_profile(nft_contract_address, registry_class_hash, account_class_hash, 2478);

    let community_id = community_dispatcher.create_community();
    let channel_id = channel_dispatcher.create_channel(community_id);
    let pub_assigned_id = publication_dispatcher
        .post(
            PostParams {
                content_URI: content_URI,
                profile_address: user_one_profile_address,
                channel_id: channel_id,
                community_id: community_id
            }
        );
    stop_cheat_caller_address(publication_contract_address);

    start_cheat_caller_address(publication_contract_address, USER_TWO.try_into().unwrap());
    community_dispatcher.join_community(community_id);
    channel_dispatcher.join_channel(channel_id);
    publication_dispatcher
        .downvote(
            DownVoteParams {
                profile_address: user_one_profile_address,
                channel_id: channel_id,
                community_id: community_id,
                pub_id: pub_assigned_id
            }
        );
    let expected_event = PublicationEvent::Downvoted(
        Downvoted {
            publication_id: pub_assigned_id,
            transaction_executor: USER_TWO.try_into().unwrap(),
            block_timestamp: get_block_timestamp()
        }
    );
    spy.assert_emitted(@array![(publication_contract_address, expected_event)]);
    stop_cheat_caller_address(publication_contract_address);
}

#[test]
#[should_panic(expected: ('Karst: already react to post!',))]
fn test_upvote_should_fail_if_user_already_upvoted() {
    let (
        nft_contract_address,
        _,
        publication_contract_address,
        registry_class_hash,
        account_class_hash,
        _,
        _,
        _
    ) =
        __setup__();
    let publication_dispatcher = IComposableDispatcher {
        contract_address: publication_contract_address
    };
    let channel_dispatcher = IChannelDispatcher { contract_address: publication_contract_address };
    let community_dispatcher = ICommunityDispatcher {
        contract_address: publication_contract_address
    };
    let content_URI2: ByteArray = "ipfs://helloworld";

    start_cheat_caller_address(publication_contract_address, USER_TWO.try_into().unwrap());
    let user_two_profile_address = publication_dispatcher
        .create_profile(nft_contract_address, registry_class_hash, account_class_hash, 2478);
    let community_id = community_dispatcher.create_community();
    let channel_id = channel_dispatcher.create_channel(community_id);
    let pub_assigned_id = publication_dispatcher
        .post(
            PostParams {
                content_URI: content_URI2,
                profile_address: user_two_profile_address,
                channel_id: channel_id,
                community_id: community_id
            }
        );
    publication_dispatcher
        .upvote(
            UpVoteParams {
                profile_address: user_two_profile_address,
                channel_id: channel_id,
                community_id: community_id,
                pub_id: pub_assigned_id
            }
        );
    publication_dispatcher
        .upvote(
            UpVoteParams {
                profile_address: user_two_profile_address,
                channel_id: channel_id,
                community_id: community_id,
                pub_id: pub_assigned_id
            }
        );
    stop_cheat_caller_address(publication_contract_address);
}

#[test]
#[should_panic(expected: ('Karst: already react to post!',))]
fn test_downvote_should_fail_if_user_already_downvoted() {
    let (
        nft_contract_address,
        _,
        publication_contract_address,
        registry_class_hash,
        account_class_hash,
        _,
        _,
        _
    ) =
        __setup__();
    let publication_dispatcher = IComposableDispatcher {
        contract_address: publication_contract_address
    };
    let channel_dispatcher = IChannelDispatcher { contract_address: publication_contract_address };
    let community_dispatcher = ICommunityDispatcher {
        contract_address: publication_contract_address
    };
    let content_URI2: ByteArray = "ipfs://helloworld";

    start_cheat_caller_address(publication_contract_address, USER_TWO.try_into().unwrap());
    let user_two_profile_address = publication_dispatcher
        .create_profile(nft_contract_address, registry_class_hash, account_class_hash, 2478);
    let community_id = community_dispatcher.create_community();
    let channel_id = channel_dispatcher.create_channel(community_id);
    let pub_assigned_id = publication_dispatcher
        .post(
            PostParams {
                content_URI: content_URI2,
                profile_address: user_two_profile_address,
                channel_id: channel_id,
                community_id: community_id
            }
        );
    publication_dispatcher
        .downvote(
            DownVoteParams {
                profile_address: user_two_profile_address,
                channel_id: channel_id,
                community_id: community_id,
                pub_id: pub_assigned_id
            }
        );
    publication_dispatcher
        .downvote(
            DownVoteParams {
                profile_address: user_two_profile_address,
                channel_id: channel_id,
                community_id: community_id,
                pub_id: pub_assigned_id
            }
        );
    stop_cheat_caller_address(publication_contract_address);
}

#[test]
fn test_post_event_emission() {
    let (
        nft_contract_address,
        _,
        publication_contract_address,
        registry_class_hash,
        account_class_hash,
        _,
        spy,
        _
    ) =
        __setup__();

    let mut spy = spy;

    let publication_dispatcher = IComposableDispatcher {
        contract_address: publication_contract_address
    };
    let channel_dispatcher = IChannelDispatcher { contract_address: publication_contract_address };
    let community_dispatcher = ICommunityDispatcher {
        contract_address: publication_contract_address
    };
    let content_URI: ByteArray = "ipfs://helloworld";
    start_cheat_caller_address(publication_contract_address, USER_ONE.try_into().unwrap());
    let user_one_profile_address = publication_dispatcher
        .create_profile(nft_contract_address, registry_class_hash, account_class_hash, 2478);

    let community_id = community_dispatcher.create_community();
    let channel_id = channel_dispatcher.create_channel(community_id);
    let pub_assigned_id = publication_dispatcher
        .post(
            PostParams {
                content_URI: content_URI,
                profile_address: user_one_profile_address,
                channel_id: channel_id,
                community_id: community_id
            }
        );
    let expected_event = PublicationEvent::Post(
        Post {
            post: PostParams {
                content_URI: "ipfs://helloworld",
                profile_address: user_one_profile_address,
                channel_id: channel_id,
                community_id: community_id
            },
            publication_id: pub_assigned_id,
            transaction_executor: user_one_profile_address,
            block_timestamp: get_block_timestamp()
        }
    );

    spy.assert_emitted(@array![(publication_contract_address, expected_event)]);
    stop_cheat_caller_address(publication_contract_address);
}


#[test]
fn test_comment() {
    let (
        nft_contract_address,
        _,
        publication_contract_address,
        registry_class_hash,
        account_class_hash,
        _,
        _,
        _
    ) =
        __setup__();

    let publication_dispatcher = IComposableDispatcher {
        contract_address: publication_contract_address
    };
    let channel_dispatcher = IChannelDispatcher { contract_address: publication_contract_address };
    let community_dispatcher = ICommunityDispatcher {
        contract_address: publication_contract_address
    };
    let content_URI: ByteArray = "ipfs://helloworld";
    start_cheat_caller_address(publication_contract_address, USER_ONE.try_into().unwrap());
    let user_one_profile_address = publication_dispatcher
        .create_profile(nft_contract_address, registry_class_hash, account_class_hash, 2478);

    let community_id = community_dispatcher.create_community();
    let channel_id = channel_dispatcher.create_channel(community_id);
    let pub_assigned_id = publication_dispatcher
        .post(
            PostParams {
                content_URI: content_URI,
                profile_address: user_one_profile_address,
                channel_id: channel_id,
                community_id: community_id
            }
        );
    stop_cheat_caller_address(publication_contract_address);

    start_cheat_caller_address(publication_contract_address, USER_TWO.try_into().unwrap());
    let user_two_profile_address = publication_dispatcher
        .create_profile(nft_contract_address, registry_class_hash, account_class_hash, 2478);
    community_dispatcher.join_community(community_id);
    channel_dispatcher.join_channel(channel_id);
    let content_URI_1 = "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaryrga/";

    let user_one_comment_assigned_pub_id_1 = publication_dispatcher
        .comment(
            CommentParams {
                profile_address: user_two_profile_address,
                content_URI: content_URI_1,
                pointed_profile_address: user_one_profile_address,
                pointed_pub_id: pub_assigned_id,
                reference_pub_type: PublicationType::Comment,
                channel_id: channel_id,
                community_id: community_id
            }
        );
    stop_cheat_caller_address(publication_contract_address);

    let user_one_comment = publication_dispatcher
        .get_publication(user_two_profile_address, user_one_comment_assigned_pub_id_1);

    assert(
        user_one_comment.pointed_profile_address == user_one_profile_address,
        'invalid pointed profile address'
    );
    assert(user_one_comment.pointed_pub_id == pub_assigned_id, 'invalid pointed publication ID');
    assert(
        user_one_comment.content_URI == "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaryrga/",
        'invalid content URI'
    );
    assert(user_one_comment.pub_Type == PublicationType::Comment, 'invalid pub_type');
    assert(
        user_one_comment.root_profile_address == user_one_profile_address,
        'invalid root profile address'
    );
    assert(user_one_comment.root_pub_id == pub_assigned_id, 'invalid root publication ID');
}

#[test]
fn test_comment_event_emission() {
    let (
        nft_contract_address,
        _,
        publication_contract_address,
        registry_class_hash,
        account_class_hash,
        _,
        spy,
        _
    ) =
        __setup__();

    let mut spy = spy;
    let content_URI_1 = "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZysddewga/";

    let publication_dispatcher = IComposableDispatcher {
        contract_address: publication_contract_address
    };
    let channel_dispatcher = IChannelDispatcher { contract_address: publication_contract_address };
    let community_dispatcher = ICommunityDispatcher {
        contract_address: publication_contract_address
    };
    let content_URI: ByteArray = "ipfs://helloworld";
    start_cheat_caller_address(publication_contract_address, USER_ONE.try_into().unwrap());
    let user_one_profile_address = publication_dispatcher
        .create_profile(nft_contract_address, registry_class_hash, account_class_hash, 2478);

    let community_id = community_dispatcher.create_community();
    let channel_id = channel_dispatcher.create_channel(community_id);
    let pub_assigned_id = publication_dispatcher
        .post(
            PostParams {
                content_URI: content_URI,
                profile_address: user_one_profile_address,
                channel_id: channel_id,
                community_id: community_id
            }
        );
    stop_cheat_caller_address(publication_contract_address);

    start_cheat_caller_address(publication_contract_address, USER_TWO.try_into().unwrap());
    let user_two_profile_address = publication_dispatcher
        .create_profile(nft_contract_address, registry_class_hash, account_class_hash, 2478);
    community_dispatcher.join_community(community_id);
    channel_dispatcher.join_channel(channel_id);
    let user_two_comment_on_user_one_assigned_pub_id = publication_dispatcher
        .comment(
            CommentParams {
                profile_address: user_two_profile_address,
                content_URI: content_URI_1,
                pointed_profile_address: user_one_profile_address,
                pointed_pub_id: pub_assigned_id,
                reference_pub_type: PublicationType::Comment,
                channel_id: channel_id,
                community_id: community_id
            }
        );
    stop_cheat_caller_address(publication_contract_address);

    let expected_event = PublicationEvent::CommentCreated(
        CommentCreated {
            commentParams: CommentParams {
                profile_address: user_two_profile_address,
                content_URI: "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZysddewga/",
                pointed_profile_address: user_one_profile_address,
                pointed_pub_id: pub_assigned_id,
                reference_pub_type: PublicationType::Comment,
                channel_id: channel_id,
                community_id: community_id
            },
            publication_id: user_two_comment_on_user_one_assigned_pub_id,
            transaction_executor: user_two_profile_address,
            block_timestamp: get_block_timestamp(),
        }
    );

    spy.assert_emitted(@array![(publication_contract_address, expected_event)]);
}


#[test]
fn test_repost() {
    let (
        nft_contract_address,
        _,
        publication_contract_address,
        registry_class_hash,
        account_class_hash,
        _,
        _,
        _
    ) =
        __setup__();

    let publication_dispatcher = IComposableDispatcher {
        contract_address: publication_contract_address
    };
    let channel_dispatcher = IChannelDispatcher { contract_address: publication_contract_address };
    let community_dispatcher = ICommunityDispatcher {
        contract_address: publication_contract_address
    };
    let content_URI: ByteArray = "ipfs://helloworld";
    start_cheat_caller_address(publication_contract_address, USER_ONE.try_into().unwrap());
    let user_one_profile_address = publication_dispatcher
        .create_profile(nft_contract_address, registry_class_hash, account_class_hash, 2478);

    let community_id = community_dispatcher.create_community();
    let channel_id = channel_dispatcher.create_channel(community_id);
    let pub_assigned_id = publication_dispatcher
        .post(
            PostParams {
                content_URI: content_URI,
                profile_address: user_one_profile_address,
                channel_id: channel_id,
                community_id: community_id
            }
        );
    stop_cheat_caller_address(publication_contract_address);

    start_cheat_caller_address(publication_contract_address, USER_TWO.try_into().unwrap());
    let user_two_profile_address = publication_dispatcher
        .create_profile(nft_contract_address, registry_class_hash, account_class_hash, 2478);
    community_dispatcher.join_community(community_id);
    channel_dispatcher.join_channel(channel_id);
    let repost_params = RepostParams {
        profile_address: user_two_profile_address,
        pointed_profile_address: user_one_profile_address,
        pointed_pub_id: pub_assigned_id,
        channel_id: channel_id,
        community_id: community_id
    };
    let pub_assigned_id = publication_dispatcher.repost(repost_params);
    stop_cheat_caller_address(publication_contract_address);

    // get the repost publication
    let user_repost = publication_dispatcher
        .get_publication(user_two_profile_address, pub_assigned_id);

    assert(
        user_repost.pointed_profile_address == user_one_profile_address,
        'invalid pointed profile address'
    );
    assert(user_repost.pointed_pub_id == pub_assigned_id, 'invalid pointed publication ID');
    assert(user_repost.content_URI == "ipfs://helloworld", 'invalid content URI');
    assert(user_repost.pub_Type == PublicationType::Repost, 'invalid pub_type');
    assert(
        user_repost.root_profile_address == user_one_profile_address, 'invalid root profile address'
    );
    assert(user_repost.root_pub_id == pub_assigned_id, 'invalid root publication ID');
}

#[test]
fn test_repost_event_emission() {
    let (
        nft_contract_address,
        _,
        publication_contract_address,
        registry_class_hash,
        account_class_hash,
        _,
        spy,
        _
    ) =
        __setup__();

    let publication_dispatcher = IComposableDispatcher {
        contract_address: publication_contract_address
    };
    let channel_dispatcher = IChannelDispatcher { contract_address: publication_contract_address };
    let community_dispatcher = ICommunityDispatcher {
        contract_address: publication_contract_address
    };
    let content_URI: ByteArray = "ipfs://helloworld";
    start_cheat_caller_address(publication_contract_address, USER_ONE.try_into().unwrap());
    let user_one_profile_address = publication_dispatcher
        .create_profile(nft_contract_address, registry_class_hash, account_class_hash, 2478);

    let community_id = community_dispatcher.create_community();
    let channel_id = channel_dispatcher.create_channel(community_id);
    let post_pub_assigned_id = publication_dispatcher
        .post(
            PostParams {
                content_URI: content_URI,
                profile_address: user_one_profile_address,
                channel_id: channel_id,
                community_id: community_id
            }
        );
    stop_cheat_caller_address(publication_contract_address);
    let mut spy = spy;

    start_cheat_caller_address(publication_contract_address, USER_TWO.try_into().unwrap());
    let user_two_profile_address = publication_dispatcher
        .create_profile(nft_contract_address, registry_class_hash, account_class_hash, 2478);
    community_dispatcher.join_community(community_id);
    channel_dispatcher.join_channel(channel_id);
    let repost_params = RepostParams {
        profile_address: user_two_profile_address,
        pointed_profile_address: user_one_profile_address,
        pointed_pub_id: post_pub_assigned_id,
        channel_id: channel_id,
        community_id: community_id
    };
    let pub_assigned_id = publication_dispatcher.repost(repost_params);
    stop_cheat_caller_address(publication_contract_address);

    // get the repost publication
    let user_repost = publication_dispatcher
        .get_publication(user_two_profile_address, pub_assigned_id);

    let expected_event = PublicationEvent::RepostCreated(
        RepostCreated {
            repostParams: RepostParams {
                profile_address: user_two_profile_address,
                pointed_profile_address: user_repost.pointed_profile_address,
                pointed_pub_id: user_repost.pointed_pub_id,
                channel_id: channel_id,
                community_id: community_id
            },
            publication_id: pub_assigned_id,
            transaction_executor: user_two_profile_address,
            block_timestamp: get_block_timestamp(),
        }
    );

    spy.assert_emitted(@array![(publication_contract_address, expected_event)]);
}


#[test]
fn test_get_publication_content_uri() {
    let (
        nft_contract_address,
        _,
        publication_contract_address,
        registry_class_hash,
        account_class_hash,
        _,
        _,
        _
    ) =
        __setup__();
    let publication_dispatcher = IComposableDispatcher {
        contract_address: publication_contract_address
    };
    let channel_dispatcher = IChannelDispatcher { contract_address: publication_contract_address };
    let community_dispatcher = ICommunityDispatcher {
        contract_address: publication_contract_address
    };
    let content_URI: ByteArray = "ipfs://helloworld";
    start_cheat_caller_address(publication_contract_address, USER_ONE.try_into().unwrap());
    let user_one_profile_address = publication_dispatcher
        .create_profile(nft_contract_address, registry_class_hash, account_class_hash, 2478);

    let community_id = community_dispatcher.create_community();
    let channel_id = channel_dispatcher.create_channel(community_id);
    let pub_assigned_id = publication_dispatcher
        .post(
            PostParams {
                content_URI: content_URI,
                profile_address: user_one_profile_address,
                channel_id: channel_id,
                community_id: community_id
            }
        );
    let content_uri = publication_dispatcher
        .get_publication_content_uri(user_one_profile_address, pub_assigned_id);
    assert(content_uri == "ipfs://helloworld", 'invalid uri');
    stop_cheat_caller_address(publication_contract_address);
}

#[test]
fn test_get_publication_type() {
    let (
        nft_contract_address,
        _,
        publication_contract_address,
        registry_class_hash,
        account_class_hash,
        _,
        _,
        _
    ) =
        __setup__();
    let publication_dispatcher = IComposableDispatcher {
        contract_address: publication_contract_address
    };
    let channel_dispatcher = IChannelDispatcher { contract_address: publication_contract_address };
    let community_dispatcher = ICommunityDispatcher {
        contract_address: publication_contract_address
    };
    let content_URI: ByteArray = "ipfs://helloworld";
    start_cheat_caller_address(publication_contract_address, USER_ONE.try_into().unwrap());
    let user_one_profile_address = publication_dispatcher
        .create_profile(nft_contract_address, registry_class_hash, account_class_hash, 2478);

    let community_id = community_dispatcher.create_community();
    let channel_id = channel_dispatcher.create_channel(community_id);
    let pub_assigned_id = publication_dispatcher
        .post(
            PostParams {
                content_URI: content_URI,
                profile_address: user_one_profile_address,
                channel_id: channel_id,
                community_id: community_id
            }
        );
    let pub_type = publication_dispatcher
        .get_publication_type(user_one_profile_address, pub_assigned_id);
    assert(pub_type == PublicationType::Post, 'invalid pub type');
    stop_cheat_caller_address(publication_contract_address);
}

#[test]
#[should_panic(expected: ('Karst: Profile is banned!',))]
fn test_should_fail_if_banned_profile_from_posting() {
    let (
        nft_contract_address,
        _,
        publication_contract_address,
        registry_class_hash,
        account_class_hash,
        _,
        _,
        _
    ) =
        __setup__();

    let publication_dispatcher = IComposableDispatcher {
        contract_address: publication_contract_address
    };
    let channel_dispatcher = IChannelDispatcher { contract_address: publication_contract_address };
    let community_dispatcher = ICommunityDispatcher {
        contract_address: publication_contract_address
    };
    let content_URI: ByteArray = "ipfs://helloworld";
    let content_URI2: ByteArray = "ipfs://helloworld";

    start_cheat_caller_address(publication_contract_address, USER_ONE.try_into().unwrap());
    // Create profile
    let user_one_profile_address = publication_dispatcher
        .create_profile(nft_contract_address, registry_class_hash, account_class_hash, 2478);
    // Check if community is created
    let community_id = community_dispatcher.create_community();
    // Check if community is created
    let channel_id = channel_dispatcher.create_channel(community_id);
    // Attempt to post
    let _pub_assigned_id = publication_dispatcher
        .post(
            PostParams {
                content_URI: content_URI,
                profile_address: user_one_profile_address,
                channel_id: channel_id,
                community_id: community_id
            }
        );
    start_cheat_caller_address(publication_contract_address, USER_TWO.try_into().unwrap());
    let user_one_profile_address = publication_dispatcher
        .create_profile(nft_contract_address, registry_class_hash, account_class_hash, 2478);
    community_dispatcher.join_community(community_id);
    channel_dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(publication_contract_address);

    //set ban
    start_cheat_caller_address(publication_contract_address, USER_ONE.try_into().unwrap());
    let mut profiles = ArrayTrait::new();
    profiles.append(USER_TWO.try_into().unwrap());
    let mut ban_statuses = ArrayTrait::new();
    ban_statuses.append(true);
    community_dispatcher.set_ban_status(community_id, profiles, ban_statuses);

    start_cheat_caller_address(publication_contract_address, USER_TWO.try_into().unwrap());
    let _pub_assigned_id = publication_dispatcher
        .post(
            PostParams {
                content_URI: content_URI2,
                profile_address: user_one_profile_address,
                channel_id: channel_id,
                community_id: community_id
            }
        );
    stop_cheat_caller_address(publication_contract_address);
}

#[test]
#[should_panic(expected: ('Karst: Not a Community  Member',))]
fn test_should_fail_if_not_community_member_while_posting() {
    let (
        nft_contract_address,
        _,
        publication_contract_address,
        registry_class_hash,
        account_class_hash,
        _,
        _,
        _
    ) =
        __setup__();
    let publication_dispatcher = IComposableDispatcher {
        contract_address: publication_contract_address
    };
    let channel_dispatcher = IChannelDispatcher { contract_address: publication_contract_address };
    let community_dispatcher = ICommunityDispatcher {
        contract_address: publication_contract_address
    };
    let content_URI: ByteArray = "ipfs://helloworld";
    let content_URI2: ByteArray = "ipfs://helloworld!";

    start_cheat_caller_address(publication_contract_address, USER_ONE.try_into().unwrap());
    let user_one_profile_address = publication_dispatcher
        .create_profile(nft_contract_address, registry_class_hash, account_class_hash, 2478);
    let community_id = community_dispatcher.create_community();
    let channel_id = channel_dispatcher.create_channel(community_id);
    let _pub_assigned_id = publication_dispatcher
        .post(
            PostParams {
                content_URI: content_URI,
                profile_address: user_one_profile_address,
                channel_id: channel_id,
                community_id: community_id
            }
        );
    stop_cheat_caller_address(publication_contract_address);
    start_cheat_caller_address(publication_contract_address, USER_TWO.try_into().unwrap());
    let user_two_profile_address = publication_dispatcher
        .create_profile(nft_contract_address, registry_class_hash, account_class_hash, 24998);
    let _pub_assigned_id = publication_dispatcher
        .post(
            PostParams {
                content_URI: content_URI2,
                profile_address: user_two_profile_address,
                channel_id: channel_id,
                community_id: community_id
            }
        );
    stop_cheat_caller_address(publication_contract_address);
}

#[test]
fn test_tip() {
    let (
        nft_contract_address,
        _,
        publication_contract_address,
        registry_class_hash,
        account_class_hash,
        _,
        _,
        erc20_contract_address
    ) =
        __setup__();
    let publication_dispatcher = IComposableDispatcher {
        contract_address: publication_contract_address
    };
    let channel_dispatcher = IChannelDispatcher { contract_address: publication_contract_address };
    let community_dispatcher = ICommunityDispatcher {
        contract_address: publication_contract_address
    };
    let erc20_dispatcher = IERC20Dispatcher { contract_address: erc20_contract_address };
    let content_URI: ByteArray = "ipfs://helloworld";

    start_cheat_caller_address(publication_contract_address, USER_ONE.try_into().unwrap());
    // Create profile
    let user_one_profile_address = publication_dispatcher
        .create_profile(nft_contract_address, registry_class_hash, account_class_hash, 2478);
    // Check if community is created
    let community_id = community_dispatcher.create_community();
    // Check if community is created
    let channel_id = channel_dispatcher.create_channel(community_id);
    // Attempt to post
    let pub_assigned_id = publication_dispatcher
        .post(
            PostParams {
                content_URI: content_URI,
                profile_address: user_one_profile_address,
                channel_id: channel_id,
                community_id: community_id
            }
        );
    stop_cheat_caller_address(publication_contract_address);
    // USER_TWO joins community
    start_cheat_caller_address(publication_contract_address, USER_TWO.try_into().unwrap());
    let _user_two_profile_address = publication_dispatcher
        .create_profile(nft_contract_address, registry_class_hash, account_class_hash, 2478);
    community_dispatcher.join_community(community_id);
    channel_dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(publication_contract_address);

    start_cheat_caller_address(erc20_contract_address, USER_TWO.try_into().unwrap());
    // approve contract to spend amount
    erc20_dispatcher.approve(publication_contract_address, 2000000000000000000);
    stop_cheat_caller_address(erc20_contract_address);

    start_cheat_caller_address(publication_contract_address, USER_TWO.try_into().unwrap());
    publication_dispatcher
        .tip(
            TipParams {
                profile_address: user_one_profile_address,
                channel_id: channel_id,
                community_id: community_id,
                pub_id: pub_assigned_id,
                amount: 2000000000000000000,
                erc20_contract_address: erc20_contract_address
            }
        );
    stop_cheat_caller_address(publication_contract_address);

    start_cheat_caller_address(publication_contract_address, USER_ONE.try_into().unwrap());
    let tip_amount = IComposableDispatcher { contract_address: publication_contract_address }
        .get_tipped_amount(user_one_profile_address, pub_assigned_id);
    let jolt_balance = IERC20Dispatcher { contract_address: erc20_contract_address }
        .balance_of(user_one_profile_address);
    assert(tip_amount == 2000000000000000000, 'invalid tip_amount');
    assert(jolt_balance == 2000000000000000000, 'invalid amount');
    stop_cheat_caller_address(publication_contract_address);
}

#[test]
fn test_collect() {
    let (
        nft_contract_address,
        _,
        publication_contract_address,
        registry_class_hash,
        account_class_hash,
        collect_nft_classhash,
        _,
        _
    ) =
        __setup__();

    let publication_dispatcher = IComposableDispatcher {
        contract_address: publication_contract_address
    };
    let channel_dispatcher = IChannelDispatcher { contract_address: publication_contract_address };
    let community_dispatcher = ICommunityDispatcher {
        contract_address: publication_contract_address
    };
    let content_URI: ByteArray = "ipfs://helloworld";

    start_cheat_caller_address(publication_contract_address, USER_ONE.try_into().unwrap());
    // Create profile
    let user_one_profile_address = publication_dispatcher
        .create_profile(nft_contract_address, registry_class_hash, account_class_hash, 2478);
    // Check if community is created
    let community_id = community_dispatcher.create_community();
    // Check if community is created
    let channel_id = channel_dispatcher.create_channel(community_id);
    // Attempt to post
    let pub_assigned_id = publication_dispatcher
        .post(
            PostParams {
                content_URI: content_URI,
                profile_address: user_one_profile_address,
                channel_id: channel_id,
                community_id: community_id
            }
        );
    stop_cheat_caller_address(publication_contract_address);

    start_cheat_caller_address(publication_contract_address, USER_TWO.try_into().unwrap());
    let _user_two_profile_address = publication_dispatcher
        .create_profile(nft_contract_address, registry_class_hash, account_class_hash, 2478);
    community_dispatcher.join_community(community_id);
    channel_dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(publication_contract_address);

    start_cheat_caller_address(publication_contract_address, USER_THREE.try_into().unwrap());
    let _user_three_profile_address = publication_dispatcher
        .create_profile(nft_contract_address, registry_class_hash, account_class_hash, 2478);
    community_dispatcher.join_community(community_id);
    channel_dispatcher.join_channel(channel_id);
    stop_cheat_caller_address(publication_contract_address);

    start_cheat_caller_address(publication_contract_address, USER_TWO.try_into().unwrap());
    // // Case 1: First collection, expecting new deployment
    let token_id = publication_dispatcher
        .collect(
            CollectParams {
                karst_hub: HUB_ADDRESS.try_into().unwrap(),
                profile_address: user_one_profile_address,
                pub_id: pub_assigned_id,
                community_id: community_id,
                channel_id: channel_id,
                collect_nft_impl_class_hash: collect_nft_classhash,
                salt: 23465
            }
        );
    let collect_nft1 = publication_dispatcher
        .get_publication(user_one_profile_address, pub_assigned_id)
        .collect_nft;
    let collect_dispatcher = ICollectNFTDispatcher { contract_address: collect_nft1 };
    let user2_token_id = collect_dispatcher.get_user_token_id(USER_TWO.try_into().unwrap());

    assert(token_id == user2_token_id, 'invalid token_id');
    stop_cheat_caller_address(publication_contract_address);

    start_cheat_caller_address(publication_contract_address, USER_THREE.try_into().unwrap());
    // // Case 2: collect the same publication, expecting reuse of the existing contract
    let token_id2 = publication_dispatcher
        .collect(
            CollectParams {
                karst_hub: HUB_ADDRESS.try_into().unwrap(),
                profile_address: user_one_profile_address,
                pub_id: pub_assigned_id,
                community_id: community_id,
                channel_id: channel_id,
                collect_nft_impl_class_hash: collect_nft_classhash,
                salt: 234657
            }
        );
    let collect_nft2 = publication_dispatcher
        .get_publication(user_one_profile_address, pub_assigned_id)
        .collect_nft;
    let collect_dispatcher = ICollectNFTDispatcher { contract_address: collect_nft2 };
    let user3_token_id = collect_dispatcher.get_user_token_id(USER_THREE.try_into().unwrap());
    assert(collect_nft1 == collect_nft2, 'invalid_ address');
    assert(token_id2 == user3_token_id, 'invalid token_id');
    stop_cheat_caller_address(publication_contract_address);
}

