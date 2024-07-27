// *************************************************************************
//                              PUBLICATION TEST
// *************************************************************************
use core::option::OptionTrait;
use core::starknet::SyscallResultTrait;
use core::result::ResultTrait;
use core::traits::{TryInto, Into};
use starknet::{ContractAddress, class_hash::ClassHash, contract_address_const};
use snforge_std::{declare, ContractClassTrait, CheatTarget, start_prank, stop_prank};

use token_bound_accounts::interfaces::IAccount::{IAccountDispatcher, IAccountDispatcherTrait};
use token_bound_accounts::presets::account::Account;
use karst::mocks::registry::Registry;
use karst::interfaces::IRegistry::{IRegistryDispatcher, IRegistryDispatcherTrait};
use karst::karstnft::karstnft::KarstNFT;
use karst::follownft::follownft::Follow;
use karst::mocks::interfaces::IComposable::{IComposableDispatcher, IComposableDispatcherTrait};
use karst::base::constants::types::{
    PostParams, MirrorParams, CommentParams, PublicationType, QuoteParams
};

const HUB_ADDRESS: felt252 = 'HUB';
const USER_ONE: felt252 = 'BOB';
const USER_TWO: felt252 = 'ALICE';
const USER_THREE: felt252 = 'ROB';

// *************************************************************************
//                              SETUP 
// *************************************************************************
fn __setup__() -> (
    ContractAddress,
    ContractAddress,
    ContractAddress,
    felt252,
    felt252,
    ContractAddress,
    ContractAddress,
    ContractAddress,
    u256,
) {
    // deploy NFT
    let nft_contract = declare("KarstNFT").unwrap();
    let names: ByteArray = "KarstNFT";
    let symbol: ByteArray = "KNFT";
    let base_uri: ByteArray = "";
    let mut calldata: Array<felt252> = array![USER_ONE];
    names.serialize(ref calldata);
    symbol.serialize(ref calldata);
    base_uri.serialize(ref calldata);
    let (nft_contract_address, _) = nft_contract.deploy(@calldata).unwrap_syscall();

    // deploy registry
    let registry_class_hash = declare("Registry").unwrap();
    let (registry_contract_address, _) = registry_class_hash.deploy(@array![]).unwrap_syscall();

    // deploy publication
    let publication_contract = declare("KarstPublication").unwrap();
    let mut publication_constructor_calldata = array![];
    let (publication_contract_address, _) = publication_contract
        .deploy(@publication_constructor_calldata)
        .unwrap_syscall();

    // declare account
    let account_class_hash = declare("Account").unwrap();

    // declare follownft
    let follow_nft_classhash = declare("Follow").unwrap();

    // create dispatcher, initialize profile contract
    let dispatcher = IComposableDispatcher { contract_address: publication_contract_address };
    dispatcher.initializer(
        nft_contract_address, 
        HUB_ADDRESS.try_into().unwrap(), 
        follow_nft_classhash.class_hash.into()
    );

    // deploying karst Profile for USER 1
    start_prank(CheatTarget::One(publication_contract_address), USER_ONE.try_into().unwrap());
    let user_one_profile_address = dispatcher
        .create_profile(
            nft_contract_address,
            registry_class_hash.class_hash.into(),
            account_class_hash.class_hash.into(),
            2478
        );
    let content_URI: ByteArray = "ipfs://helloworld";
    let user_one_first_post_pointed_pub_id = dispatcher
        .post(PostParams { content_URI: content_URI, profile_address: user_one_profile_address });
    stop_prank(CheatTarget::One(publication_contract_address),);

    // deploying karst Profile for USER 2
    start_prank(CheatTarget::One(publication_contract_address), USER_TWO.try_into().unwrap());
    let user_two_profile_address = dispatcher
        .create_profile(
            nft_contract_address,
            registry_class_hash.class_hash.into(),
            account_class_hash.class_hash.into(),
            2479
        );
    let content_URI: ByteArray = "ipfs://helloworld";
    dispatcher
        .post(PostParams { content_URI: content_URI, profile_address: user_two_profile_address });
    stop_prank(CheatTarget::One(publication_contract_address),);

    // deploying karst Profile for USER 3
    start_prank(CheatTarget::One(publication_contract_address), USER_THREE.try_into().unwrap());
    let user_three_profile_address = dispatcher
        .create_profile(
            nft_contract_address,
            registry_class_hash.class_hash.into(),
            account_class_hash.class_hash.into(),
            2480
        );
    let content_URI: ByteArray = "ipfs://helloworld";
    dispatcher
        .post(PostParams { content_URI: content_URI, profile_address: user_three_profile_address });
    stop_prank(CheatTarget::One(publication_contract_address));

    return (
        nft_contract_address,
        registry_contract_address,
        publication_contract_address,
        registry_class_hash.class_hash.into(),
        account_class_hash.class_hash.into(),
        user_one_profile_address,
        user_two_profile_address,
        user_three_profile_address,
        user_one_first_post_pointed_pub_id,
    );
}

