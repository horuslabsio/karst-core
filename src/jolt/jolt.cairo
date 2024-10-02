#[starknet::contract]
pub mod Jolt {
    // *************************************************************************
    //                            IMPORTS
    // *************************************************************************
    use core::num::traits::zero::Zero;
    use core::hash::HashStateTrait;
    use core::pedersen::PedersenTrait;
    use starknet::{
        ContractAddress, ClassHash, get_caller_address, get_contract_address, get_block_timestamp, get_tx_info, contract_address_const,
        storage::{
            StoragePointerWriteAccess, StoragePointerReadAccess, Map, StorageMapReadAccess, StorageMapWriteAccess
        }
    };
    use karst::base::{
        constants::errors::Errors, 
        constants::types::{joltData, joltParams, JoltType, JoltCurrency, JoltStatus, RenewalData},
        constants::contract_addresses::Addresses,
    };
    use karst::interfaces::{
        IJolt::IJolt,
        IERC20::{IERC20Dispatcher, IERC20DispatcherTrait}
    };
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
        jolt: Map::<u256, joltData>,
        total_jolts: Map::<ContractAddress, u256>,
        renewals: Map::<(ContractAddress, u256), RenewalData>,
    }

    // *************************************************************************
    //                            EVENTS
    // *************************************************************************
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        Jolted: Jolted
    }

    #[derive(Drop, starknet::Event)]
    pub struct Jolted {
        jolt_id: u256,
        jolt_type: felt252,
        sender: ContractAddress,
        recipient: ContractAddress,
        block_timestamp: u64,
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
        fn jolt(ref self: ContractState, jolt_params: joltParams) -> bool {
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

            // get the appropriate contract address
            let mut erc20_contract_address: ContractAddress = contract_address_const::<0>();
            let jolt_currency = @jolt_params.currency;

            match jolt_currency {
                JoltCurrency::USDT => erc20_contract_address = Addresses::USDT.try_into().unwrap(),
                JoltCurrency::USDC => erc20_contract_address = Addresses::USDC.try_into().unwrap(),
                JoltCurrency::ETH => erc20_contract_address = Addresses::ETH.try_into().unwrap(),
                JoltCurrency::STRK => erc20_contract_address = Addresses::STRK.try_into().unwrap()
            };

            // jolt
            let mut tx_status = false;
            let mut jolt_status = JoltStatus::PENDING;

            let jolt_type = @jolt_params.jolt_type;
            match jolt_type {
                JoltType::Tip => {
                    let (_tx_status, _jolt_status) = self._tip(
                        jolt_id, 
                        sender, 
                        jolt_params.recipient, 
                        jolt_params.amount, 
                        erc20_contract_address
                    );

                    tx_status = _tx_status;
                    jolt_status = _jolt_status;
                },
                JoltType::Transfer => {
                    let (_tx_status, _jolt_status) = self._transfer(
                        jolt_id, 
                        sender, 
                        jolt_params.recipient, 
                        jolt_params.amount, 
                        erc20_contract_address
                    );

                    tx_status = _tx_status;
                    jolt_status = _jolt_status;
                },
                JoltType::Subscription => {
                    // check that currency is a stable
                    if(jolt_currency != @JoltCurrency::USDT || jolt_currency != @JoltCurrency::USDC) {
                        panic!("Karst: subscription can only be done with stables!");
                    }

                    let (_tx_status, _jolt_status)= self._subscribe(
                        jolt_id, 
                        sender,  
                        jolt_params.amount, 
                        jolt_params.auto_renewal,
                        erc20_contract_address
                    );

                    tx_status = _tx_status;
                    jolt_status = _jolt_status;
                },
                JoltType::Request => {
                    let (_tx_status, _jolt_status) = self._request(
                        jolt_id, 
                        sender, 
                        jolt_params.recipient, 
                        jolt_params.amount, 
                        erc20_contract_address
                    );

                    tx_status = _tx_status;
                    jolt_status = _jolt_status;
                }
            };

            // get jolt amount in usd
            let mut amount_in_usd = self._get_usd_equiv(jolt_params.amount, erc20_contract_address);

            // prefill tx data
            let jolt_data = joltData {
                jolt_id: jolt_id,
                jolt_type: jolt_params.jolt_type,
                sender: sender,
                recipient: jolt_params.recipient,
                memo: jolt_params.memo,
                amount: jolt_params.amount,
                amount_in_usd: amount_in_usd,
                currency: jolt_params.currency,
                status: jolt_status,
                expiration_stamp: jolt_params.expiration_stamp,
                block_timestamp: tx_timestamp
            };
            let total_jolts_recieved = self.total_jolts.read(jolt_params.recipient) + amount_in_usd;

            // write to storage
            self.jolt.write(jolt_id, jolt_data);
            self.total_jolts.write(jolt_params.recipient, total_jolts_recieved);

            return tx_status;
        }

        fn set_fee_address(ref self: ContractState, _fee_address: ContractAddress) {
            self.ownable.assert_only_owner();
            self.fee_address.write(_fee_address);
        }

        fn auto_renew(ref self: ContractState, profile: ContractAddress, renewal_id: u256) -> bool {
            self._auto_renew(profile, renewal_id)
        }
        
        // *************************************************************************
        //                              GETTERS
        // *************************************************************************
        fn get_jolt(self: @ContractState, jolt_id: u256) -> joltData {
            self.jolt.read(jolt_id)
        }

        fn total_jolts_received(self: @ContractState, profile: ContractAddress) -> u256 {
            self.total_jolts.read(profile)
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

    #[generate_trait]
    impl Private of PrivateTrait {
        fn _tip(
            ref self: ContractState, 
            jolt_id: u256, 
            sender: ContractAddress, 
            recipient: ContractAddress,
            amount: u256,
            erc20_contract_address: ContractAddress
        ) -> (bool, JoltStatus) {
            // check that user is not self-tipping or tipping a non-existent address
            assert(sender != recipient, Errors::SELF_TIPPING);
            assert(recipient.is_non_zero(), Errors::INVALID_PROFILE_ADDRESS);

            // check that tip does not exceed maximum tip
            let tipped_amount = self._get_usd_equiv(amount, erc20_contract_address);
            assert(tipped_amount <= MAX_TIP, Errors::MAX_TIPPING);

            // tip user
            let dispatcher = IERC20Dispatcher { contract_address: erc20_contract_address };
            dispatcher.transfer_from(sender, recipient, amount);

            // emit event
            self.emit(
                Jolted {
                    jolt_id,
                    jolt_type: 'TIP',
                    sender,
                    recipient: recipient,
                    block_timestamp: get_block_timestamp(),
                }
            );

            // return txn status
            (true, JoltStatus::SUCCESSFUL)
        }

        fn _transfer(
            ref self: ContractState, 
            jolt_id: u256, 
            sender: ContractAddress, 
            recipient: ContractAddress,
            amount: u256,
            erc20_contract_address: ContractAddress
        ) -> (bool, JoltStatus) {
            // check that user is not transferring to self or to a non-existent address
            assert(sender != recipient, Errors::SELF_TRANSFER);
            assert(recipient.is_non_zero(), Errors::INVALID_PROFILE_ADDRESS);

            // transfer to recipient
            let dispatcher = IERC20Dispatcher { contract_address: erc20_contract_address };
            dispatcher.transfer_from(sender, recipient, amount);

            // emit event
            self.emit(
                Jolted {
                    jolt_id,
                    jolt_type: 'TRANSFER',
                    sender,
                    recipient: recipient,
                    block_timestamp: get_block_timestamp(),
                }
            );

            // return txn status
            (true, JoltStatus::SUCCESSFUL)
        }

        fn _subscribe(
            ref self: ContractState, 
            jolt_id: u256, 
            sender: ContractAddress,
            amount: u256,
            auto_renewal: (bool, u256),
            erc20_contract_address: ContractAddress
        ) -> (bool, JoltStatus) {
            let (renewal_status, renewal_duration_in_months) = auto_renewal;
            let dispatcher = IERC20Dispatcher { contract_address: erc20_contract_address };
            let this_contract = get_contract_address();
            let tx_info = get_tx_info().unbox();

            if (renewal_status) {
                // check allowances match auto-renew duration
                let allowance = dispatcher.allowance(sender, this_contract);
                assert(allowance == renewal_duration_in_months * amount, Errors::INSUFFICIENT_ALLOWANCE);

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
                let renewal_data = RenewalData { renewal_duration: renewal_duration_in_months, renewal_amount: amount, erc20_contract_address };
                self.renewals.write((sender, renewal_id), renewal_data);
            }

            // send subscription amount to fee address
            let fee_address = self.fee_address.read();
            dispatcher.transfer_from(sender, fee_address, amount);

            // emit event
            self.emit(
                Jolted {
                    jolt_id,
                    jolt_type: 'SUBSCRIPTION',
                    sender,
                    recipient: fee_address,
                    block_timestamp: get_block_timestamp(),
                }
            );

            // return txn status
            (true, JoltStatus::SUCCESSFUL)
        }

        // TODO
        fn _request(
            ref self: ContractState, 
            jolt_id: u256, 
            sender: ContractAddress, 
            recipient: ContractAddress,
            amount: u256,
            erc20_contract_address: ContractAddress
        ) -> (bool, JoltStatus) {
            (true, JoltStatus::SUCCESSFUL)
        }

        fn _auto_renew(
            ref self: ContractState,  
            sender: ContractAddress,
            renewal_id: u256
        ) -> bool {
            let tx_info = get_tx_info().unbox();
            let amount = self.renewals.read((sender, renewal_id)).renewal_amount;
            let duration = self.renewals.read((sender, renewal_id)).renewal_duration;
            let erc20_contract_address = self.renewals.read((sender, renewal_id)).erc20_contract_address;
            let dispatcher = IERC20Dispatcher { contract_address: erc20_contract_address };

            // check duration is greater than 0 else shouldn't auto renew
            assert(duration > 0, Errors::AUTO_RENEW_DURATION_ENDED);

            // send subscription amount to fee address
            let fee_address = self.fee_address.read();
            dispatcher.transfer_from(sender, fee_address, amount);

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
            let renewal_data = RenewalData { renewal_duration: duration - 1, renewal_amount: amount, erc20_contract_address };
            self.renewals.write((sender, renewal_id), renewal_data);

            // get currency
            let mut currency = JoltCurrency::USDT;
            let erc20_name = dispatcher.name();
            if (erc20_name == "USDC") {
                currency = JoltCurrency::USDC;
            }

            // prefill tx data
            let jolt_data = joltData {
                jolt_id: jolt_id,
                jolt_type: JoltType::Subscription,
                sender: sender,
                recipient: fee_address,
                memo: "auto renew successful",
                amount: amount,
                amount_in_usd: amount,
                currency: currency,
                status: JoltStatus::SUCCESSFUL,
                expiration_stamp: 0,
                block_timestamp: get_block_timestamp()
            };
            let total_jolts_recieved = self.total_jolts.read(fee_address) + amount;

            // write to storage
            self.jolt.write(jolt_id, jolt_data);
            self.total_jolts.write(fee_address, total_jolts_recieved);

            // emit event
            self.emit(
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

        // TODO: convert jolt amount to usd equivalent
        fn _get_usd_equiv(ref self: ContractState, amount: u256, erc20_contract_address: ContractAddress) -> u256 {
            100
        }
    }
}

