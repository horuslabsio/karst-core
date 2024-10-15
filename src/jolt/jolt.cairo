#[starknet::component]
pub mod JoltComponent {
    // *************************************************************************
    //                            IMPORTS
    // *************************************************************************
    use core::num::traits::zero::Zero;
    use core::hash::HashStateTrait;
    use core::pedersen::PedersenTrait;
    use starknet::{
        ContractAddress, get_caller_address, get_contract_address, get_block_timestamp,
        get_tx_info,
        storage::{
            StoragePointerWriteAccess, StoragePointerReadAccess, Map, StorageMapReadAccess,
            StorageMapWriteAccess
        }
    };
    use karst::base::{
        constants::errors::Errors,
        constants::types::{JoltData, JoltParams, JoltType, JoltStatus, SubscriptionData}
    };
    use karst::interfaces::{IJolt::IJolt, IERC20::{IERC20Dispatcher, IERC20DispatcherTrait}};

    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::access::ownable::OwnableComponent::{OwnableMixinImpl, InternalImpl};

    // *************************************************************************
    //                            STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        fee_address: ContractAddress,
        jolt: Map::<u256, JoltData>,
        subscriptions: Map::<u256, SubscriptionData>,
        renewal_iterations: Map::<(ContractAddress, u256), u256>,
    }

    // *************************************************************************
    //                            EVENTS
    // *************************************************************************
    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        Jolted: Jolted,
        JoltRequested: JoltRequested,
        JoltRequestFullfilled: JoltRequestFullfilled,
    }

    #[derive(Drop, starknet::Event)]
    pub struct Jolted {
        pub jolt_id: u256,
        pub jolt_type: felt252,
        pub sender: ContractAddress,
        pub recipient: ContractAddress,
        pub block_timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct JoltRequested {
        pub jolt_id: u256,
        pub jolt_type: felt252,
        pub sender: ContractAddress,
        pub recipient: ContractAddress,
        pub expiration_timestamp: u64,
        pub block_timestamp: u64,
    }

    #[derive(Drop, starknet::Event)]
    pub struct JoltRequestFullfilled {
        pub jolt_id: u256,
        pub jolt_type: felt252,
        pub sender: ContractAddress,
        pub recipient: ContractAddress,
        pub expiration_timestamp: u64,
        pub block_timestamp: u64,
    }

    const MAX_TIP: u256 = 1000;

    #[embeddable_as(Jolt)]
    impl JoltImpl<
        TContractState, 
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl Ownable: OwnableComponent::HasComponent<TContractState>
    > of IJolt<ComponentState<TContractState>> {
        // *************************************************************************
        //                              EXTERNALS
        // *************************************************************************

        /// @notice multi-faceted transfer logic
        /// @param jolt_params required jolting parameters
        fn jolt(ref self: ComponentState<TContractState>, jolt_params: JoltParams) -> u256 {
            let sender = get_caller_address();
            let tx_info = get_tx_info().unbox();
            let tx_timestamp = get_block_timestamp();

            // generate jolt_id
            let jolt_hash = PedersenTrait::new(0)
                .update(jolt_params.recipient.into())
                .update(jolt_params.amount.low.into())
                .update(jolt_params.amount.high.into())
                .update(tx_info.nonce)
                .update(4)
                .finalize();

            let jolt_id: u256 = jolt_hash.try_into().unwrap();

            // jolt
            let mut jolt_status = JoltStatus::PENDING;
            let erc20_contract_address = jolt_params.erc20_contract_address;

            let jolt_type = @jolt_params.jolt_type;
            match jolt_type {
                JoltType::Tip => {
                    let _jolt_status = self
                        ._tip(
                            jolt_id,
                            sender,
                            jolt_params.recipient,
                            jolt_params.amount,
                            erc20_contract_address
                        );
                    jolt_status = _jolt_status;
                },
                JoltType::Transfer => {
                    let _jolt_status = self
                        ._transfer(
                            jolt_id,
                            sender,
                            jolt_params.recipient,
                            jolt_params.amount,
                            erc20_contract_address
                        );
                    jolt_status = _jolt_status;
                },
                JoltType::Subscription => {
                    let (sub_id, renewal_status, renewal_iterations) = jolt_params.subscription_details;
                    let _jolt_status = self
                        ._subscribe(
                            jolt_id,
                            sub_id,
                            sender,
                            jolt_params.amount,
                            renewal_status,
                            renewal_iterations,
                            erc20_contract_address
                        );
                    jolt_status = _jolt_status;
                },
                JoltType::Request => {
                    let _jolt_status = self
                        ._request(
                            jolt_id,
                            sender,
                            jolt_params.recipient,
                            jolt_params.amount,
                            jolt_params.expiration_stamp,
                            erc20_contract_address
                        );
                    jolt_status = _jolt_status;
                }
            };

            // prefill tx data
            let jolt_data = JoltData {
                jolt_id: jolt_id,
                jolt_type: jolt_params.jolt_type,
                sender: sender,
                recipient: jolt_params.recipient,
                memo: jolt_params.memo,
                amount: jolt_params.amount,
                status: jolt_status,
                expiration_stamp: jolt_params.expiration_stamp,
                block_timestamp: tx_timestamp,
                erc20_contract_address: jolt_params.erc20_contract_address
            };

            self.jolt.write(jolt_id, jolt_data);
            return jolt_id;
        }

        /// @notice fulfills a pending jolt request
        /// @param jolt_id id of jolt request to be fulfilled
        fn fulfill_request(ref self: ComponentState<TContractState>, jolt_id: u256) -> bool {
            // get jolt details
            let mut jolt_details = self.jolt.read(jolt_id);
            let sender = get_caller_address();

            // validate request
            assert(jolt_details.jolt_type == JoltType::Request, Errors::INVALID_JOLT);
            assert(jolt_details.status == JoltStatus::PENDING, Errors::INVALID_JOLT);
            assert(sender == jolt_details.recipient, Errors::INVALID_JOLT_RECIPIENT);

            // if expired write jolt status to expired and exit
            if (get_block_timestamp() > jolt_details.expiration_stamp) {
                let jolt_data = JoltData { status: JoltStatus::EXPIRED, ..jolt_details };
                self.jolt.write(jolt_id, jolt_data);
                return false;
            }

            // else fulfill request
            self._fulfill_request(jolt_id, sender, jolt_details)
        }

        /// @notice contains logic for auto renewal of subscriptions
        /// @dev can be automated using cron jobs in a backend service
        /// @param jolt_id id of jolt subscription to auto-renew
        /// TODO: restrict only to a whitelisted renewer
        fn auto_renew(ref self: ComponentState<TContractState>, profile: ContractAddress, jolt_id: u256) -> bool {
            self._auto_renew(profile, jolt_id)
        }

        fn create_subscription(
            ref self: ComponentState<TContractState>,
            fee_address: ContractAddress, 
            amount: u256, 
            erc20_contract_address: ContractAddress
        ) {
            let caller = get_caller_address();
            let tx_info = get_tx_info().unbox();

            let subscription_data = SubscriptionData {
                creator: caller,
                fee_address: fee_address,
                amount: amount,
                erc20_contract_address: erc20_contract_address
            };

            let sub_id = PedersenTrait::new(0)
                .update(fee_address.into())
                .update(amount.low.into())
                .update(amount.high.into())
                .update(tx_info.nonce)
                .update(4)
                .finalize();

            self.subscriptions.write(sub_id.try_into().unwrap(), subscription_data);
        }

        /// @notice sets the fee address which receives subscription payments and maybe actual fees
        /// in the future?
        /// @param _fee_address address to be set
        fn set_fee_address(ref self: ComponentState<TContractState>, _fee_address: ContractAddress) {
            get_dep_component!(@self, Ownable).assert_only_owner();
            self.fee_address.write(_fee_address);
        }

        // *************************************************************************
        //                              GETTERS
        // *************************************************************************

        /// @notice gets the associated data for a jolt id
        /// @param jolt_id id of jolt who's data is to be gotten
        /// @returns JoltData struct containing jolt details
        fn get_jolt(self: @ComponentState<TContractState>, jolt_id: u256) -> JoltData {
            self.jolt.read(jolt_id)
        }

        /// @notice gets the subscription data for a particular subscription
        /// @param subscription_id id of subscription to be retrieved
        /// @returns SubscriptionData struct containing subscription details
        fn get_subscription_data(
            self: @ComponentState<TContractState>, subscription_id: u256) -> SubscriptionData {
            self.subscriptions.read(subscription_id)
        }

        /// @notice gets the fee address
        /// @returns the fee address for contract
        fn get_fee_address(self: @ComponentState<TContractState>) -> ContractAddress {
            self.fee_address.read()
        }
    }

    // *************************************************************************
    //                              PRIVATE FUNCTIONS
    // *************************************************************************
    #[generate_trait]
    impl Private<
        TContractState, 
        +HasComponent<TContractState>,
        +Drop<TContractState>,
        impl Ownable: OwnableComponent::HasComponent<TContractState>
    > of PrivateTrait<TContractState> {
        fn _initializer(ref self: ComponentState<TContractState>, owner: ContractAddress) {
            let mut ownable_comp = get_dep_component_mut!(ref self, Ownable);
            ownable_comp.initializer(owner);
        }
        
        /// @notice contains the tipping logic
        /// @param jolt_id id of txn
        /// @param sender the profile performing the tipping
        /// @param recipient the profile being tipped
        /// @param amount the amount to be tipped
        /// @param erc20_contract_address the address of token used in tipping
        /// @returns JoltStatus status of the txn
        fn _tip(
            ref self: ComponentState<TContractState>,
            jolt_id: u256,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256,
            erc20_contract_address: ContractAddress
        ) -> JoltStatus {
            // check that user is not self-tipping or tipping a non-existent address
            assert(sender != recipient, Errors::SELF_TIPPING);
            assert(recipient.is_non_zero(), Errors::INVALID_PROFILE_ADDRESS);

            // tip user
            self._transfer_helper(erc20_contract_address, sender, recipient, amount);

            // emit event
            self
                .emit(
                    Jolted {
                        jolt_id,
                        jolt_type: 'TIP',
                        sender,
                        recipient: recipient,
                        block_timestamp: get_block_timestamp(),
                    }
                );

            // return txn status
            JoltStatus::SUCCESSFUL
        }

        /// @notice contains the transfer logic
        /// @param jolt_id id of txn
        /// @param sender the profile performing the transfer
        /// @param recipient the profile being transferred to
        /// @param amount the amount to be transferred
        /// @param erc20_contract_address the address of token used
        /// @returns JoltStatus status of the txn
        fn _transfer(
            ref self: ComponentState<TContractState>,
            jolt_id: u256,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256,
            erc20_contract_address: ContractAddress
        ) -> JoltStatus {
            // check that user is not transferring to self or to a non-existent address
            assert(sender != recipient, Errors::SELF_TRANSFER);
            assert(recipient.is_non_zero(), Errors::INVALID_PROFILE_ADDRESS);

            // transfer to recipient
            self._transfer_helper(erc20_contract_address, sender, recipient, amount);

            // emit event
            self
                .emit(
                    Jolted {
                        jolt_id,
                        jolt_type: 'TRANSFER',
                        sender,
                        recipient: recipient,
                        block_timestamp: get_block_timestamp(),
                    }
                );

            // return txn status
            JoltStatus::SUCCESSFUL
        }

        /// @notice contains the subscription logic
        /// @param jolt_id id of txn
        /// @param sub_id subscription id
        /// @param sender the profile performing the subscription
        /// @param amount the amount to pay
        /// @param renewal_status status of renewal
        /// @param renewal_iterations no. of times to auto renew
        /// @param erc20_contract_address the address of token used
        /// @returns JoltStatus status of the txn
        fn _subscribe(
            ref self: ComponentState<TContractState>,
            jolt_id: u256,
            sub_id: u256,
            sender: ContractAddress,
            amount: u256,
            renewal_status: bool,
            renewal_iterations: u256,
            erc20_contract_address: ContractAddress
        ) -> JoltStatus {
            let dispatcher = IERC20Dispatcher { contract_address: erc20_contract_address };
            let this_contract = get_contract_address();

            if (renewal_status == true) {
                // check allowances match auto-renew iterations
                let allowance = dispatcher.allowance(sender, this_contract);
                assert(allowance >= renewal_iterations * amount, Errors::INSUFFICIENT_ALLOWANCE);

                self.renewal_iterations.write((sender, sub_id), renewal_iterations);
            }

            // send subscription amount to fee address
            let subscription_data = self.subscriptions.read(sub_id);
            self._transfer_helper(erc20_contract_address, sender, subscription_data.fee_address, amount);

            // emit event
            self
                .emit(
                    Jolted {
                        jolt_id,
                        jolt_type: 'SUBSCRIPTION',
                        sender,
                        recipient: subscription_data.fee_address,
                        block_timestamp: get_block_timestamp(),
                    }
                );

            // return txn status
            JoltStatus::SUCCESSFUL
        }

        /// @notice contains the request logic
        /// @param jolt_id id of txn
        /// @param sender the profile performing the request
        /// @param recipient the profile being requested of
        /// @param amount the amount to be tipped
        /// @param expiration_timestamp timestamp of when the request will expire
        /// @param erc20_contract_address the address of token used
        /// @returns JoltStatus status of the txn
        fn _request(
            ref self: ComponentState<TContractState>,
            jolt_id: u256,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256,
            expiration_timestamp: u64,
            erc20_contract_address: ContractAddress
        ) -> JoltStatus {
            // check that user is not requesting to self or to a non-existent address and expiration
            // time exceeds current time
            assert(sender != recipient, Errors::SELF_REQUEST);
            assert(recipient.is_non_zero(), Errors::INVALID_PROFILE_ADDRESS);
            assert(expiration_timestamp > get_block_timestamp(), Errors::INVALID_EXPIRATION_STAMP);

            // emit event
            self
                .emit(
                    JoltRequested {
                        jolt_id,
                        jolt_type: 'REQUEST',
                        sender,
                        recipient: recipient,
                        expiration_timestamp,
                        block_timestamp: get_block_timestamp(),
                    }
                );

            // return txn status
            JoltStatus::PENDING
        }

        /// @notice internal logic to fulfill a request
        /// @param sender the profile fulfilling the request
        /// @param jolt_details details of the jolt to be fulfilled
        /// @returns bool status of the txn
        fn _fulfill_request(
            ref self: ComponentState<TContractState>, jolt_id: u256, sender: ContractAddress, jolt_details: JoltData
        ) -> bool {
            // transfer request amount
            self
                ._transfer_helper(
                    jolt_details.erc20_contract_address,
                    sender,
                    jolt_details.sender,
                    jolt_details.amount
                );

            // update jolt details
            let jolt_data = JoltData { status: JoltStatus::SUCCESSFUL, ..jolt_details };
            self.jolt.write(jolt_id, jolt_data);

            // emit events
            self
                .emit(
                    JoltRequestFullfilled {
                        jolt_id,
                        jolt_type: 'REQUEST FULFILLMENT',
                        sender: jolt_details.recipient,
                        recipient: jolt_details.sender,
                        expiration_timestamp: jolt_details.expiration_stamp,
                        block_timestamp: get_block_timestamp(),
                    }
                );

            return true;
        }

        /// @notice internal logic to auto renew a subscription
        /// @param sender the profile renewing a subscription
        /// @param renewal_id id jolt to be renewed
        /// @returns bool status of the txn
        fn _auto_renew(ref self: ComponentState<TContractState>, sender: ContractAddress, sub_id: u256) -> bool {
            let tx_info = get_tx_info().unbox();
            let subscription_data = self.subscriptions.read(sub_id);
            let iterations = self.renewal_iterations.read((sender, sub_id));

            // check iteration is greater than 0 else shouldn't auto renew
            assert(iterations > 0, Errors::AUTO_RENEW_DURATION_ENDED);

            // send subscription amount to fee address
            let amount = subscription_data.amount;
            let fee_address = subscription_data.fee_address;
            let erc20_contract_address = subscription_data.erc20_contract_address;
            self._transfer_helper(erc20_contract_address, sender, fee_address, amount);

            // generate jolt_id
            let jolt_hash = PedersenTrait::new(0)
                .update(fee_address.into())
                .update(amount.low.into())
                .update(amount.high.into())
                .update(tx_info.nonce)
                .update(4)
                .finalize();

            let jolt_id: u256 = jolt_hash.try_into().unwrap();

            // reduce iteration by one month
            self.renewal_iterations.write((sender, sub_id), iterations - 1);

            // prefill tx data
            let jolt_data = JoltData {
                jolt_id: jolt_id,
                jolt_type: JoltType::Subscription,
                sender: sender,
                recipient: fee_address,
                memo: "auto renew successful",
                amount: amount,
                status: JoltStatus::SUCCESSFUL,
                expiration_stamp: 0,
                block_timestamp: get_block_timestamp(),
                erc20_contract_address
            };

            // write to storage
            self.jolt.write(jolt_id, jolt_data);

            // emit event
            self
                .emit(
                    Jolted {
                        jolt_id,
                        jolt_type: 'SUBSCRIPTION',
                        sender,
                        recipient: fee_address,
                        block_timestamp: get_block_timestamp(),
                    }
                );

            // return txn status
            return true;
        }

        /// @notice internal logic to perform an ERC20 transfer
        /// @param erc20_contract_address address of the token to be transferred
        /// @param sender profile sending the token
        /// @param recipient profile receiving the token
        /// @param amount amount to be transferred
        fn _transfer_helper(
            ref self: ComponentState<TContractState>,
            erc20_contract_address: ContractAddress,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) {
            let dispatcher = IERC20Dispatcher { contract_address: erc20_contract_address };

            // check allowance
            let allowance = dispatcher.allowance(sender, get_contract_address());
            assert(allowance >= amount, Errors::INSUFFICIENT_ALLOWANCE);

            // transfer to recipient
            dispatcher.transfer_from(sender, recipient, amount);
        }
    }
}