// *************************************************************************
//                              TEST
// *************************************************************************

#[test]
fn test_post() {
    let (
        _,
        _,
        publication_contract_address,
        _,
        _,
        user_one_profile_address,
        _,
        _,
        user_one_first_post_pointed_pub_id,
    ) =
        __setup__();

    let dispatcher = IComposableDispatcher { contract_address: publication_contract_address };

    start_prank(CheatTarget::One(publication_contract_address), USER_ONE.try_into().unwrap());
    let publication_type = dispatcher
        .get_publication_type(user_one_profile_address, user_one_first_post_pointed_pub_id);

    assert(publication_type == PublicationType::Post, 'invalid pub_type');
    assert(user_one_first_post_pointed_pub_id == 1_u256, 'invalid pub id');
    stop_prank(CheatTarget::One(publication_contract_address));
}

#[test]
#[should_panic(expected: ('Karst: not profile owner!',))]
fn test_posting_should_fail_if_not_profile_owner() {
    let (_, _, publication_contract_address, _, _, user_one_profile_address, _, _, _) = __setup__();
    let dispatcher = IComposableDispatcher { contract_address: publication_contract_address };

    start_prank(CheatTarget::One(publication_contract_address), USER_TWO.try_into().unwrap());
    let content_URI = "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaryrga/";
    dispatcher
        .post(PostParams { content_URI: content_URI, profile_address: user_one_profile_address });
    stop_prank(CheatTarget::One(publication_contract_address),);
}

