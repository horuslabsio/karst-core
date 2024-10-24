use coloniz::base::constants::types::{JoltParams};

#[starknet::interface]
pub trait IJoltUpgrade<TState> {
    // *************************************************************************
    //                              EXTERNALS
    // *************************************************************************
    fn jolt(ref self: TState, jolt_params: JoltParams) -> u256;
    // *************************************************************************
    //                              GETTERS
    // *************************************************************************
    fn version(self: @TState) -> u256;
}
