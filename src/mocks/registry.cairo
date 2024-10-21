////////////////////////////////
// Registry Component
////////////////////////////////
#[starknet::contract]
pub mod Registry {
    use core::result::ResultTrait;
    use core::hash::HashStateTrait;
    use core::pedersen::PedersenTrait;
    use starknet::{
        ContractAddress, get_caller_address, get_contract_address, syscalls::call_contract_syscall,
        class_hash::ClassHash, syscalls::deploy_syscall, SyscallResultTrait
    };
    use token_bound_accounts::interfaces::IRegistry::IRegistry;

    #[storage]
    pub struct Storage {}

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        AccountCreated: AccountCreated
    }

    /// @notice Emitted when a new tokenbound account is deployed/created
    /// @param account_address the deployed contract address of the tokenbound acccount
    /// @param token_contract the contract address of the NFT
    /// @param token_id the ID of the NFT
    #[derive(Drop, starknet::Event)]
    struct AccountCreated {
        account_address: ContractAddress,
        token_contract: ContractAddress,
        token_id: u256,
    }

    mod Errors {
        const CALLER_IS_NOT_OWNER: felt252 = 'Registry: caller is not onwer';
    }

    #[abi(embed_v0)]
    impl IRegistryImpl of IRegistry<ContractState> {
        /// @notice deploys a new tokenbound account for an NFT
        /// @param implementation_hash the class hash of the reference account
        /// @param token_contract the contract address of the NFT
        /// @param token_id the ID of the NFT
        /// @param salt random salt for deployment
        fn create_account(
            ref self: ContractState,
            implementation_hash: felt252,
            token_contract: ContractAddress,
            token_id: u256,
            salt: felt252,
            chain_id: felt252
        ) -> ContractAddress {
            let owner = self._get_owner(token_contract, token_id);
            assert(owner == get_caller_address(), 'CALLER_IS_NOT_OWNER');

            let mut constructor_calldata: Array<felt252> = array![
                token_contract.into(),
                token_id.low.into(),
                token_id.high.into(),
                get_contract_address().into(),
                implementation_hash,
                salt
            ];

            let class_hash: ClassHash = implementation_hash.try_into().unwrap();
            let result = deploy_syscall(class_hash, salt, constructor_calldata.span(), true);
            let (account_address, _) = result.unwrap_syscall();

            self.emit(AccountCreated { account_address, token_contract, token_id, });
            account_address
        }

        /// @notice calculates the account address for an existing tokenbound account
        /// @param implementation_hash the class hash of the reference account
        /// @param token_contract the contract address of the NFT
        /// @param token_id the ID of the NFT
        /// @param salt random salt for deployment
        fn get_account(
            self: @ContractState,
            implementation_hash: felt252,
            token_contract: ContractAddress,
            token_id: u256,
            salt: felt252,
            chain_id: felt252
        ) -> ContractAddress {
            let constructor_calldata_hash = PedersenTrait::new(0)
                .update(token_contract.into())
                .update(token_id.low.into())
                .update(token_id.high.into())
                .update(get_contract_address().into())
                .update(implementation_hash)
                .update(salt)
                .update(6)
                .finalize();

            let prefix: felt252 = 'STARKNET_CONTRACT_ADDRESS';
            let account_address = PedersenTrait::new(0)
                .update(prefix)
                .update(0)
                .update(salt)
                .update(implementation_hash)
                .update(constructor_calldata_hash)
                .update(5)
                .finalize();

            account_address.try_into().unwrap()
        }
    }

    #[generate_trait]
    impl internalImpl of InternalTrait {
        /// @notice internal function for getting NFT owner
        /// @param token_contract contract address of NFT
        // @param token_id token ID of NFT
        // NB: This function aims for compatibility with all contracts (snake or camel case) but do
        // not work as expected on mainnet as low level calls do not return err at the moment.
        // Should work for contracts which implements CamelCase but not snake_case until starknet
        // v0.15.
        fn _get_owner(
            self: @ContractState, token_contract: ContractAddress, token_id: u256
        ) -> ContractAddress {
            let mut calldata: Array<felt252> = ArrayTrait::new();
            Serde::serialize(@token_id, ref calldata);
            let mut res = call_contract_syscall(
                token_contract, selector!("ownerOf"), calldata.span()
            );
            if (res.is_err()) {
                res = call_contract_syscall(token_contract, selector!("owner_of"), calldata.span());
            }
            let mut address = res.unwrap();
            Serde::<ContractAddress>::deserialize(ref address).unwrap()
        }
    }
}
