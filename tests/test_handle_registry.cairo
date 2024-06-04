use core::option::OptionTrait;
use core::starknet::SyscallResultTrait;
use core::result::ResultTrait;
use core::traits::{TryInto, Into};
use starknet::{ContractAddress};
use snforge_std::{
    declare, ContractClassTrait, CheatTarget, start_prank, stop_prank, start_warp, stop_warp
};

use karst::interfaces::IHandleRegistry::{IHandleRegistryDispatcher, IHandleRegistryDispatcherTrait};
use karst::namespaces::handle_registry::HandleRegistry;

fn __setup__() { // should contain any actions or logic to be carried out before a test is run
}
// *************************************************************************
//                              TEST
// *************************************************************************


