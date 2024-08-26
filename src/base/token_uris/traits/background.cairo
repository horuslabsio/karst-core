// let make the face of the profile svg  

mod background {
    use core::traits::TryInto;
    use karst::base::token_uris::traits::color::karstColors;
    use karst::base::utils::byte_array_extra::FeltTryIntoByteArray;

    #[derive(Drop)]
    enum BackgroundVariants {
        BACKGROUND1, // 1
        BACKGROUND2, // 2
        BACKGROUND3, // 3
        BACKGROUND4, // 4
        BACKGROUND5, // 5
    }

    pub fn backgroundSvgStart() -> ByteArray {
        getBackgroundVariant(BackgroundVariants::BACKGROUND1)
    }

    pub fn getBackgroundVariant(backgroundVariant: BackgroundVariants) -> ByteArray {
        let mut decidedbackground: ByteArray = Default::default();
        match backgroundVariant {
            BackgroundVariants::BACKGROUND1 => {
                decidedbackground =
                    " style=\"clip-rule:evenodd;fill-rule:evenodd;image-rendering:optimizeQuality;shape-rendering:geometricPrecision;text-rendering:geometricPrecision\" xml:space=\"preserve\" xmlns=\"http://www.w3.org/2000/svg\"><g style=\"display:inline\"><path style=\"opacity:1;fill:#556378;fill-opacity:1;stroke:#020503;stroke-width:.377995;stroke-dasharray:none;stroke-opacity:1\" d=\"M-1.701 2.299h199.622v199.622H-1.701z\"/></g>"
            },
            BackgroundVariants::BACKGROUND2 => {
                decidedbackground =
                    " style=\"clip-rule:evenodd;fill-rule:evenodd;image-rendering:optimizeQuality;shape-rendering:geometricPrecision;text-rendering:geometricPrecision\" xml:space=\"preserve\" xmlns=\"http://www.w3.org/2000/svg\"><g style=\"display:inline\"><path style=\"opacity:1;fill:#556378;fill-opacity:1;stroke:#020503;stroke-width:.377995;stroke-dasharray:none;stroke-opacity:1\" d=\"M-1.701 2.299h199.622v199.622H-1.701z\"/></g>"
            },
            BackgroundVariants::BACKGROUND3 => {
                decidedbackground =
                    " style=\"clip-rule:evenodd;fill-rule:evenodd;image-rendering:optimizeQuality;shape-rendering:geometricPrecision;text-rendering:geometricPrecision\" xml:space=\"preserve\" xmlns=\"http://www.w3.org/2000/svg\"><g style=\"display:inline\"><path style=\"opacity:1;fill:#556378;fill-opacity:1;stroke:#020503;stroke-width:.377995;stroke-dasharray:none;stroke-opacity:1\" d=\"M-1.701 2.299h199.622v199.622H-1.701z\"/></g>"
            },
            BackgroundVariants::BACKGROUND4 => {
                decidedbackground =
                    " style=\"clip-rule:evenodd;fill-rule:evenodd;image-rendering:optimizeQuality;shape-rendering:geometricPrecision;text-rendering:geometricPrecision\" xml:space=\"preserve\" xmlns=\"http://www.w3.org/2000/svg\"><g style=\"display:inline\"><path style=\"opacity:1;fill:#556378;fill-opacity:1;stroke:#020503;stroke-width:.377995;stroke-dasharray:none;stroke-opacity:1\" d=\"M-1.701 2.299h199.622v199.622H-1.701z\"/></g>"
            },
            BackgroundVariants::BACKGROUND5 => {
                decidedbackground =
                    " style=\"clip-rule:evenodd;fill-rule:evenodd;image-rendering:optimizeQuality;shape-rendering:geometricPrecision;text-rendering:geometricPrecision\" xml:space=\"preserve\" xmlns=\"http://www.w3.org/2000/svg\"><g style=\"display:inline\"><path style=\"opacity:1;fill:#556378;fill-opacity:1;stroke:#020503;stroke-width:.377995;stroke-dasharray:none;stroke-opacity:1\" d=\"M-1.701 2.299h199.622v199.622H-1.701z\"/></g>"
            }
        }
        decidedbackground
    }
}
