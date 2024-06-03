//! Contract for Karst Publications V1
// [Len Publication Contract](https://github.com/lens-protocol/core/blob/master/contracts/libraries/PublicationLib.sol)
use starknet::{ContractAddress, get_caller_address};
use karst::base::types::{
    PostParams, PublicationType, CommentParams, ReferencePubParams, Publication, MirrorParams,
    QuoteParams
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
    fn comment(
        ref self: T,
        profile_address: ContractAddress,
        content_URI: ByteArray,
        pointed_profile_address: ContractAddress,
        pointed_pub_id: u256,
        profile_contract_address: ContractAddress,
    ) -> u256;
    fn mirror(ref self: T, mirrorParams: MirrorParams) -> u256;
    fn quote(ref self: T, quoteParams: QuoteParams) -> u256;
    ////// Getters//////
    fn get_publication(self: @T, user: ContractAddress, pubIdAssigned: u256) -> Publication;
    fn get_publication_type(
        self: @T, profile_address: ContractAddress, pub_id_assigned: u256
    ) -> PublicationType;
    fn get_publication_content_uri(
        self: @T, profile_address: ContractAddress, pub_id: u256
    ) -> ByteArray;
}

#[starknet::contract]
pub mod Publications {
    // *************************************************************************
    //                              IMPORTS
    // *************************************************************************
    use starknet::{ContractAddress, get_contract_address, get_caller_address};
    use karst::base::types::{
        PostParams, Publication, PublicationType, ReferencePubParams, CommentParams, QuoteParams,
        MirrorParams
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
            // assert that the person that created the profile can make a post
            let profile_owner = IKarstProfileDispatcher {
                contract_address: profile_contract_address
            }
                .get_profile(profile_address)
                .profile_owner;
            assert(profile_owner == get_caller_address(), NOT_PROFILE_OWNER);
            let pubIdAssigned = IKarstProfileDispatcher {
                contract_address: profile_contract_address
            }
                .increment_publication_count(profile_address);
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
        fn comment(
            ref self: ContractState,
            profile_address: ContractAddress,
            content_URI: ByteArray,
            pointed_profile_address: ContractAddress,
            pointed_pub_id: u256,
            profile_contract_address: ContractAddress
        ) -> u256 {
            let pubIdAssigned = self
                ._createReferencePublication(
                    profile_address,
                    content_URI,
                    pointed_profile_address,
                    pointed_pub_id,
                    PublicationType::Comment,
                    profile_contract_address
                );
            pubIdAssigned
        }

        // /**
        // * @notice Publishes a mirror to a given profile.
        // *
        // * @param mirrorParams the MirrorParams struct reference types.cairo to know MirrorParams.
        // *
        // * @return uint256 The created publication's pubId.
        // */
        fn mirror(ref self: ContractState, mirrorParams: MirrorParams) -> u256 {
            // logic here
            0
        }

        fn quote(ref self: ContractState, quoteParams: QuoteParams) -> u256 {
            // logic here
            0
        }
        //////////////////////////////////////////////////////////////
        /// GETTERS//////////////////////////////////////////////////
        /// /////////////////////////////////////////////////////////
        fn get_publication_content_uri(
            self: @ContractState, profile_address: ContractAddress, pub_id: u256
        ) -> ByteArray {
            self._getContentURI(profile_address, pub_id)
        }

        fn get_publication(
            self: @ContractState, user: ContractAddress, pubIdAssigned: u256
        ) -> Publication {
            self.publication.read((user, pubIdAssigned))
        }

        fn get_publication_type(
            self: @ContractState, profile_address: ContractAddress, pub_id_assigned: u256
        ) -> PublicationType {
            self._getPublicationType(profile_address, pub_id_assigned)
        }
    }
    // *************************************************************************
    //                            PRIVATE FUNCTIONS
    // *************************************************************************
    #[generate_trait]
    impl Private of PrivateTrait {
        fn _fillRootOfPublicationInStorage(
            ref self: ContractState,
            profile_address: ContractAddress,
            pointed_profile_address: ContractAddress,
            pointed_pub_id: u256,
            profile_contract_address: ContractAddress
        ) -> ContractAddress {
            let mut publication = self.publication.read((profile_address, pointed_pub_id));
            let pointed = self.publication.read((profile_address, pointed_pub_id));
            let publication_type = pointed.pub_Type;
            match publication_type {
                PublicationType::Post => {
                    publication.root_pub_id = pointed_pub_id;
                    publication.root_profile_address = pointed_profile_address;
                },
                PublicationType::Nonexistent |
                PublicationType::Mirror => { return 0.try_into().unwrap(); },
                PublicationType::Comment |
                PublicationType::Quote => {
                    publication.root_pub_id = pointed.root_pub_id;
                    publication.root_profile_address = pointed.root_profile_address;
                }
            }
            self.publication.write((profile_address, pointed_pub_id), publication);
            self.publication.read((profile_address, pointed_pub_id)).root_profile_address
        }
        fn _fillRefeferencePublicationStorage(
            ref self: ContractState,
            profile_address: ContractAddress,
            content_URI: ByteArray,
            pointed_profile_address: ContractAddress,
            pointed_pub_id: u256,
            referencePubType: PublicationType,
            profile_contract_address: ContractAddress
        ) -> (u256, ContractAddress) {
            let pub_id_assigned = IKarstProfileDispatcher {
                contract_address: profile_contract_address
            }
                .increment_publication_count(profile_address);
            let root_profile_address = self
                ._fillRootOfPublicationInStorage(
                    profile_address,
                    pointed_profile_address,
                    pointed_pub_id,
                    profile_contract_address
                );
            let update_reference = Publication {
                pointed_profile_address: profile_address,
                pointed_pub_id: pointed_pub_id,
                content_URI: content_URI,
                pub_Type: referencePubType,
                root_pub_id: 0,
                root_profile_address: root_profile_address
            };
            self.publication.write((profile_address, pub_id_assigned), update_reference);
            (pub_id_assigned, root_profile_address)
        }

