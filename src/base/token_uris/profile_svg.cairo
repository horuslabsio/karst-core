mod ProfileSvg {
    use karst::base::token_uris::traits::color::karstColors;
    use karst::base::token_uris::traits::head::head::faceSvgStart;
    use karst::base::token_uris::traits::glass::glass::glassSvgStart;
    use karst::base::token_uris::traits::beard::beard::beardSvgStart;
    use karst::base::token_uris::traits::cloth::cloth::clothSvgStart;
    use karst::base::token_uris::traits::background::background::backgroundSvgStart;

    pub fn gen_profile_svg() -> ByteArray {
        let mut profilesvg: ByteArray = "<svg width=\"200\" height=\"200\"";
        profilesvg.append(@backgroundSvgStart());
        profilesvg.append(@faceSvgStart());
        profilesvg.append(@glassSvgStart());
        profilesvg.append(@beardSvgStart());
        profilesvg.append(@clothSvgStart());
        profilesvg.append(@"</svg>");
        profilesvg
    }
}
