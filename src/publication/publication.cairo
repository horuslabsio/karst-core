//! Contract for Karst Publications

use starknet::{ContractAddress, get_caller_address};
use karst::base::types::{PostParams, PublicationType, CommentParams, ReferencePubParams};
use karst::interfaces::IProfile::{IKarstProfileDispatcher, IKarstProfileDispatcherTrait};


// *************************************************************************
//                              INTERFACE of KARST PUBLICATIONS
// *************************************************************************
#[starknet::interface]
pub trait IKarstPublications<T> {
    // *************************************************************************
    //                              PUBLISHING FUNCTIONS  
    // *************************************************************************

    fn post(
        ref self: T, post_params: PostParams, profile_contract_address: ContractAddress
    ) -> u256;
    fn comment(
        ref self: T, referencePubParams: ReferencePubParams, profile_address: ContractAddress
    ) -> u256;
// *************************************************************************
//                              PROFILE INTERACTION FUNCTIONS  
// *************************************************************************
}

#[starknet::contract]
pub mod Publications {
    // *************************************************************************
    //                              IMPORTS
    // *************************************************************************
    use starknet::{ContractAddress, get_contract_address, get_caller_address};
    use karst::base::types::{
        PostParams, Publication, PublicationType, ReferencePubParams, CommentParams
    };
    use super::IKarstPublications;
    use karst::interfaces::IProfile::{IKarstProfileDispatcher, IKarstProfileDispatcherTrait};
    use karst::base::errors::Errors::{NOT_PROFILE_OWNER, BLOCKED_STATUS};

    // *************************************************************************
    //                              STORAGE
    // *************************************************************************

    #[storage]
    struct Storage {
        publication: LegacyMap<ContractAddress, Publication>,
        blocked_profile_address: LegacyMap<(ContractAddress, ContractAddress), bool>
    }

