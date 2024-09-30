// TODO: https://github.com/lens-protocol/core/blob/master/contracts/misc/token-uris/HandleTokenURI.sol

pub mod HandleTokenUri {
    use core::array::ArrayTrait;
    use karst::base::utils::byte_array_extra::FeltTryIntoByteArray;
    use karst::base::utils::base64_extended::{convert_into_byteArray, get_base64_encode};
    use karst::base::token_uris::traits::handle::handle::get_svg_handle;

    pub fn get_token_uri(token_id: u256, local_name: felt252, namespace: felt252) -> ByteArray {
        let baseuri = 'data:image/svg+xml;base64,';
        /// TODO what are feaature include in the svg 
        let mut svg_byte_array: ByteArray = get_svg_handle(token_id, local_name, namespace);
        let mut svg_encoded: ByteArray = get_base64_encode(svg_byte_array);
        let mut attribute_byte_array: ByteArray = get_attributes(
            token_id, ref svg_encoded, local_name, namespace
        );
        let mut token_uri: ByteArray = baseuri.try_into().unwrap();
        token_uri.append(@attribute_byte_array);
        token_uri
    }

    fn get_attributes(
        token_id: u256,
        ref svg_encoded_byteArray: ByteArray,
        local_name: felt252,
        namespace: felt252
    ) -> ByteArray {
        let mut attributespre = ArrayTrait::<felt252>::new();
        let mut attributespost = ArrayTrait::<felt252>::new();
        attributespre.append('{"name":"@');
        attributespre.append(local_name);
        attributespre.append('","description":"Lens ');
        attributespre.append('Protocol - Handle @');
        attributespre.append(local_name);
        attributespre.append('","image":"data:image');
        attributespre.append('/svg+xml;base64,');
        attributespost.append('","attributes":[{"display');
        attributespost.append('_type":"number","trait_type');
        attributespost.append('":"ID","value":"');
        attributespost.append(token_id.try_into().unwrap());
        attributespost.append('"},{"trait_type":"NAMES');
        attributespost.append('PACE","value":"');
        attributespost.append(namespace);
        attributespost.append('"},{"trait_type":"');
        attributespost.append('LENGTH","value":"');
        attributespost.append('token_id_byte_len');
        attributespost.append('"}]}');
        let mut attributespre_bytearray = convert_into_byteArray(ref attributespre);
        let mut attributespost_bytearray = convert_into_byteArray(ref attributespost);
        attributespre_bytearray.append(@svg_encoded_byteArray);
        attributespre_bytearray.append(@attributespost_bytearray);
        get_base64_encode(attributespre_bytearray)
    }
}