#[test]
fn test_comment() {
    let (
        _,
        _,
        publication_contract_address,
        _,
        _,
        user_one_profile_address,
        user_two_profile_address,
        _,
        user_one_first_post_pointed_pub_id,
    ) =
        __setup__();

    let dispatcher = IComposableDispatcher { contract_address: publication_contract_address };

    start_prank(CheatTarget::One(publication_contract_address), USER_ONE.try_into().unwrap());
    let content_URI_1 = "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaryrga/";
    let content_URI_2 = "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZysddewga/";

    // user comment on his own post
    let user_one_comment_assigned_pub_id_1 = dispatcher
        .comment(
            CommentParams {
                profile_address: user_one_profile_address,
                content_URI: content_URI_1,
                pointed_profile_address: user_one_profile_address,
                pointed_pub_id: user_one_first_post_pointed_pub_id,
                reference_pub_type: PublicationType::Comment
            }
        );
    stop_prank(CheatTarget::One(publication_contract_address),);

    start_prank(CheatTarget::One(publication_contract_address), USER_TWO.try_into().unwrap());
    // user two comment on user_one_post
    let user_two_comment_on_user_one_assigned_pub_id_2 = dispatcher
        .comment(
            CommentParams {
                profile_address: user_two_profile_address,
                content_URI: content_URI_2,
                pointed_profile_address: user_one_profile_address,
                pointed_pub_id: user_one_first_post_pointed_pub_id,
                reference_pub_type: PublicationType::Comment
            }
        );
    stop_prank(CheatTarget::One(publication_contract_address),);

    let user_one_comment = dispatcher
        .get_publication(user_one_profile_address, user_one_comment_assigned_pub_id_1);
    let user_two_comment = dispatcher
        .get_publication(user_two_profile_address, user_two_comment_on_user_one_assigned_pub_id_2);

    assert(
        user_one_comment.pointed_profile_address == user_one_profile_address,
        'invalid pointed profile address'
    );
    assert(
        user_one_comment.pointed_pub_id == user_one_first_post_pointed_pub_id,
        'invalid pointed publication ID'
    );
    assert(
        user_one_comment.content_URI == "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaryrga/",
        'invalid content URI'
    );
    assert(user_one_comment.pub_Type == PublicationType::Comment, 'invalid pub_type');
    assert(
        user_one_comment.root_profile_address == user_one_profile_address,
        'invalid root profile address'
    );
    assert(
        user_one_comment.root_pub_id == user_one_first_post_pointed_pub_id,
        'invalid root publication ID'
    );

    assert(
        user_two_comment.pointed_profile_address == user_one_profile_address,
        'invalid pointed profile address'
    );
    assert(
        user_two_comment.pointed_pub_id == user_one_first_post_pointed_pub_id,
        'invalid pointed publication ID'
    );
    assert(
        user_two_comment.content_URI == "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZysddewga/",
        'invalid content URI'
    );
    assert(user_two_comment.pub_Type == PublicationType::Comment, 'invalid pub_type');
    assert(
        user_two_comment.root_profile_address == user_one_profile_address,
        'invalid root profile address'
    );
    assert(
        user_two_comment.root_pub_id == user_one_first_post_pointed_pub_id,
        'invalid root publication ID'
    );
}

#[test]
fn test_nested_comments() {
    let (
        _,
        _,
        publication_contract_address,
        _,
        _,
        user_one_profile_address,
        user_two_profile_address,
        user_three_profile_address,
        user_one_first_post_pointed_pub_id,
    ) =
        __setup__();

    let dispatcher = IComposableDispatcher { contract_address: publication_contract_address };

    start_prank(CheatTarget::One(publication_contract_address), USER_TWO.try_into().unwrap());
    let content_URI_1 = "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaryrga/";
    let content_URI_2 = "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZysddewga/";
    let content_URI_3 = "ipfs://VmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZysddewUhje/";

    // user 2 comments on post
    let user_two_comment_assigned_pub_id = dispatcher
        .comment(
            CommentParams {
                profile_address: user_two_profile_address,
                content_URI: content_URI_1,
                pointed_profile_address: user_one_profile_address,
                pointed_pub_id: user_one_first_post_pointed_pub_id,
                reference_pub_type: PublicationType::Comment
            }
        );
    stop_prank(CheatTarget::One(publication_contract_address),);

    // user three comments under user one's comment
    start_prank(CheatTarget::One(publication_contract_address), USER_THREE.try_into().unwrap());
    let user_three_comment_assigned_pub_id = dispatcher
        .comment(
            CommentParams {
                profile_address: user_three_profile_address,
                content_URI: content_URI_2,
                pointed_profile_address: user_two_profile_address,
                pointed_pub_id: user_two_comment_assigned_pub_id,
                reference_pub_type: PublicationType::Comment
            }
        );
    stop_prank(CheatTarget::One(publication_contract_address),);

    // user one comments under user three's comment
    start_prank(CheatTarget::One(publication_contract_address), USER_ONE.try_into().unwrap());
    let user_one_comment_assigned_pub_id = dispatcher
        .comment(
            CommentParams {
                profile_address: user_one_profile_address,
                content_URI: content_URI_3,
                pointed_profile_address: user_three_profile_address,
                pointed_pub_id: user_three_comment_assigned_pub_id,
                reference_pub_type: PublicationType::Comment
            }
        );
    stop_prank(CheatTarget::One(publication_contract_address),);

    let user_two_comment = dispatcher
        .get_publication(user_two_profile_address, user_two_comment_assigned_pub_id);
    let user_three_comment = dispatcher
        .get_publication(user_three_profile_address, user_three_comment_assigned_pub_id);
    let user_one_comment = dispatcher
        .get_publication(user_one_profile_address, user_one_comment_assigned_pub_id);

    assert(
        user_two_comment.pointed_profile_address == user_one_profile_address,
        'invalid pointed profile address'
    );
    assert(
        user_two_comment.pointed_pub_id == user_one_first_post_pointed_pub_id,
        'invalid pointed publication ID'
    );
    assert(
        user_two_comment.content_URI == "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaryrga/",
        'invalid content URI'
    );
    assert(user_two_comment.pub_Type == PublicationType::Comment, 'invalid pub_type');
    assert(
        user_two_comment.root_profile_address == user_one_profile_address,
        'invalid root profile address'
    );
    assert(
        user_two_comment.root_pub_id == user_one_first_post_pointed_pub_id,
        'invalid root publication ID'
    );

    assert(
        user_three_comment.pointed_profile_address == user_two_profile_address,
        'invalid pointed profile address'
    );
    assert(
        user_three_comment.pointed_pub_id == user_two_comment_assigned_pub_id,
        'invalid pointed publication ID'
    );
    assert(
        user_three_comment.content_URI == "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZysddewga/",
        'invalid content URI'
    );
    assert(user_three_comment.pub_Type == PublicationType::Comment, 'invalid pub_type');
    assert(
        user_three_comment.root_profile_address == user_one_profile_address,
        'invalid root profile address'
    );
    assert(
        user_three_comment.root_pub_id == user_one_first_post_pointed_pub_id,
        'invalid root publication ID'
    );

    assert(
        user_one_comment.pointed_profile_address == user_three_profile_address,
        'invalid pointed profile address'
    );
    assert(
        user_one_comment.pointed_pub_id == user_three_comment_assigned_pub_id,
        'invalid pointed publication ID'
    );
    assert(
        user_one_comment.content_URI == "ipfs://VmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZysddewUhje/",
        'invalid content URI'
    );
    assert(user_one_comment.pub_Type == PublicationType::Comment, 'invalid pub_type');
    assert(
        user_one_comment.root_profile_address == user_one_profile_address,
        'invalid root profile address'
    );
    assert(
        user_one_comment.root_pub_id == user_one_first_post_pointed_pub_id,
        'invalid root publication ID'
    );
}

