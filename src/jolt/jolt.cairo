#[starknet::contract]
pub mod Jolt {
    // *************************************************************************
    //                            IMPORTS
    // *************************************************************************
    use core::num::traits::zero::Zero;
    use core::hash::HashStateTrait;
    use core::pedersen::PedersenTrait;
    use starknet::{
        ContractAddress, ClassHash, get_caller_address, get_contract_address, get_block_timestamp,
        get_tx_info,
        storage::{
            StoragePointerWriteAccess, StoragePointerReadAccess, Map, StorageMapReadAccess,
            StorageMapWriteAccess
        }
    };
    use karst::base::{
        constants::errors::Errors,
        constants::types::{JoltData, JoltParams, JoltType, JoltStatus, RenewalData}
    };
    use karst::interfaces::{IJolt::IJolt, IERC20::{IERC20Dispatcher, IERC20DispatcherTrait}};

    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::upgrades::interface::IUpgradeable;

    // *************************************************************************
    //                            COMPONENTS
    // *************************************************************************
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    // Ownable
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    // Upgradeable
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    // *************************************************************************
    //                            STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        fee_address: ContractAddress,
        jolt: Map::<u256, JoltData>,
        renewals: Map::<(ContractAddress, u256), RenewalData>,
    }

    // *************************************************************************
    //                            EVENTS
    // *************************************************************************
    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
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

    // *************************************************************************
    //                            CONSTRUCTOR
    // *************************************************************************
    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.ownable.initializer(owner);
    }

    #[abi(embed_v0)]
    impl JoltImpl of IJolt<ContractState> {
        // *************************************************************************
        //                              EXTERNALS
        // *************************************************************************
        fn jolt(ref self: ContractState, jolt_params: JoltParams) -> u256 {
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
                    let _jolt_status = self
                        ._subscribe(
                            jolt_id,
                            sender,
                            jolt_params.amount,
                            jolt_params.auto_renewal,
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

        fn set_fee_address(ref self: ContractState, _fee_address: ContractAddress) {
            self.ownable.assert_only_owner();
            self.fee_address.write(_fee_address);
        }

        fn fulfill_request(ref self: ContractState, jolt_id: u256) -> bool {
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

        fn auto_renew(ref self: ContractState, profile: ContractAddress, renewal_id: u256) -> bool {
            self._auto_renew(profile, renewal_id)
        }

        // *************************************************************************
        //                              GETTERS
        // *************************************************************************
        fn get_jolt(self: @ContractState, jolt_id: u256) -> JoltData {
            self.jolt.read(jolt_id)
        }

        fn get_fee_address(self: @ContractState) -> ContractAddress {
            self.fee_address.read()
        }
    }

    // *************************************************************************
    //                            UPGRADEABLE IMPL
    // *************************************************************************
    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.ownable.assert_only_owner();
            self.upgradeable.upgrade(new_class_hash);
        }
    }

    // *************************************************************************
    //                              PRIVATE FUNCTIONS
    // *************************************************************************
    #[generate_trait]
    impl Private of PrivateTrait {
        fn _tip(
            ref self: ContractState,
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

        fn _transfer(
            ref self: ContractState,
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

        fn _subscribe(
            ref self: ContractState,
            jolt_id: u256,
            sender: ContractAddress,
            amount: u256,
            auto_renewal: (bool, u256),
            erc20_contract_address: ContractAddress
        ) -> JoltStatus {
            let (renewal_status, renewal_duration) = auto_renewal;
            let dispatcher = IERC20Dispatcher { contract_address: erc20_contract_address };
            let this_contract = get_contract_address();
            let tx_info = get_tx_info().unbox();

            if (renewal_status == true) {
                // check allowances match auto-renew duration
                let allowance = dispatcher.allowance(sender, this_contract);
                assert(allowance >= renewal_duration * amount, Errors::INSUFFICIENT_ALLOWANCE);

                // generate renewal ID
                let renewal_hash = PedersenTrait::new(0)
                    .update(sender.into())
                    .update(jolt_id.low.into())
                    .update(jolt_id.high.into())
                    .update(tx_info.nonce)
                    .update(4)
                    .finalize();

                let renewal_id: u256 = renewal_hash.try_into().unwrap();

                // write renewal details to storage
                let renewal_data = RenewalData {
                    renewal_duration: renewal_duration,
                    renewal_amount: amount,
                    erc20_contract_address
                };
                self.renewals.write((sender, renewal_id), renewal_data);
            }

            // send subscription amount to fee address
            let fee_address = self.fee_address.read();
            self._transfer_helper(erc20_contract_address, sender, fee_address, amount);

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
            JoltStatus::SUCCESSFUL
        }

        fn _request(
            ref self: ContractState,
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

        fn _fulfill_request(
            ref self: ContractState, jolt_id: u256, sender: ContractAddress, jolt_details: JoltData
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

        fn _auto_renew(ref self: ContractState, sender: ContractAddress, renewal_id: u256) -> bool {
            let tx_info = get_tx_info().unbox();
            let amount = self.renewals.read((sender, renewal_id)).renewal_amount;
            let duration = self.renewals.read((sender, renewal_id)).renewal_duration;
            let erc20_contract_address = self
                .renewals
                .read((sender, renewal_id))
                .erc20_contract_address;

            // check duration is greater than 0 else shouldn't auto renew
            assert(duration > 0, Errors::AUTO_RENEW_DURATION_ENDED);

            // send subscription amount to fee address
            let fee_address = self.fee_address.read();
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

            // reduce duration by one month
            let renewal_data = RenewalData {
                renewal_duration: duration - 1, renewal_amount: amount, erc20_contract_address
            };
            self.renewals.write((sender, renewal_id), renewal_data);

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

        fn _transfer_helper(
            ref self: ContractState,
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
