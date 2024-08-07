// TODO: https://github.com/lens-protocol/core/blob/master/contracts/misc/token-uris/ProfileTokenURI.sol

pub mod ProfileTokenUri {
    use core::array::ArrayTrait;
    use alexandria_bytes::{Bytes, BytesTrait};
    use karst::base::utils::byte_array_extra::FeltTryIntoByteArray;
    use alexandria_encoding::base64::{Base64UrlEncoder};

    fn get_svg() -> Array<felt252> {
        let mut svg = ArrayTrait::<felt252>::new();
        svg.append('<svg width="200" height="200" x');
        svg.append('mlns="http://www.w3.org/2000/sv');
        svg.append('g"><circle cx="100" cy="100" r=');
        svg.append('"80" fill="red"/></svg>');
        svg
    }
    fn get_svg_base64_encode(ref svg: Array<felt252>) -> ByteArray {
        let mut res: ByteArray = Default::default();

        // converting felt252 array to byte array 
        while (!svg.is_empty()) {
            let each_felt: felt252 = svg.pop_front().unwrap();
            let word: ByteArray = each_felt.try_into().unwrap();
            res.append(@word);
        };

        // converting the byte array to array of u8
        let mut res_arr_u8 = ArrayTrait::<u8>::new();
        let mut i = 0;
        while i < res
            .len() {
                let mut res_data = res.at(i);
                res_arr_u8.append(res_data.unwrap());
                i += 1;
            };

        // encoding the  array of u8  to base64url
        let mut encoded_val = Base64UrlEncoder::encode(res_arr_u8);

        // converting array of u8 to byte array 
        let mut res_final: ByteArray = Default::default();
        let mut j = 0;
        while j < encoded_val
            .len() {
                let encoded_val_data = encoded_val.at(j);
                res_final.append_byte(*encoded_val_data);
                j += 1;
            };
        res_final
    }

    pub fn get_token_uri(token_id: u256, mint_timestamp: u64) -> ByteArray {
        let baseuri = 'data:image/svg+xml;base64,';
        let mut svg = get_svg();
        let mut tokenuri: ByteArray = Default::default();
        // append the svg encoded value after the base uri 
        tokenuri.append(@baseuri.try_into().unwrap());
        tokenuri.append(@get_svg_base64_encode(ref svg));
        tokenuri
    }
}
