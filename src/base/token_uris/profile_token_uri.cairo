// TODO: https://github.com/lens-protocol/core/blob/master/contracts/misc/token-uris/ProfileTokenURI.sol

pub mod ProfileTokenUri {

    use core::array::ArrayTrait;
    use core::IndexView  ; 
    use alexandria_bytes::{Bytes, BytesTrait};
    use karst::base::utils::byte_array_extra::FeltTryIntoByteArray;
    use alexandria_encoding::base64::{Base64UrlEncoder };  
    use alexandria_encoding::sol_abi::encode::{SolAbiEncodeTrait};
    use alexandria_encoding::sol_abi::sol_bytes::{SolBytesTrait};
    pub fn get_token_uri(token_id: u256, mint_timestamp: u64) -> ByteArray {
        // this must be done into the byte array format 
        let mut tokenuri : ByteArray = Default::default();
        let baseuri = 'data:image/svg+xml;base64,';
        tokenuri.append(@baseuri.try_into().unwrap());
        let mut svg = ArrayTrait::<felt252>::new();
        let mut res: ByteArray = Default::default();
        svg.append('<svg width="200" height="200" x');
        svg.append('mlns="http://www.w3.org/2000/sv');
        svg.append('g"><circle cx="100" cy="100" r=');
        svg.append('"80" fill="red"/></svg>');
        while (!svg.is_empty()) {
            let each_felt : felt252 = svg.pop_front().unwrap() ;  
            // println!("{:?}", svg.index(0)); 
            let word: ByteArray = each_felt.try_into().unwrap();
            res.append(@word);
        };
        println!("{:?} ", res);
        println!("{:?} ", res.len());
        let res_len = res.len() ; 
        let mut res_encode = ArrayTrait::<u8>::new(); 
        let mut i = 0 ; 
        while i < res_len {
            let mut res_data = res.at(i);
            res_encode.append(res_data.unwrap());
            i += 1 ; 
        };
        println!("{:?} ", res_encode);
        let mut encoded_val = Base64UrlEncoder::encode(res_encode);
        ////////
        let encoded_val_len = encoded_val.len() ;
        let mut res_final : ByteArray = Default::default();

        let mut j = 0 ; 
        while j < encoded_val_len {
            let  encoded_val_data = encoded_val.at(j);
            res_final.append_byte(*encoded_val_data);
            j += 1 ; 
        };
        println!("{:?} ", res_final);
        tokenuri.append(@res_final) ; 
        println!("{:?} ", tokenuri);
        tokenuri
    }
}
