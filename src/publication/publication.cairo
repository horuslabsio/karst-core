//! Contract for Karst Publications

use starknet::{ContractAddress, get_caller_address};
use karst::base::types::{
    PostParams, PublicationType, CommentParams, ReferencePubParams, Publication
};
use karst::interfaces::IProfile::{IKarstProfileDispatcher, IKarstProfileDispatcherTrait};
use core::option::OptionTrait;

// *************************************************************************
//                              INTERFACE of KARST PUBLICATIONS
// *************************************************************************
#[starknet::interface]
pub trait IKarstPublications<T> {
    // *************************************************************************
    //                              PUBLISHING FUNCTIONS  
    // *************************************************************************

    fn post(
        ref self: T,
        contentURI: ByteArray,
        profile_address: ContractAddress,
        profile_contract_address: ContractAddress
    ) -> u256;
    // fn get_content_uri(self: @T, user: ContractAddress) -> ByteArray;
    // fn get_pub_type(self: @T, user: ContractAddress) -> Option<PublicationType>;
    fn get_publication(self: @T, user: ContractAddress, pubIdAssigned: u256) -> Publication;
// fn comment(
//     ref self: T, referencePubParams: ReferencePubParams, profile_address: ContractAddress
// ) -> u256;
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
    use karst::base::{hubrestricted::HubRestricted::hub_only};
    use core::option::OptionTrait;
    // *************************************************************************
    //                              STORAGE
    // *************************************************************************

    #[storage]
    struct Storage {
        publication: LegacyMap<(ContractAddress, u256), Publication>,
        blocked_profile_address: LegacyMap<(ContractAddress, ContractAddress), bool>,
        karst_hub: ContractAddress,
    }
    // *************************************************************************
    //                              EVENTS
    // *************************************************************************

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        Post: Post,
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
    //                            CONSTRUCTOR
    // *************************************************************************
    #[constructor]
    fn constructor(ref self: ContractState, hub: ContractAddress) {
        self.karst_hub.write(hub);
    }

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
            contentURI: ByteArray,
            profile_address: ContractAddress,
            profile_contract_address: ContractAddress
        ) -> u256 {
            hub_only(self.karst_hub.read());
            let pubIdAssigned = IKarstProfileDispatcher {
                contract_address: profile_contract_address
            }
                .increment_publication_count();
            let new_post = Publication {
                pointed_profile_address: 0.try_into().unwrap(),
                pointed_pub_id: 0,
                content_URI: contentURI,
                pub_Type: PublicationType::Post,
                root_profile_address: 0.try_into().unwrap(),
                root_pub_id: 0
            };
            self.publication.write((profile_address, pubIdAssigned), new_post);
            pubIdAssigned
        }
        fn get_publication(
            self: @ContractState, user: ContractAddress, pubIdAssigned: u256
        ) -> Publication {
            self.publication.read((user, pubIdAssigned))
        }
    // fn comment(
    //     ref self: ContractState,
    //     mut referencePubParams: ReferencePubParams,
    //     profile_address: ContractAddress
    // ) -> u256 {
    //     let pubIdAssigned = self
    //        ._createReferencePublication(
    //             ref referencePubParams, PublicationType::Comment, profile_address
    //         );
    //     pubIdAssigned
    // }
    }
// *************************************************************************
//                            PRIVATE FUNCTIONS
// *************************************************************************
// #[generate_trait]
// impl Private of PrivateTrait {
//     fn _fillRootOfPublicationInStorage(
//         ref self: ContractState,
//         pointedProfileId: ContractAddress,
//         pointedPubId: u256,
//         profile_contract_address: ContractAddress
//     ) -> ContractAddress {
//         let caller = get_caller_address();
//         let (_, _, profile_address, _) = IKarstProfileDispatcher {
//             contract_address: profile_contract_address
//         }
//             .get_profile_details(caller);
//         let mut pubPointed = self.publication.read(profile_address);
//         let pubPointedType = pubPointed.pubType;

//         if pubPointedType == Option::Some(PublicationType::Post) {
//             pubPointed.rootPubId = pointedPubId;
//             return pubPointed.root_profile_address;
//         } else if pubPointedType == Option::Some(PublicationType::Comment)
//             || pubPointedType == Option::Some(PublicationType::Quote) {
//             pubPointed.rootPubId = pubPointed.rootPubId;
//             return pubPointed.root_profile_address;
//         };
//         return 0.try_into().unwrap();
//     }

