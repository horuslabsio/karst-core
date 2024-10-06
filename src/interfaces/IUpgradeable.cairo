// *************************************************************************
//                              UPGRADEABLE INTERFACE
// *************************************************************************
use starknet::ClassHash;

#[starknet::interface]
pub trait IUpgradeable<TContractState> {
    fn upgrade(ref self: TContractState, new_class_hash: ClassHash);
}
