#[starknet::contract]
pub mod JoltUpgrade {
    // *************************************************************************
    //                            IMPORTS
    // *************************************************************************
    use core::hash::HashStateTrait;
    use core::pedersen::PedersenTrait;
    use starknet::get_tx_info;
    use karst::base::{constants::types::{JoltParams}};
    use karst::mocks::interfaces::IJoltUpgrade::IJoltUpgrade;

    // *************************************************************************
    //                            STORAGE
    // *************************************************************************
    #[storage]
    struct Storage {}

    // *************************************************************************
    //                            EVENTS
    // *************************************************************************
    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {}


    // *************************************************************************
    //                            EXTERNALS
    // *************************************************************************
    #[abi(embed_v0)]
    impl JoltImpl of IJoltUpgrade<ContractState> {
        fn jolt(ref self: ContractState, jolt_params: JoltParams) -> u256 {
            let tx_info = get_tx_info().unbox();

            // generate jolt_id
            let jolt_hash = PedersenTrait::new(0)
                .update(jolt_params.recipient.into())
                .update(jolt_params.amount.low.into())
                .update(jolt_params.amount.high.into())
                .update(tx_info.nonce)
                .update(4)
                .finalize();

            let jolt_id: u256 = jolt_hash.try_into().unwrap();

            return jolt_id;
        }

        fn version(self: @ContractState) -> u256 {
            2
        }
    }
}