    // *************************************************************************
    //                              EVENTS
    // *************************************************************************

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        Post: Post,
    // Comment: Comment,
    // Mirror: Mirror,
    // Quote: Quote,
    // Tip: Tip,
    }

    // *************************************************************************
    //                              STRUCTS
    // *************************************************************************

    #[derive(Drop, starknet::Event)]
    pub struct Post {
        pub post: PostParams,
        pub publication_id: u256,
        pub transaction_executor: ContractAddress,
        pub block_timestamp: u256,
    }


    // *************************************************************************
    //                              CONSTRUCTOR
    // *************************************************************************
    #[constructor]
    fn constructor(ref self: ContractState,) {}

    // *************************************************************************
    //                              EXTERNAL FUNCTIONS
    // *************************************************************************

    #[abi(embed_v0)]
    impl PublicationsImpl of IKarstPublications<ContractState> {
        // *************************************************************************
        //                              PUBLISHING FUNCTIONS
        // *************************************************************************

        fn post(
            ref self: ContractState,
            post_params: PostParams,
            profile_contract_address: ContractAddress
        ) -> u256 {
            let caller = get_caller_address();

            let (_, _, _, profile_owner) = IKarstProfileDispatcher {
                contract_address: profile_contract_address
            }
                .get_profile_details(caller);
            assert(caller == profile_owner, NOT_PROFILE_OWNER);
            let mut profile = IKarstProfileDispatcher { contract_address: profile_contract_address }
                .get_profile(caller);
            profile.pubCount += 1;
            let mut post = self.publication.read(post_params.profile_address);
            post.pointed_profile_address = post_params.profile_address;
            post.pointedPubId = profile.pubCount;
            post.contentURI = post_params.contentURI;
            post.pubType = PublicationType::Post;
            self.publication.write(post_params.profile_address, post);

            profile.pubCount
        // self.emit(Post { post, publication_id, transaction_executor, block_timestamp, });
        }

        fn comment(
            ref self: ContractState,
            mut referencePubParams: ReferencePubParams,
            profile_address: ContractAddress
        ) -> u256 {
            let pubIdAssigned = self
                ._createReferencePublication(
                    ref referencePubParams, PublicationType::Comment, profile_address
                );
            pubIdAssigned
        }
    // *************************************************************************
    }


    // *************************************************************************
    //                            PRIVATE FUNCTIONS
    // *************************************************************************
    #[generate_trait]
    impl Private of PrivateTrait {
        fn _fillRootOfPublicationInStorage(
            ref self: ContractState,
            pointedProfileId: ContractAddress,
            pointedPubId: u256,
            profile_contract_address: ContractAddress
        ) -> ContractAddress {
            let caller = get_caller_address();
            let (_, _, profile_address, _) = IKarstProfileDispatcher {
                contract_address: profile_contract_address
            }
                .get_profile_details(caller);
            let mut pubPointed = self.publication.read(profile_address);
            let pubPointedType = pubPointed.pubType;

            if pubPointedType == PublicationType::Post {
                pubPointed.rootPubId = pointedPubId;
                return pubPointed.root_profile_address;
            } else if pubPointedType == PublicationType::Comment
                || pubPointedType == PublicationType::Quote {
                pubPointed.rootPubId = pubPointed.rootPubId;
                return pubPointed.root_profile_address;
            };
            return 0.try_into().unwrap();
        }

        fn _fillRefeferencePublicationStorage(
            ref self: ContractState,
            ref referencePubParams: ReferencePubParams,
            referencePubType: PublicationType,
            profile_contract_address: ContractAddress
        ) -> (u256, ContractAddress) {
            let caller = get_caller_address();
            let mut profile = IKarstProfileDispatcher { contract_address: profile_contract_address }
                .get_profile(caller);
            profile.pubCount += 1;
            let mut referencePub = self.publication.read(referencePubParams.profile_address);
            referencePub.pointed_profile_address = referencePubParams.pointedProfile_address;
            referencePub.pointedPubId = referencePubParams.pointedPubId;
            referencePub.contentURI = referencePubParams.contentURI;
            referencePub.pubType = referencePubType;
            let rootProfileId = self
                ._fillRootOfPublicationInStorage(
                    referencePubParams.pointedProfile_address,
                    referencePubParams.pointedPubId,
                    profile_contract_address
                );
            (profile.pubCount, rootProfileId)
        }

        fn _createReferencePublication(
            ref self: ContractState,
            ref referencePubParams: ReferencePubParams,
            referencePubType: PublicationType,
            profile_contract_address: ContractAddress
        ) -> u256 {
            self._validatePointedPub(referencePubParams.pointedProfile_address);

            let (pubIdAssigned, rootProfileId) = self
                ._fillRefeferencePublicationStorage(
                    ref referencePubParams, referencePubType, profile_contract_address
                );

            if (rootProfileId != referencePubParams.pointedProfile_address) {
                self
                    .validateNotBlocked(
                        referencePubParams.profile_address,
                        referencePubParams.pointedProfile_address,
                        false
                    );
            }
            pubIdAssigned
        }

        fn _blockedStatus(
            ref self: ContractState,
            profile_address: ContractAddress,
            byProfile_address: ContractAddress
        ) -> bool {
            self.blocked_profile_address.read((profile_address, byProfile_address))
        }


        fn validateNotBlocked(
            ref self: ContractState,
            profile_address: ContractAddress,
            byProfile_address: ContractAddress,
            unidirectionalCheck: bool,
        ) {
            if (profile_address != byProfile_address
                && (self._blockedStatus(profile_address, byProfile_address)
                    || (!unidirectionalCheck
                        && self._blockedStatus(byProfile_address, profile_address)))) {
                return;
            }
        }

        fn _validatePointedPub(ref self: ContractState, profile_address: ContractAddress) {
            // If it is pointing to itself it will fail because it will return a non-existent type.
            let pointedPubType = self._getPublicationType(profile_address);
            if pointedPubType == PublicationType::Nonexistent
                || pointedPubType == PublicationType::Mirror {
                return;
            }
        }

        fn _getPublicationType(
            ref self: ContractState, profile_address: ContractAddress
        ) -> PublicationType {
            let pubType = self.publication.read(profile_address).pubType;
            match pubType {
                PublicationType::Nonexistent => PublicationType::Nonexistent,
                PublicationType::Post => PublicationType::Post,
                PublicationType::Comment => PublicationType::Comment,
                PublicationType::Mirror => PublicationType::Mirror,
                PublicationType::Quote => PublicationType::Quote,
            }
        }

    }
}
