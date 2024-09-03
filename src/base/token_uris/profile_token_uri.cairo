// TODO: https://github.com/lens-protocol/core/blob/master/contracts/misc/token-uris/ProfileTokenURI.sol

pub mod ProfileTokenUri {
    use core::array::ArrayTrait;
    use alexandria_bytes::{Bytes, BytesTrait};
    use karst::base::utils::byte_array_extra::FeltTryIntoByteArray;
    use karst::base::utils::base64_extended:: { get_base64_encode , convert_into_byteArray }; 
    use karst::base::token_uris::traits::profile::ProfileSvg::gen_profile_svg ; 
    // get svg according to the token id and mint timestamp
    fn get_svg(token_id: u256, mint_timestamp: u64) -> Array<felt252> {
        let mut svg = ArrayTrait::<felt252>::new();
        svg.append('<svg width="200" height="200" x');
        svg.append('mlns="http://www.w3.org/2000/sv');
        svg.append('g"><circle cx="100" cy="100" r=');
        svg.append('"80" fill="red"/></svg>');
        svg
    }

    fn get_attributes(token_id: u256, mint_timestamp: u64) -> Array<felt252> {
        let token_id_felt: felt252 = token_id.try_into().unwrap();
        let timestamp_felt: felt252 = mint_timestamp.try_into().unwrap();
        let token_id_byte: ByteArray = token_id_felt.try_into().unwrap();
        let token_id_byte_len: felt252 = token_id_byte.len().try_into().unwrap();
        let mut attributes = ArrayTrait::<felt252>::new();
        let sample_traits = 'pavitra';
        attributes.append('","attributes":[{"display');
        attributes.append('_type":"number","trait_');
        attributes.append('type":"ID","value":"');
        attributes.append(token_id_felt);
        attributes.append('"},{"trait_type":"HEX ');
        attributes.append('ID","value":"');
        attributes.append(token_id_felt); // TODO to hex string 
        attributes.append('"},{"trait_type":"DIGITS"');
        attributes.append(',"value":"');
        attributes.append(token_id_byte_len);
        attributes.append('"},{"display_type":"date","trai');
        attributes.append('t_type":"MINTED AT","value":"');
        attributes.append(timestamp_felt);
        attributes.append('"},');
        attributes.append(sample_traits);
        attributes.append(']}');
        attributes
    }

    fn get_json(token_id: u256, mint_timestamp: u64) -> Array<felt252> {
        let token_id_felt: felt252 = token_id.try_into().unwrap();
        let timestamp_felt: felt252 = mint_timestamp.try_into().unwrap();
        let mut json = ArrayTrait::<felt252>::new();
        json.append('{"name":"Profile #');
        json.append(token_id_felt);
        json.append('","description":"Profile #');
        json.append(timestamp_felt);
        json.append('","image":"data:image/svg');
        json.append('+xml;base64,');
        json
    }


    pub fn get_token_uri(token_id: u256, mint_timestamp: u64) -> ByteArray {
        let baseuri = 'data:image/svg+xml;base64,';
        let mut svg = get_svg(token_id, mint_timestamp);
        let mut svg_byte_array: ByteArray = convert_into_byteArray(ref svg);
        let svg_encoded: ByteArray = get_base64_encode(svg_byte_array);
        // getting json byte array 
        // json - json + svg_base64_encoded 
        let mut json = get_json(token_id, mint_timestamp);
        let mut json_byte_array: ByteArray = convert_into_byteArray(ref json);
        json_byte_array.append(@svg_encoded);
        // getting attributes  
        let mut attribute = get_attributes(token_id, mint_timestamp);
        let mut attribute_byte_array: ByteArray = convert_into_byteArray(ref attribute);
        // tokenuri_to_encode = json + attribute 
        let mut tokenuri_to_encode: ByteArray = Default::default();
        // concat json , 
        tokenuri_to_encode.append(@json_byte_array);
        // concat attribute 
        tokenuri_to_encode.append(@attribute_byte_array);
        // ecoding the encode 
        let encoded_token_uri = get_base64_encode(tokenuri_to_encode);
        // baseuri + base64_encoded(json,attribute) 
        let mut token_uri: ByteArray = baseuri.try_into().unwrap();
        // concat the base uri and the encoded token uri
        token_uri.append(@encoded_token_uri);
        token_uri
    }
}
