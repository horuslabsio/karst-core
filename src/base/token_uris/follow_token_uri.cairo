// TODO: https://github.com/lens-protocol/core/blob/master/contracts/misc/token-uris/FollowTokenURI.sol#L14

pub mod FollowTokenUri {
    use starknet::ContractAddress;
    use alexandria_bytes::{Bytes, BytesTrait};
    use karst::base::utils::byte_array_extra::FeltTryIntoByteArray;

    pub fn get_token_uri(
        follow_token_id: u256, followed_profile_address: ContractAddress, follow_timestamp: u64
    ) -> ByteArray {
        "TODO"
    }
}
