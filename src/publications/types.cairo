use starknet::ContractAddress;
pub struct PostParams{
    post: felt252,
    publication_id: u256,
    transaction_executor: ContractAddress,
    block_timestamp: u256

}