        fn _createReferencePublication(
            ref self: ContractState,
            profile_address: ContractAddress,
            content_URI: ByteArray,
            pointed_profile_address: ContractAddress,
            pointed_pub_id: u256,
            referencePubType: PublicationType,
            profile_contract_address: ContractAddress
        ) -> u256 {
            self._validatePointedPub(pointed_profile_address, pointed_pub_id);

            let (pub_id_assigned, root_profile_address) = self
                ._fillRefeferencePublicationStorage(
                    profile_address,
                    content_URI,
                    pointed_profile_address,
                    pointed_pub_id,
                    PublicationType::Comment,
                    profile_contract_address
                );

            if (root_profile_address != pointed_profile_address) {
                self.validateNotBlocked(profile_address, pointed_profile_address, false);
            }
            pub_id_assigned
        }

        fn _blockedStatus(
            ref self: ContractState,
            profile_address: ContractAddress,
            by_profile_address: ContractAddress,
        ) -> bool {
            self.blocked_profile_address.write((profile_address, by_profile_address), false);
            let status = self.blocked_profile_address.read((profile_address, by_profile_address));
            status
        }

        fn validateNotBlocked(
            ref self: ContractState,
            profile_address: ContractAddress,
            by_profile_address: ContractAddress,
            unidirectional_check: bool
        ) {
            if (profile_address != by_profile_address
                && (self._blockedStatus(profile_address, by_profile_address)
                    || (!unidirectional_check
                        && self
                            ._blockedStatus(
                                by_profile_address, profile_address
                            )))) { // return; ERROR
            }
        }

        fn _validatePointedPub(
            ref self: ContractState, profile_address: ContractAddress, pub_id: u256
        ) {
            // If it is pointing to itself it will fail because it will return a non-existent type.
            let pointedPubType = self._getPublicationType(profile_address, pub_id);
            if pointedPubType == PublicationType::Nonexistent
                || pointedPubType == PublicationType::Mirror {
                panic!("invalid pointed publication");
            }
        }

        fn _getPublicationType(
            self: @ContractState, profile_address: ContractAddress, pub_id_assigned: u256
        ) -> PublicationType {
            let pub_type_option = self
                .publication
                .read((profile_address, pub_id_assigned))
                .pub_Type;
            match pub_type_option {
                PublicationType::Nonexistent => PublicationType::Nonexistent,
                PublicationType::Post => PublicationType::Post,
                PublicationType::Comment => PublicationType::Comment,
                PublicationType::Mirror => PublicationType::Mirror,
                PublicationType::Quote => PublicationType::Quote,
            }
        }

        fn _getContentURI(
            self: @ContractState, profile_address: ContractAddress, pub_id: u256
        ) -> ByteArray {
            let publication = self.publication.read((profile_address, pub_id));
            let pub_type_option = publication.pub_Type;

            if pub_type_option == PublicationType::Nonexistent {
                return "0";
            }
            if pub_type_option == PublicationType::Mirror {
                self
                    .publication
                    .read((publication.pointed_profile_address, publication.pointed_pub_id))
                    .content_URI
            } else {
                self.publication.read((profile_address, pub_id)).content_URI
            }
        }
    }
}

