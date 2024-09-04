// TODO: https://github.com/lens-protocol/core/blob/master/contracts/misc/token-uris/FollowTokenURI.sol#L14

pub mod FollowTokenUri {
    use starknet::ContractAddress;
    use alexandria_bytes::{Bytes, BytesTrait};
    use karst::base::utils::byte_array_extra::FeltTryIntoByteArray;
    use karst::base::utils::base64_extended::{convert_into_byteArray, get_base64_encode};
    use karst::base::token_uris::traits::follow::follow::get_svg_follow;

    pub fn get_token_uri(
        follow_token_id: u256, followed_profile_address: ContractAddress, follow_timestamp: u64
    ) -> ByteArray {
        let baseuri = 'data:image/svg+xml;base64,';
        /// TODO what are feaature include in the svg 
        let mut svg_byte_array: ByteArray = get_svg_follow(follow_token_id);
        let mut svg_encoded: ByteArray = get_base64_encode(svg_byte_array);
        let mut attribute_byte_array: ByteArray = get_attributes(
            follow_token_id, ref svg_encoded, followed_profile_address, follow_timestamp
        );
        let mut token_uri: ByteArray = baseuri.try_into().unwrap();
        token_uri.append(@attribute_byte_array);
        token_uri
    }

    fn get_attributes(
        token_id: u256,
        ref svg_encoded_byteArray: ByteArray,
        followed_profile_address: ContractAddress,
        follow_timestamp: u64
    ) -> ByteArray {
        let token_id_felt: felt252 = token_id.try_into().unwrap();
        let token_id_byte: ByteArray = token_id_felt.try_into().unwrap();
        let token_id_byte_len: felt252 = token_id_byte.len().try_into().unwrap();
        let follow_profile_address_felt: felt252 = followed_profile_address.try_into().unwrap();
        let follow_prfile_address_byte: ByteArray = follow_profile_address_felt.try_into().unwrap();
        let follow_prfile_address_byte_len: felt252 = follow_prfile_address_byte
            .len()
            .try_into()
            .unwrap();
        let mut attributespre = ArrayTrait::<felt252>::new();
        let mut attributespost = ArrayTrait::<felt252>::new();
        attributespre.append('{"name":"Follower #');
        attributespre.append(token_id_felt);
        attributespre.append('","description":"Lens ');
        attributespre.append('Protocol - Follower @');
        attributespre.append(token_id_felt);
        attributespre.append(' of Profile #');
        attributespre.append(follow_profile_address_felt);
        attributespre.append('","image":"data:image');
        attributespre.append('/svg+xml;base64,');
        //post base64 follow svg 
        attributespost.append('","attributes":[{"display');
        attributespost.append('_type":"number","trait_type');
        attributespost.append('":"ID","value":"');
        attributespost.append(token_id_felt);
        attributespost.append('"},{"trait_type":"DIGITS"');
        attributespost.append(',"value":"');
        attributespost.append(follow_prfile_address_byte_len);
        attributespost.append('"},{"display_type":"date');
        attributespost.append('","trait_type":"MINTED AT"');
        attributespost.append(',"value":"');
        attributespost.append(follow_timestamp.try_into().unwrap());
        attributespost.append('"}]}');
        let mut attributespre_bytearray = convert_into_byteArray(ref attributespre);
        let mut attributespost_bytearray = convert_into_byteArray(ref attributespost);
        attributespre_bytearray.append(@svg_encoded_byteArray);
        attributespre_bytearray.append(@attributespost_bytearray);
        get_base64_encode(attributespre_bytearray)
    }
}
