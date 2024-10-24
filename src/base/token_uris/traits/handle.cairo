pub mod handle {
    use core::array::ArrayTrait;
    use coloniz::base::utils::base64_extended::convert_into_byteArray;
    use coloniz::base::token_uris::traits::color::colonizColors;

    pub fn get_svg_handle(token_id: u256, local_name: felt252, namespace: felt252) -> ByteArray {
        let mut svg = ArrayTrait::<felt252>::new();
        let color_code = get_random_color(local_name);
        /// TODO chnage the circle svg to desired svg
        svg.append('<svg width="100" height="100"');
        svg.append('xmlns="http://www.w3.org/2000/');
        svg.append('svg"> <circle cx="50" cy="50"');
        svg.append(' r="40" fill="');
        svg.append(color_code);
        svg.append('" /> </svg>');
        convert_into_byteArray(ref svg)
    }

    fn get_random_color(local_name: felt252) -> felt252 {
        // TODO select the random color
        colonizColors::basePink
    }
}
