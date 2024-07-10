use starknet::{ContractAddress, get_caller_address};
use karst::base::types::{
    PostParams, PublicationType, CommentParams, ReferencePubParams, Publication, MirrorParams,
    QuoteParams
};

use karst::interfaces::IProfile::{IProfileDispatcher, IProfileDispatcherTrait};
use core::option::OptionTrait;


#[starknet::component]
pub mod PublicationComponent {
    // *************************************************************************
    //                              IMPORTS
    // *************************************************************************
    use karst::interfaces::IProfile::IProfile;
use core::option::OptionTrait;
    use starknet::{ContractAddress, get_contract_address, get_caller_address, get_block_timestamp};
    use karst::interfaces::IPublication::IKarstPublications;
    use karst::base::errors::Errors::{NOT_PROFILE_OWNER, UNSUPPORTED_PUB_TYPE};
    use karst::base::{hubrestricted::HubRestricted::hub_only};
    use karst::base::types::{
        PostParams, Publication, PublicationType, ReferencePubParams, CommentParams, QuoteParams,
        MirrorParams
    };
    use karst::profile::profile::ProfileComponent;


    // *************************************************************************
    //                              STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        publication: LegacyMap<(ContractAddress, u256), Publication>,
        karst_hub: ContractAddress
    }

    // *************************************************************************
    //                              EVENTS
    // *************************************************************************
    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        Post: Post,
        CommentCreated: CommentCreated,
        MirrorCreated: MirrorCreated,
        QuoteCreated: QuoteCreated,
    }

    #[derive(Drop, starknet::Event)]
    pub struct Post {
        pub post: PostParams,
        pub publication_id: u256,
        pub transaction_executor: ContractAddress,
        pub block_timestamp: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct MirrorCreated {
        pub mirrorParams: MirrorParams,
        pub publication_id: u256,
        pub transaction_executor: ContractAddress,
        pub block_timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct CommentCreated {
        pub profile_address: ContractAddress,
        pub publication_id: u256,
        pub transaction_executor: ContractAddress,
        pub block_timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct QuoteCreated {
        pub quoteParams: QuoteParams,
        pub publication_id: u256,
        pub transaction_executor: ContractAddress,
        pub block_timestamp: u64,
    }


    // *************************************************************************
    //                              EXTERNAL FUNCTIONS
    // *************************************************************************
    #[embeddable_as(KarstPublication)]
    impl PublicationsImpl<
        TContractState, +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl Profile: ProfileComponent::HasComponent<TContractState>
    > of IKarstPublications<ComponentState<TContractState>> {
        // *************************************************************************
        //                              PUBLISHING FUNCTIONS
        // *************************************************************************
        /// @notice initialize publication component
        /// @param hub_address address of hub contract
        fn initialize(ref self: ComponentState<TContractState>, hub_address: ContractAddress) {
            self.karst_hub.write(hub_address);
        }

        /// @notice performs post action
        /// @param contentURI uri of the content to be posted
        /// @param profile_address address of profile performing the post action
        fn post(
            ref self: ComponentState<TContractState>,
            contentURI: ByteArray,
            profile_address: ContractAddress,
            profile_contract_address: ContractAddress
        ) -> u256 {
            let profile_owner:ContractAddress = get_dep_component!(@self,Profile).get_profile(profile_address).profile_owner;            
            let mut profile_instance = get_dep_component_mut!(ref self,Profile);
            let pub_id_assigned = profile_instance.increment_publication_count(profile_address);
            assert(profile_owner == get_caller_address(), NOT_PROFILE_OWNER);
            let new_post = Publication {
                pointed_profile_address: 0.try_into().unwrap(),
                pointed_pub_id: 0,
                content_URI: contentURI,
                pub_Type: PublicationType::Post,
                root_profile_address: 0.try_into().unwrap(),
                root_pub_id: 0
            };

            self.publication.write((profile_address, pub_id_assigned), new_post);
            pub_id_assigned
        }

        /// @notice performs comment action
        /// @param profile_address address of profile performing the comment action
        /// @param reference_pub_type publication type
        /// @param pointed_profile_address profile address comment points too
        /// @param pointed_pub_id ID of initial publication comment points too
        fn comment(
            ref self: ComponentState<TContractState>,
            profile_address: ContractAddress,
            reference_pub_type: PublicationType,
            content_URI: ByteArray,
            pointed_profile_address: ContractAddress,
            pointed_pub_id: u256,
            profile_contract_address: ContractAddress
        ) -> u256 {
            let reference_pub_type = self._as_reference_pub_params(reference_pub_type);
            assert(reference_pub_type == PublicationType::Comment, UNSUPPORTED_PUB_TYPE);

            let pub_id_assigned = self
                ._createReferencePublication(
                    profile_address,
                    content_URI,
                    pointed_profile_address,
                    pointed_pub_id,
                    reference_pub_type,
                    profile_contract_address
                );

            self
                .emit(
                    CommentCreated {
                        profile_address,
                        publication_id: pub_id_assigned,
                        transaction_executor: profile_address,
                        block_timestamp: get_block_timestamp(),
                    }
                );
            pub_id_assigned
        }

        /// @notice performs the mirror function
        /// @param mirrorParams the MirrorParams struct
        fn mirror(
            ref self: ComponentState<TContractState>,
            mirrorParams: MirrorParams,
            profile_contract_address: ContractAddress
        ) -> u256 {
            self._validatePointedPub(mirrorParams.profile_address, mirrorParams.pointed_pub_id);
            let ref_mirrorParams = mirrorParams.clone();
            let pub_id_assigned = get_dep_component!(@self,Profile).get_user_publication_count(mirrorParams.profile_address);
            let publication = self
                .get_publication(mirrorParams.pointed_profile_address, mirrorParams.pointed_pub_id);

            self
                ._fillRefeferencePublicationStorage(
                    mirrorParams.profile_address,
                    publication.content_URI,
                    mirrorParams.pointed_profile_address,
                    mirrorParams.pointed_pub_id,
                    PublicationType::Mirror,
                    profile_contract_address,
                );

            self
                .emit(
                    MirrorCreated {
                        mirrorParams: ref_mirrorParams,
                        publication_id: pub_id_assigned,
                        transaction_executor: mirrorParams.profile_address,
                        block_timestamp: get_block_timestamp(),
                    }
                );

            pub_id_assigned
        }

        /// @notice performs the quote function
        /// @param reference_pub_type publication type
        /// @param quoteParams the quoteParams struct
        fn quote(
            ref self: ComponentState<TContractState>,
            reference_pub_type: PublicationType,
            quoteParams: QuoteParams,
            profile_contract_address: ContractAddress
        ) -> u256 {
            let ref_quoteParams = quoteParams.clone();
            let reference_pub_type = self._as_reference_pub_params(reference_pub_type);
            assert(reference_pub_type == PublicationType::Quote, UNSUPPORTED_PUB_TYPE);

            let pub_id_assigned = self
                ._createReferencePublication(
                    quoteParams.profile_address,
                    quoteParams.content_URI,
                    quoteParams.pointed_profile_address,
                    quoteParams.pointed_pub_id,
                    reference_pub_type,
                    profile_contract_address
                );

            self
                .emit(
                    QuoteCreated {
                        quoteParams: ref_quoteParams,
                        publication_id: pub_id_assigned,
                        transaction_executor: quoteParams.profile_address,
                        block_timestamp: get_block_timestamp(),
                    }
                );
            pub_id_assigned
        }

        // *************************************************************************
        //                              GETTERS
        // *************************************************************************

        /// @notice gets the publication's content URI
        /// @param profile_address the profile address to be queried
        /// @param pub_id the ID of the publication to be queried
        fn get_publication_content_uri(
            self: @ComponentState<TContractState>, profile_address: ContractAddress, pub_id: u256
        ) -> ByteArray {
            self._getContentURI(profile_address, pub_id)
        }

        /// @notice retrieves a publication
        /// @param profile_address the profile address to be queried
        /// @param pub_id_assigned the ID of the publication to be retrieved
        fn get_publication(
            self: @ComponentState<TContractState>,
            profile_address: ContractAddress,
            pub_id_assigned: u256
        ) -> Publication {
            self.publication.read((profile_address, pub_id_assigned))
        }

        /// @notice retrieves a publication type
        /// @param profile_address the profile address to be queried
        /// @param pub_id_assigned the ID of the publication whose type is to be retrieved
        fn get_publication_type(
            self: @ComponentState<TContractState>,
            profile_address: ContractAddress,
            pub_id_assigned: u256
        ) -> PublicationType {
            self._getPublicationType(profile_address, pub_id_assigned)
        }
    }
    // *************************************************************************
    //                            PRIVATE FUNCTIONS
    // *************************************************************************
    #[generate_trait]
    impl InternalImpl<
        TContractState, +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl Profile: ProfileComponent::HasComponent<TContractState>
    > of InternalTrait<TContractState> {
        /// @notice fill root of publication
        /// @param profile_address the profile address creating the publication
        /// @param pointed_profile_address the profile address being pointed to by this publication
        /// @param pointed_pub_id the ID of the publication being pointed to by this publication
        fn _fillRootOfPublicationInStorage(
            ref self: ComponentState<TContractState>,
            profile_address: ContractAddress,
            pointed_profile_address: ContractAddress,
            pointed_pub_id: u256,
            profile_contract_address: ContractAddress
        ) -> ContractAddress {
            let mut publication = self.publication.read((profile_address, pointed_pub_id));
            let pointedPub: Publication = self.publication.read((profile_address, pointed_pub_id));
            let publication_type: PublicationType = pointedPub.pub_Type;
            match publication_type {
                PublicationType::Post => {
                    publication.root_pub_id = pointed_pub_id;
                    publication.root_profile_address = pointed_profile_address;
                },
                PublicationType::Nonexistent |
                PublicationType::Mirror => { return 0.try_into().unwrap(); },
                PublicationType::Comment |
                PublicationType::Quote => {
                    publication.root_pub_id = pointedPub.root_pub_id;
                    publication.root_profile_address = pointedPub.root_profile_address;
                }
            };
            self.publication.write((profile_address, pointed_pub_id), publication);
            let publication: Publication = self.publication.read((profile_address, pointed_pub_id));
            publication.root_profile_address
        }

        /// @notice fill reference publication
        /// @param profile_address the profile address creating the publication
        /// @param content_URI uri of the publication content
        /// @param pointed_profile_address the profile address being pointed to by this publication
        /// @param pointed_pub_id the ID of the publication being pointed to by this publication
        // @param reference_pub_type reference publication type
        fn _fillRefeferencePublicationStorage(
            ref self: ComponentState<TContractState>,
            profile_address: ContractAddress,
            content_URI: ByteArray,
            pointed_profile_address: ContractAddress,
            pointed_pub_id: u256,
            referencePubType: PublicationType,
            profile_contract_address: ContractAddress
        ) -> (u256, ContractAddress) {
            let mut profile_instance = get_dep_component_mut!(ref self,Profile);
            let pub_id_assigned = profile_instance.increment_publication_count(profile_address);
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

        /// @notice create reference publication
        /// @param profile_address the profile address creating the publication
        /// @param content_URI uri of the publication content
        /// @param pointed_profile_address the profile address being pointed to by this publication
        /// @param pointed_pub_id the ID of the publication being pointed to by this publication
        // @param reference_pub_type reference publication type
        fn _createReferencePublication(
            ref self: ComponentState<TContractState>,
            profile_address: ContractAddress,
            content_URI: ByteArray,
            pointed_profile_address: ContractAddress,
            pointed_pub_id: u256,
            referencePubType: PublicationType,
            profile_contract_address: ContractAddress
        ) -> u256 {
            self._validatePointedPub(pointed_profile_address, pointed_pub_id);

            let (pub_id_assigned, _root_profile_address) = self
                ._fillRefeferencePublicationStorage(
                    profile_address,
                    content_URI,
                    pointed_profile_address,
                    pointed_pub_id,
                    referencePubType,
                    profile_contract_address
                );

            pub_id_assigned
        }

        /// @notice returns the publication type
        // @param reference_pub_type reference publication type
        fn _as_reference_pub_params(
            ref self: ComponentState<TContractState>, reference_pub_type: PublicationType
        ) -> PublicationType {
            match reference_pub_type {
                PublicationType::Quote => PublicationType::Quote,
                PublicationType::Comment => PublicationType::Comment,
                _ => PublicationType::Nonexistent,
            }
        }



        /// @notice validates pointed publication
        /// @param profile_address the profile address that created the publication
        /// @param pub_id the publication ID of the publication to be checked
        fn _validatePointedPub(
            ref self: ComponentState<TContractState>, profile_address: ContractAddress, pub_id: u256
        ) {
            // If it points to itself, it fails because type will be non existent.
            let pointedPubType = self._getPublicationType(profile_address, pub_id);
            if pointedPubType == PublicationType::Nonexistent
                || pointedPubType == PublicationType::Mirror {
                panic!("invalid pointed publication");
            }
        }

        /// @notice gets the publication type
        /// @param profile_address the profile address that created the publication
        /// @param pub_id_assigned the publication ID of the publication to be queried
        fn _getPublicationType(
            self: @ComponentState<TContractState>,
            profile_address: ContractAddress,
            pub_id_assigned: u256
        ) -> PublicationType {
            let publication: Publication = self
                .publication
                .read((profile_address, pub_id_assigned));
            let pub_type_option: PublicationType = publication.pub_Type;
            match pub_type_option {
                PublicationType::Nonexistent => PublicationType::Nonexistent,
                PublicationType::Post => PublicationType::Post,
                PublicationType::Comment => PublicationType::Comment,
                PublicationType::Mirror => PublicationType::Mirror,
                PublicationType::Quote => PublicationType::Quote,
            }
        }

        /// @notice gets the publication content URI
        /// @param profile_address the profile address that created the publication
        /// @param pub_id the publication ID of the publication to be queried
        fn _getContentURI(
            self: @ComponentState<TContractState>, profile_address: ContractAddress, pub_id: u256
        ) -> ByteArray {
            let publication: Publication = self.publication.read((profile_address, pub_id));
            let pub_type_option: PublicationType = publication.pub_Type;

            if pub_type_option == PublicationType::Nonexistent {
                return "0";
            }
            if pub_type_option == PublicationType::Mirror {
                let pointedPub: Publication = self
                    .publication
                    .read((publication.pointed_profile_address, publication.pointed_pub_id));
                let content_uri: ByteArray = pointedPub.content_URI;
                content_uri
            } else {
                let publication: Publication = self.publication.read((profile_address, pub_id));
                let content_uri: ByteArray = publication.content_URI;
                content_uri
            }
        }
    }
}

