use starknet::ContractAddress;

#[starknet::interface]
trait IKarstProfile<TState> {
    fn create_karstnft(
        ref self: TState,
        karstnft_contract_address: ContractAddress,
        tokenbound_contract_address: ContractAddress,
        implementation_hash: felt252,
        salt: felt252
    );
    fn get_user_profile_id(self:@TState, user:ContractAddress) -> u256;
    fn get_total_id(self:@TState) -> u256;
}


#[starknet::contract]
mod KarstProfile {
    use starknet::{ContractAddress, get_caller_address};
    use karst::interface::Ikarst::{IKarstDispatcher, IKarstDispatcherTrait};
    use karst::interface::Iregistry::{IRegistryDispatcher, IRegistryDispatcherTrait};
    use karst::interface::IERC721::{IERC721Dispatcher, IERC721DispatcherTrait};
    use starknet::ContractAddress;

    #[storage]
    struct Storage {
        profile_id: LegacyMap<ContractAddress, u256>,
        total_profile_id: u256
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        CreateKarstProfile: CreateKarstProfile
    }

    #[derive(Drop, starknet::Event)]
    struct CreateKarstProfile {
        #[key]
        user: ContractAddress,
        #[key]
        karstnft_contract_address: ContractAddress,
        #[key]
        tokenbound_contract_address: ContractAddress,
        #[key]
        token_id: u256,
    }

    #[abi(embed_v0)]
    impl KarstProfileImpl of super::IKarstProfile<ContractState> {
        fn create_karstnft(
            ref self: ContractState,
            karstnft_contract_address: ContractAddress,
            tokenbound_contract_address: ContractAddress,
            implementation_hash: felt252,
            salt: felt252
        ) {
            let caller = get_caller_address();
            // check if user has a karst nft
            let own_karstnft = IERC721Dispatcher { contract_address: karstnft_contract_address }
                .balance_of(caller);
            let token_id = IKarstDispatcher { contract_address: karstnft_contract_address }
                .token_id();
            let current_total_id = self.total_profile_id.read();
            if own_karstnft == 0 {
                IKarstDispatcher { contract_address: karstnft_contract_address }.mint_karstnft();
                IRegistryDispatcher { contract_address: tokenbound_contract_address }
                    .create_account(implementation_hash, karstnft_contract_address, token_id, salt);
                // assign profile id 
                self.profile_id.write(caller, current_total_id + 1);
            } else {
                IRegistryDispatcher { contract_address: tokenbound_contract_address }
                    .create_account(implementation_hash, karstnft_contract_address, token_id, salt);
                // execute create_account on token bound registry via dispatcher
                self.profile_id.write(caller, current_total_id + 1);
            }
            // emit event
            self
                .emit(
                    CreateKarstProfile {
                        user: caller,
                        karstnft_contract_address,
                        tokenbound_contract_address,
                        token_id
                    }
                )
        }

        fn get_user_profile_id(self:@ContractState, user:ContractAddress) -> u256{
            self.profile_id.read(user)
        }

        fn get_total_id(self:@ContractState) -> u256{
            self.total_profile_id.read()
        }

    }
}