#[test]
#[should_panic(expected: ('Karst: not profile owner!',))]
fn test_commenting_should_fail_if_not_profile_owner() {
    let (
        _,
        _,
        publication_contract_address,
        _,
        _,
        user_one_profile_address,
        _,
        _,
        user_one_first_post_pointed_pub_id
    ) =
        __setup__();
    let dispatcher = IComposableDispatcher { contract_address: publication_contract_address };

    start_prank(CheatTarget::One(publication_contract_address), USER_TWO.try_into().unwrap());
    let content_URI = "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaryrga/";
    dispatcher
        .comment(
            CommentParams {
                profile_address: user_one_profile_address,
                content_URI: content_URI,
                pointed_profile_address: user_one_profile_address,
                pointed_pub_id: user_one_first_post_pointed_pub_id,
                reference_pub_type: PublicationType::Comment
            }
        );
    stop_prank(CheatTarget::One(publication_contract_address),);
}

#[test]
fn test_quote() {
    let (
        _,
        _,
        publication_contract_address,
        _,
        _,
        user_one_profile_address,
        user_two_profile_address,
        user_three_profile_address,
        user_one_first_post_pointed_pub_id,
    ) =
        __setup__();
    let dispatcher = IComposableDispatcher { contract_address: publication_contract_address };

    // user two quotes user one
    start_prank(CheatTarget::One(publication_contract_address), USER_TWO.try_into().unwrap());
    let quote_content_URI = "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZysddefzp/";
    let quote_params = QuoteParams {
        profile_address: user_two_profile_address,
        content_URI: quote_content_URI,
        pointed_profile_address: user_one_profile_address,
        pointed_pub_id: user_one_first_post_pointed_pub_id,
        reference_pub_type: PublicationType::Quote
    };
    let quote_pub_id_one = dispatcher.quote(quote_params);
    stop_prank(CheatTarget::Multiple(array![publication_contract_address]),);

    // user three quotes user two
    start_prank(CheatTarget::One(publication_contract_address), USER_THREE.try_into().unwrap());
    let user_two_quote_content_URI = "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZysdjbezo/";
    let user_two_quote_params = QuoteParams {
        profile_address: user_three_profile_address,
        content_URI: user_two_quote_content_URI,
        pointed_profile_address: user_two_profile_address,
        pointed_pub_id: quote_pub_id_one,
        reference_pub_type: PublicationType::Quote
    };
    let quote_pub_id_two = dispatcher.quote(user_two_quote_params);
    stop_prank(CheatTarget::One(publication_contract_address));

    // get both publications
    let user_two_quote = dispatcher.get_publication(user_two_profile_address, quote_pub_id_one);
    let user_three_quote = dispatcher.get_publication(user_three_profile_address, quote_pub_id_two);

    assert(
        user_two_quote.pointed_profile_address == user_one_profile_address,
        'invalid pointed profile address'
    );
    assert(
        user_two_quote.pointed_pub_id == user_one_first_post_pointed_pub_id,
        'invalid pointed publication ID'
    );
    assert(
        user_two_quote.content_URI == "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZysddefzp/",
        'invalid content URI'
    );
    assert(user_two_quote.pub_Type == PublicationType::Quote, 'invalid pub_type');
    assert(
        user_two_quote.root_profile_address == user_one_profile_address,
        'invalid root profile address'
    );
    assert(
        user_two_quote.root_pub_id == user_one_first_post_pointed_pub_id,
        'invalid root publication ID'
    );

    assert(
        user_three_quote.pointed_profile_address == user_two_profile_address,
        'invalid pointed profile address'
    );
    assert(user_three_quote.pointed_pub_id == quote_pub_id_one, 'invalid pointed publication ID');
    assert(
        user_three_quote.content_URI == "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZysdjbezo/",
        'invalid content URI'
    );
    assert(user_three_quote.pub_Type == PublicationType::Quote, 'invalid pub_type');
    assert(
        user_three_quote.root_profile_address == user_one_profile_address,
        'invalid root profile address'
    );
    assert(
        user_three_quote.root_pub_id == user_one_first_post_pointed_pub_id,
        'invalid root publication ID'
    );
}

