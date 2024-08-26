mod ProfileSvg {
    use karst::base::token_uris::traits::color::karstColors;
    use karst::base::token_uris::traits::head::head::faceSvgStart;
    use karst::base::token_uris::traits::glass::glass::glassSvgStart;

    pub fn gen_profile_svg() -> ByteArray {
        let mut profilesvg: ByteArray = "<svg width=\"200\" height=\"200\"";
        profilesvg.append(@faceSvgStart());
        profilesvg.append(@glassSvgStart());
        profilesvg.append(@"</svg>");
        profilesvg
    }
}
