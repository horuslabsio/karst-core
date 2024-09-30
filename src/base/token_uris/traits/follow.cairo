pub mod follow {
    use core::array::ArrayTrait;
    use karst::base::utils::base64_extended::convert_into_byteArray;
    use karst::base::token_uris::traits::color::karstColors;

    pub fn get_svg_follow(follow_token_id: u256) -> ByteArray {
        let mut svg = ArrayTrait::<felt252>::new();
        let color_code = get_random_color(follow_token_id);
        /// TODO chnage the circle svg to desired svg 
        svg.append('<svg width="100" height="100"');
        svg.append('xmlns="http://www.w3.org/2000/');
        svg.append('svg"> <circle cx="50" cy="50"');
        svg.append(' r="40" fill="');
        svg.append(color_code);
        svg.append('" /> </svg>');
        convert_into_byteArray(ref svg)
    }

    fn get_random_color(local_name: u256) -> felt252 {
        // TODO select the random color  
        karstColors::basePink
    }
}