#[test]
#[should_panic(expected: ('Karst: not profile owner!',))]
fn test_quoting_should_fail_if_not_profile_owner() {
    let (
        _,
        _,
        publication_contract_address,
        _,
        _,
        user_one_profile_address,
        user_two_profile_address,
        _,
        user_one_first_post_pointed_pub_id
    ) =
        __setup__();
    let dispatcher = IComposableDispatcher { contract_address: publication_contract_address };

    start_prank(CheatTarget::One(publication_contract_address), USER_ONE.try_into().unwrap());
    let content_URI: ByteArray = "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaryrga/";
    dispatcher
        .quote(
            QuoteParams {
                profile_address: user_two_profile_address,
                content_URI: content_URI,
                pointed_profile_address: user_one_profile_address,
                pointed_pub_id: user_one_first_post_pointed_pub_id,
                reference_pub_type: PublicationType::Quote
            }
        );
    stop_prank(CheatTarget::One(publication_contract_address),);
}

#[test]
#[should_panic(expected: ('Karst: unsupported pub type!',))]
fn test_as_reference_pub_params_should_fail_on_wrong_pub_type() {
    let (
        _,
        _,
        publication_contract_address,
        _,
        _,
        user_one_profile_address,
        _,
        _,
        user_one_first_post_pointed_pub_id,
    ) =
        __setup__();
    let dispatcher = IComposableDispatcher { contract_address: publication_contract_address };
    start_prank(CheatTarget::One(publication_contract_address), USER_ONE.try_into().unwrap());

    let content_URI = "ipfs://QmSkDCsS32eLpcymxtn1cEn7Rc5hfefLBgfvZyjaryrga/";

    // user comments on his own post
    dispatcher
        .comment(
            CommentParams {
                profile_address: user_one_profile_address,
                content_URI: content_URI,
                pointed_profile_address: user_one_profile_address,
                pointed_pub_id: user_one_first_post_pointed_pub_id,
                reference_pub_type: PublicationType::Mirror
            }
        );

    stop_prank(CheatTarget::One(publication_contract_address),);
}


