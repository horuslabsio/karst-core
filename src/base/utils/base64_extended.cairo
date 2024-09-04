use core::serde::Serde;
use core::array::ArrayTrait;
use karst::base::utils::byte_array_extra::FeltTryIntoByteArray;
use alexandria_encoding::base64::{Base64UrlEncoder};

pub fn get_base64_encode(res: ByteArray) -> ByteArray {
    let mut res_arr_u8 = ArrayTrait::<u8>::new();
    let mut i = 0;
    while i < res
        .len() {
            let mut res_data = res.at(i);
            res_arr_u8.append(res_data.unwrap());
            i += 1;
        };
    let mut encoded_val = Base64UrlEncoder::encode(res_arr_u8);
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

pub fn convert_into_byteArray(ref svg: Array<felt252>) -> ByteArray {
    let mut res: ByteArray = Default::default();
    // converting felt252 array to byte array 
    while (!svg.is_empty()) {
        let each_felt: felt252 = svg.pop_front().unwrap();
        let word: ByteArray = each_felt.try_into().unwrap();
        res.append(@word);
    };
    res
}