//     fn _fillRefeferencePublicationStorage(
//         ref self: ContractState,
//         ref referencePubParams: ReferencePubParams,
//         referencePubType: PublicationType,
//         profile_contract_address: ContractAddress
//     ) -> (u256, ContractAddress) {
//         let caller = get_caller_address();
//         let mut profile = IKarstProfileDispatcher { contract_address: profile_contract_address }
//             .get_profile(caller);
//         profile.pubCount += 1;
//         let mut referencePub = self.publication.read(referencePubParams.profile_address);
//         referencePub.pointed_profile_address = referencePubParams.pointedProfile_address;
//         referencePub.pointedPubId = referencePubParams.pointedPubId;
//         referencePub.contentURI = referencePubParams.contentURI;
//         referencePub.pubType = Option::Some(referencePubType);
//         let rootProfileId = self
//             ._fillRootOfPublicationInStorage(
//                 referencePubParams.pointedProfile_address,
//                 referencePubParams.pointedPubId,
//                 profile_contract_address
//             );
//         (profile.pubCount, rootProfileId)
//     }

//     fn _createReferencePublication(
//         ref self: ContractState,
//         ref referencePubParams: ReferencePubParams,
//         referencePubType: PublicationType,
//         profile_contract_address: ContractAddress
//     ) -> u256 {
//         self._validatePointedPub(referencePubParams.pointedProfile_address);

//         let (pubIdAssigned, rootProfileId) = self
//             ._fillRefeferencePublicationStorage(
//                 ref referencePubParams, referencePubType, profile_contract_address
//             );

//         if (rootProfileId != referencePubParams.pointedProfile_address) {
//             self
//                 .validateNotBlocked(
//                     referencePubParams.profile_address,
//                     referencePubParams.pointedProfile_address,
//                     false
//                 );
//         }
//         pubIdAssigned
//     }

//     fn _blockedStatus(
//         ref self: ContractState,
//         profile_address: ContractAddress,
//         byProfile_address: ContractAddress
//     ) -> bool {
//         self.blocked_profile_address.read((profile_address, byProfile_address))
//     }

//     fn validateNotBlocked(
//         ref self: ContractState,
//         profile_address: ContractAddress,
//         byProfile_address: ContractAddress,
//         unidirectionalCheck: bool,
//     ) {
//         if (profile_address != byProfile_address
//             && (self._blockedStatus(profile_address, byProfile_address)
//                 || (!unidirectionalCheck
//                     && self._blockedStatus(byProfile_address, profile_address)))) {
//             return;
//         }
//     }

//     fn _validatePointedPub(ref self: ContractState, profile_address: ContractAddress) {
//         // If it is pointing to itself it will fail because it will return a non-existent type.
//         let pointedPubType = self._getPublicationType(profile_address);
//         if pointedPubType == Option::Some(PublicationType::Nonexistent)
//             || pointedPubType == Option::Some(PublicationType::Mirror) {
//             return;
//         }
//     }

//     fn _getPublicationType(
//         ref self: ContractState, profile_address: ContractAddress
//     ) -> Option<PublicationType> {
//         let pub_type_option = self.publication.read(profile_address).pubType;
//         match pub_type_option {
//             Option::Some(PublicationType::Nonexistent) => Option::Some(
//                 PublicationType::Nonexistent
//             ),
//             PublicationType::Post => Option::Some(PublicationType::Post),
//             PublicationType::Comment => Option::Some(PublicationType::Comment),
//             PublicationType::Mirror => Option::Some(PublicationType::Mirror),
//             PublicationType::Quote => Option::Some(PublicationType::Quote),
//             Option::None => Option::None
//         }
//     }
// }
}
// {
//     Option::Some(pub_type) => pub_type{
//             PublicationType::Nonexistent => Option::Some(PublicationType::Nonexistent)
//             PublicationType::Post => Option::Some(PublicationType::Post),
//             PublicationType::Comment => Option::Some(PublicationType::Comment),
//             PublicationType::Mirror => Option::Some(PublicationType::Mirror),
//             PublicationType::Quote => Option::Some(PublicationType::Quote),

//     }