#[test]
fn test_mirror() {
    let (
        _,
        _,
        publication_contract_address,
        _,
        _,
        user_one_profile_address,
        user_two_profile_address,
        _,
        user_one_first_post_pointed_pub_id,
    ) =
        __setup__();

    let dispatcher = IComposableDispatcher { contract_address: publication_contract_address };
    let mirror_params = MirrorParams {
        profile_address: user_two_profile_address,
        pointed_profile_address: user_one_profile_address,
        pointed_pub_id: user_one_first_post_pointed_pub_id,
    };

    start_prank(CheatTarget::One(publication_contract_address), USER_TWO.try_into().unwrap());
    let pub_assigned_id = dispatcher.mirror(mirror_params);
    stop_prank(CheatTarget::One(publication_contract_address),);

    // get the mirror publication
    let user_mirror = dispatcher.get_publication(user_two_profile_address, pub_assigned_id);

    assert(
        user_mirror.pointed_profile_address == user_one_profile_address,
        'invalid pointed profile address'
    );
    assert(
        user_mirror.pointed_pub_id == user_one_first_post_pointed_pub_id,
        'invalid pointed publication ID'
    );
    assert(user_mirror.content_URI == "ipfs://helloworld", 'invalid content URI');
    assert(user_mirror.pub_Type == PublicationType::Mirror, 'invalid pub_type');
    assert(
        user_mirror.root_profile_address == user_one_profile_address, 'invalid root profile address'
    );
    assert(
        user_mirror.root_pub_id == user_one_first_post_pointed_pub_id, 'invalid root publication ID'
    );
}

#[test]
#[should_panic(expected: ('Karst: not profile owner!',))]
fn test_mirroring_should_fail_if_not_profile_owner() {
    let (
        _,
        _,
        publication_contract_address,
        _,
        _,
        user_one_profile_address,
        user_two_profile_address,
        _,
        user_one_first_post_pointed_pub_id
    ) =
        __setup__();
    let dispatcher = IComposableDispatcher { contract_address: publication_contract_address };
    let mirror_params = MirrorParams {
        profile_address: user_two_profile_address,
        pointed_profile_address: user_one_profile_address,
        pointed_pub_id: user_one_first_post_pointed_pub_id,
    };

    start_prank(CheatTarget::One(publication_contract_address), USER_ONE.try_into().unwrap());
    dispatcher.mirror(mirror_params);
    stop_prank(CheatTarget::One(publication_contract_address),);
}

#[test]
fn test_get_publication_content_uri() {
    let (
        _,
        _,
        publication_contract_address,
        _,
        _,
        user_one_profile_address,
        _,
        _,
        user_one_first_post_pointed_pub_id
    ) =
        __setup__();
    let dispatcher = IComposableDispatcher { contract_address: publication_contract_address };

    let content_uri = dispatcher
        .get_publication_content_uri(user_one_profile_address, user_one_first_post_pointed_pub_id);
    assert(content_uri == "ipfs://helloworld", 'invalid uri');
}

#[test]
fn test_get_publication_type() {
    let (
        _,
        _,
        publication_contract_address,
        _,
        _,
        user_one_profile_address,
        _,
        _,
        user_one_first_post_pointed_pub_id
    ) =
        __setup__();
    let dispatcher = IComposableDispatcher { contract_address: publication_contract_address };

    let pub_type = dispatcher
        .get_publication_type(user_one_profile_address, user_one_first_post_pointed_pub_id);
    assert(pub_type == PublicationType::Post, 'invalid pub type');
}
