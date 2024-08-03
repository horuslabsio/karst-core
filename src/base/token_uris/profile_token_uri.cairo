// TODO: https://github.com/lens-protocol/core/blob/master/contracts/misc/token-uris/ProfileTokenURI.sol

pub mod ProfileTokenUri {
    use core::traits::TryInto;
    use core::serde::Serde;
    use alexandria_bytes::{Bytes, BytesTrait};
    use karst::base::utils::byte_array_extra::FeltTryIntoByteArray;
    // use alexandria_encoding::base64::Base64FeltEncoder;
    use core::integer::BoundedInt;


    pub fn get_token_uri(token_id: u256, mint_timestamp: u64) -> ByteArray {
        let mut svg = ArrayTrait::<felt252>::new();
        let mut res: ByteArray = Default::default();
        svg.append('<svg width="200" height="200" x');
        svg.append('mlns="http://www.w3.org/2000/sv');
        svg.append('g"><circle cx="100" cy="100" r=');
        svg.append('"80" fill="red"/></svg>');
        while (!svg.is_empty()) {
            let word: ByteArray = svg.pop_front().unwrap().try_into().unwrap();
            res.append(@word);
        };
        println!("{:?} ", res);
        return res;
    }
}
