// let make the face of the profile svg  

mod glass {
    use core::traits::TryInto;
    use karst::base::token_uris::traits::color::karstColors;
    use karst::base::utils::byte_array_extra::FeltTryIntoByteArray;

    #[derive(Drop)]
    enum GlassVariants {
        GLASS1, // 1
        GLASS2, // 2
        GLASS3, // 3
        GLASS4, // 4
        GLASS5, // 5
    }

    pub fn glassSvgStart() -> ByteArray {
        getGlassvariant(GlassVariants::GLASS1)
    }


    pub fn getGlassvariant(glassVariant: GlassVariants) -> ByteArray {
        let mut decidedGlass: ByteArray = Default::default();
        match glassVariant {
            GlassVariants::GLASS1 => {
                decidedGlass =
                    " style=\"clip-rule:evenodd;fill-rule:evenodd;image-rendering:optimizeQuality;shape-rendering:geometricPrecision;text-rendering:geometricPrecision\" xml:space=\"preserve\" xmlns=\"http://www.w3.org/2000/svg\"><defs><filter style=\"color-interpolation-filters:sRGB\" id=\"a\" x=\"-.015\" y=\"-.054\" width=\"1.03\" height=\"1.108\"><feGaussianBlur stdDeviation=\"5\" result=\"result3\"/><feColorMatrix values=\"1 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 0 50 0\" result=\"result7\"/><feComposite operator=\"in\" in2=\"SourceGraphic\" result=\"result9\"/><feComposite in2=\"result7\" operator=\"arithmetic\" in=\"result9\" k1=\".5\" k3=\".5\" result=\"result1\"/><feBlend in2=\"result1\" result=\"result5\" mode=\"screen\" in=\"SourceGraphic\"/><feBlend in2=\"result5\" mode=\"darken\" in=\"result5\" result=\"result6\"/><feComposite in2=\"SourceGraphic\" operator=\"in\" result=\"result8\"/></filter></defs><g style=\"display:inline;filter:url(#a)\" transform=\"translate(-4.93 1.565)scale(.1014)\"><g style=\"clip-rule:evenodd;opacity:1;fill-rule:evenodd;image-rendering:optimizeQuality;shape-rendering:geometricPrecision;text-rendering:geometricPrecision\"><g style=\"display:inline;fill:#000;fill-opacity:1\"><path style=\"opacity:.896;fill:#000;fill-opacity:1\" fill=\"#040303\" d=\"M810.5 578.5q92.502-.25 185 .5 1.493 2.751 4.5 3.5c28.61-3.413 56.45-.247 83.5 9.5 24.62 11.38 38.95 30.547 43 57.5 7.94-.406 15.77.261 23.5 2a9447 9447 0 0 1 240-23l1.5 1.5 14 .5c7.23-.516 14.4-.516 21.5 0q4.245-.554 7.5-2 3.465-.203 6 2c-5.89 1.264-11.56 3.764-17 7.5a43848 43848 0 0 0-294 28.5c2.78 23.825.62 47.158-6.5 70-22.28 45.728-57.11 59.562-104.5 41.5q-37.52-23.266-63-59.5-5.498-1.011-11 1a45.6 45.6 0 0 1-7-3q-13.132-21.267-21.5-45-1-2.5 0-5a95 95 0 0 1 8.5-8 498 498 0 0 0-7-35q-14.958-3.694-30 0a949 949 0 0 1-2.5 41q8.716-10.048 19.5-2.5 2.785 1.773 3 5a334 334 0 0 1-16.5 47.5q-12.897 10.128-22.5-2.5 1.836-3.585 1.5-7.5-17.92 36.092-46.5 64.5-13.826 12.416-32 17-27.83 3.798-48-15.5-24.287-24.067-30.5-58a297 297 0 0 1-4.5-46q-10.374 1.868-10-8.5-.327-10.045 10-8.5 2.996-63.747 67-67.5a178.7 178.7 0 0 1 32.5.5q.72-2.45 2.5-4m35 12a2209 2209 0 0 1 115-.5q-21.184 7.083-35 24.5-10.902-3.717-22.5-3l-14.5.5q-5.308.28-9.5 3.5-12.246-18.492-33.5-25\" transform=\"translate(42.925 -3.817)\"/></g><path style=\"opacity:1\" fill=\"#4f5161\" d=\"M800.5 589.5a419 419 0 0 0-34 1q9.904-2.241 20.5-2 7.02.001 13.5 1\" transform=\"translate(42.925 -3.817)\"/><path style=\"opacity:1\" fill=\"#505161\" d=\"M1034.5 589.5q-21.03-.227-42 1c8.11-1.511 16.45-2.178 25-2 5.84.001 11.51.334 17 1\" transform=\"translate(42.925 -3.817)\"/><g style=\"display:inline;opacity:.1\"><path style=\"opacity:1\" fill=\"#74778e\" d=\"M800.5 589.5q26.329.863 50 12v3q25.36 11.676 25 40-80.841-2.078-160 14v13q-4.823-29.679 8.5-57 15.947-21.158 42.5-24a419 419 0 0 1 34-1\" transform=\"translate(42.925 -3.817)\"/></g><g style=\"display:inline;opacity:.1\"><path style=\"opacity:1\" fill=\"#74778e\" d=\"M1034.5 589.5c18.92.317 36.59 4.984 53 14-.11.617-.44 1.117-1 1.5q12.6 8.262 21 20.5c4.74 9.971 8.07 20.304 10 31v5c.69 5.305 1.03 10.638 1 16a1251 1251 0 0 0-184-30q-3.294.007-6 1-6.187-39.142 32-51.5a110.3 110.3 0 0 1 32-6.5 607 607 0 0 1 42-1\" transform=\"translate(42.925 -3.817)\"/></g><path style=\"opacity:1\" fill=\"#57586a\" d=\"M850.5 601.5q31.593 15.183 27 50a25 25 0 0 0-.5-7q-.575.834-1.5 1v-1q.36-28.324-25-40z\" transform=\"translate(42.925 -3.817)\"/><path style=\"opacity:1\" fill=\"#5b5d6f\" d=\"M1087.5 603.5c11.84 6.176 20.17 15.509 25 28 .07.438-.1.772-.5 1q-1.545-4.108-4.5-7-8.4-12.238-21-20.5c.56-.383.89-.883 1-1.5\" transform=\"translate(42.925 -3.817)\"/><path style=\"opacity:1\" fill=\"#484958\" d=\"M1107.5 625.5q2.955 2.892 4.5 7c.4-.228.57-.562.5-1 4.1 7.848 5.77 16.182 5 25-1.93-10.696-5.26-21.029-10-31\" transform=\"translate(42.925 -3.817)\"/><g style=\"display:inline;opacity:.104\"><path style=\"opacity:1\" fill=\"#b9b6c7\" d=\"M875.5 644.5v1a109 109 0 0 1-6 30 10 10 0 0 0 1 3q-.143 3.429-2 6-76.635-3.544-150 18-3.762-15.061-3-31v-13q79.159-16.078 160-14\" transform=\"translate(42.925 -3.817)\"/></g><g style=\"display:inline;opacity:.1\"><path style=\"opacity:1\" fill=\"#b9b7c7\" d=\"M1118.5 677.5v25c-.24 4.342-.57 8.676-1 13q-2.055 5.191-3 11-83.37-28.284-171-38-10.776-18.592-15-40 2.706-.993 6-1a1251 1251 0 0 1 184 30\" transform=\"translate(42.925 -3.817)\"/></g><path style=\"opacity:1\" fill=\"#9795a3\" d=\"M877.5 651.5q-1.428 14.18-7 27a10 10 0 0 1-1-3 109 109 0 0 0 6-30q.925-.166 1.5-1 .745 3.465.5 7\" transform=\"translate(42.925 -3.817)\"/><path style=\"opacity:1\" fill=\"#52525d\" d=\"M1117.5 661.5c.81.929 1.65 1.929 2.5 3q.57 9.266 1.5 18.5-2.1 9.741-3 19.5v-25c.03-5.362-.31-10.695-1-16\" transform=\"translate(42.925 -3.817)\"/><g style=\"display:inline;opacity:.1\"><path style=\"opacity:1\" fill=\"#74778e\" d=\"M868.5 684.5a279.4 279.4 0 0 1-27 50q-4.015 2.337-7.5 6a27.8 27.8 0 0 1-6 8 4.93 4.93 0 0 0-.5 3 2262 2262 0 0 1-21 17.5 87.5 87.5 0 0 0-11 6q.834.575 1 1.5-21.007 7.603-40-4.5-34.039-26.313-38-69.5 73.365-21.544 150-18\" transform=\"translate(42.925 -3.817)\"/></g><g style=\"display:inline;opacity:.1\"><path style=\"opacity:1\" fill=\"#74778e\" d=\"M943.5 688.5q87.63 9.716 171 38a114 114 0 0 1-5 14c-5.01 8.448-11.34 15.948-19 22.5.92.278 1.58.778 2 1.5q-37.545 28.12-78 3.5-45.342-31.086-71-79.5\" transform=\"translate(42.925 -3.817)\"/></g><path style=\"opacity:1\" fill=\"#4b4c58\" d=\"M1117.5 715.5c.63 9.426-1.71 18.092-7 26 0-.667-.33-1-1-1 1.97-4.561 3.64-9.227 5-14q.945-5.809 3-11\" transform=\"translate(42.925 -3.817)\"/><path style=\"opacity:1\" fill=\"#5a5c6e\" d=\"M1109.5 740.5c.67 0 1 .333 1 1q-6.72 13.228-18 23c-.42-.722-1.08-1.222-2-1.5 7.66-6.552 13.99-14.052 19-22.5\" transform=\"translate(42.925 -3.817)\"/><path style=\"opacity:1\" fill=\"#686a7f\" d=\"M841.5 734.5q-14.619 22.871-37 38.5a42.3 42.3 0 0 1-8 3.5q-.166-.925-1-1.5a87.5 87.5 0 0 1 11-6 2262 2262 0 0 0 21-17.5 4.93 4.93 0 0 1 .5-3 27.8 27.8 0 0 0 6-8q3.485-3.663 7.5-6\" transform=\"translate(42.925 -3.817)\"/><path style=\"opacity:.868\" fill=\"#020101\" d=\"M1496.5 768.5c1.43.381 2.26 1.381 2.5 3 .92 5.923 2.08 11.757 3.5 17.5-3.75 4.418-8.08 8.084-13 11q-4.575 1.232-9-.5a227.4 227.4 0 0 0 16-31\" transform=\"translate(42.925 -3.817)\"/></g></g>"
            },
            GlassVariants::GLASS2 => {
                decidedGlass =
                    " style=\"clip-rule:evenodd;fill-rule:evenodd;image-rendering:optimizeQuality;shape-rendering:geometricPrecision;text-rendering:geometricPrecision\" xml:space=\"preserve\" xmlns=\"http://www.w3.org/2000/svg\"><defs><filter style=\"color-interpolation-filters:sRGB\" id=\"a\" x=\"-.015\" y=\"-.054\" width=\"1.03\" height=\"1.108\"><feGaussianBlur stdDeviation=\"5\" result=\"result3\"/><feColorMatrix values=\"1 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 0 50 0\" result=\"result7\"/><feComposite operator=\"in\" in2=\"SourceGraphic\" result=\"result9\"/><feComposite in2=\"result7\" operator=\"arithmetic\" in=\"result9\" k1=\".5\" k3=\".5\" result=\"result1\"/><feBlend in2=\"result1\" result=\"result5\" mode=\"screen\" in=\"SourceGraphic\"/><feBlend in2=\"result5\" mode=\"darken\" in=\"result5\" result=\"result6\"/><feComposite in2=\"SourceGraphic\" operator=\"in\" result=\"result8\"/></filter></defs><g style=\"display:inline;filter:url(#a)\" transform=\"translate(-4.93 1.565)scale(.1014)\"><g style=\"clip-rule:evenodd;opacity:1;fill-rule:evenodd;image-rendering:optimizeQuality;shape-rendering:geometricPrecision;text-rendering:geometricPrecision\"><g style=\"display:inline;fill:#000;fill-opacity:1\"><path style=\"opacity:.896;fill:#000;fill-opacity:1\" fill=\"#040303\" d=\"M810.5 578.5q92.502-.25 185 .5 1.493 2.751 4.5 3.5c28.61-3.413 56.45-.247 83.5 9.5 24.62 11.38 38.95 30.547 43 57.5 7.94-.406 15.77.261 23.5 2a9447 9447 0 0 1 240-23l1.5 1.5 14 .5c7.23-.516 14.4-.516 21.5 0q4.245-.554 7.5-2 3.465-.203 6 2c-5.89 1.264-11.56 3.764-17 7.5a43848 43848 0 0 0-294 28.5c2.78 23.825.62 47.158-6.5 70-22.28 45.728-57.11 59.562-104.5 41.5q-37.52-23.266-63-59.5-5.498-1.011-11 1a45.6 45.6 0 0 1-7-3q-13.132-21.267-21.5-45-1-2.5 0-5a95 95 0 0 1 8.5-8 498 498 0 0 0-7-35q-14.958-3.694-30 0a949 949 0 0 1-2.5 41q8.716-10.048 19.5-2.5 2.785 1.773 3 5a334 334 0 0 1-16.5 47.5q-12.897 10.128-22.5-2.5 1.836-3.585 1.5-7.5-17.92 36.092-46.5 64.5-13.826 12.416-32 17-27.83 3.798-48-15.5-24.287-24.067-30.5-58a297 297 0 0 1-4.5-46q-10.374 1.868-10-8.5-.327-10.045 10-8.5 2.996-63.747 67-67.5a178.7 178.7 0 0 1 32.5.5q.72-2.45 2.5-4m35 12a2209 2209 0 0 1 115-.5q-21.184 7.083-35 24.5-10.902-3.717-22.5-3l-14.5.5q-5.308.28-9.5 3.5-12.246-18.492-33.5-25\" transform=\"translate(42.925 -3.817)\"/></g><path style=\"opacity:1\" fill=\"#4f5161\" d=\"M800.5 589.5a419 419 0 0 0-34 1q9.904-2.241 20.5-2 7.02.001 13.5 1\" transform=\"translate(42.925 -3.817)\"/><path style=\"opacity:1\" fill=\"#505161\" d=\"M1034.5 589.5q-21.03-.227-42 1c8.11-1.511 16.45-2.178 25-2 5.84.001 11.51.334 17 1\" transform=\"translate(42.925 -3.817)\"/><g style=\"display:inline;opacity:.1\"><path style=\"opacity:1\" fill=\"#74778e\" d=\"M800.5 589.5q26.329.863 50 12v3q25.36 11.676 25 40-80.841-2.078-160 14v13q-4.823-29.679 8.5-57 15.947-21.158 42.5-24a419 419 0 0 1 34-1\" transform=\"translate(42.925 -3.817)\"/></g><g style=\"display:inline;opacity:.1\"><path style=\"opacity:1\" fill=\"#74778e\" d=\"M1034.5 589.5c18.92.317 36.59 4.984 53 14-.11.617-.44 1.117-1 1.5q12.6 8.262 21 20.5c4.74 9.971 8.07 20.304 10 31v5c.69 5.305 1.03 10.638 1 16a1251 1251 0 0 0-184-30q-3.294.007-6 1-6.187-39.142 32-51.5a110.3 110.3 0 0 1 32-6.5 607 607 0 0 1 42-1\" transform=\"translate(42.925 -3.817)\"/></g><path style=\"opacity:1\" fill=\"#57586a\" d=\"M850.5 601.5q31.593 15.183 27 50a25 25 0 0 0-.5-7q-.575.834-1.5 1v-1q.36-28.324-25-40z\" transform=\"translate(42.925 -3.817)\"/><path style=\"opacity:1\" fill=\"#5b5d6f\" d=\"M1087.5 603.5c11.84 6.176 20.17 15.509 25 28 .07.438-.1.772-.5 1q-1.545-4.108-4.5-7-8.4-12.238-21-20.5c.56-.383.89-.883 1-1.5\" transform=\"translate(42.925 -3.817)\"/><path style=\"opacity:1\" fill=\"#484958\" d=\"M1107.5 625.5q2.955 2.892 4.5 7c.4-.228.57-.562.5-1 4.1 7.848 5.77 16.182 5 25-1.93-10.696-5.26-21.029-10-31\" transform=\"translate(42.925 -3.817)\"/><g style=\"display:inline;opacity:.104\"><path style=\"opacity:1\" fill=\"#b9b6c7\" d=\"M875.5 644.5v1a109 109 0 0 1-6 30 10 10 0 0 0 1 3q-.143 3.429-2 6-76.635-3.544-150 18-3.762-15.061-3-31v-13q79.159-16.078 160-14\" transform=\"translate(42.925 -3.817)\"/></g><g style=\"display:inline;opacity:.1\"><path style=\"opacity:1\" fill=\"#b9b7c7\" d=\"M1118.5 677.5v25c-.24 4.342-.57 8.676-1 13q-2.055 5.191-3 11-83.37-28.284-171-38-10.776-18.592-15-40 2.706-.993 6-1a1251 1251 0 0 1 184 30\" transform=\"translate(42.925 -3.817)\"/></g><path style=\"opacity:1\" fill=\"#9795a3\" d=\"M877.5 651.5q-1.428 14.18-7 27a10 10 0 0 1-1-3 109 109 0 0 0 6-30q.925-.166 1.5-1 .745 3.465.5 7\" transform=\"translate(42.925 -3.817)\"/><path style=\"opacity:1\" fill=\"#52525d\" d=\"M1117.5 661.5c.81.929 1.65 1.929 2.5 3q.57 9.266 1.5 18.5-2.1 9.741-3 19.5v-25c.03-5.362-.31-10.695-1-16\" transform=\"translate(42.925 -3.817)\"/><g style=\"display:inline;opacity:.1\"><path style=\"opacity:1\" fill=\"#74778e\" d=\"M868.5 684.5a279.4 279.4 0 0 1-27 50q-4.015 2.337-7.5 6a27.8 27.8 0 0 1-6 8 4.93 4.93 0 0 0-.5 3 2262 2262 0 0 1-21 17.5 87.5 87.5 0 0 0-11 6q.834.575 1 1.5-21.007 7.603-40-4.5-34.039-26.313-38-69.5 73.365-21.544 150-18\" transform=\"translate(42.925 -3.817)\"/></g><g style=\"display:inline;opacity:.1\"><path style=\"opacity:1\" fill=\"#74778e\" d=\"M943.5 688.5q87.63 9.716 171 38a114 114 0 0 1-5 14c-5.01 8.448-11.34 15.948-19 22.5.92.278 1.58.778 2 1.5q-37.545 28.12-78 3.5-45.342-31.086-71-79.5\" transform=\"translate(42.925 -3.817)\"/></g><path style=\"opacity:1\" fill=\"#4b4c58\" d=\"M1117.5 715.5c.63 9.426-1.71 18.092-7 26 0-.667-.33-1-1-1 1.97-4.561 3.64-9.227 5-14q.945-5.809 3-11\" transform=\"translate(42.925 -3.817)\"/><path style=\"opacity:1\" fill=\"#5a5c6e\" d=\"M1109.5 740.5c.67 0 1 .333 1 1q-6.72 13.228-18 23c-.42-.722-1.08-1.222-2-1.5 7.66-6.552 13.99-14.052 19-22.5\" transform=\"translate(42.925 -3.817)\"/><path style=\"opacity:1\" fill=\"#686a7f\" d=\"M841.5 734.5q-14.619 22.871-37 38.5a42.3 42.3 0 0 1-8 3.5q-.166-.925-1-1.5a87.5 87.5 0 0 1 11-6 2262 2262 0 0 0 21-17.5 4.93 4.93 0 0 1 .5-3 27.8 27.8 0 0 0 6-8q3.485-3.663 7.5-6\" transform=\"translate(42.925 -3.817)\"/><path style=\"opacity:.868\" fill=\"#020101\" d=\"M1496.5 768.5c1.43.381 2.26 1.381 2.5 3 .92 5.923 2.08 11.757 3.5 17.5-3.75 4.418-8.08 8.084-13 11q-4.575 1.232-9-.5a227.4 227.4 0 0 0 16-31\" transform=\"translate(42.925 -3.817)\"/></g></g>"
            },
            GlassVariants::GLASS3 => {
                decidedGlass =
                    " style=\"clip-rule:evenodd;fill-rule:evenodd;image-rendering:optimizeQuality;shape-rendering:geometricPrecision;text-rendering:geometricPrecision\" xml:space=\"preserve\" xmlns=\"http://www.w3.org/2000/svg\"><defs><filter style=\"color-interpolation-filters:sRGB\" id=\"a\" x=\"-.015\" y=\"-.054\" width=\"1.03\" height=\"1.108\"><feGaussianBlur stdDeviation=\"5\" result=\"result3\"/><feColorMatrix values=\"1 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 0 50 0\" result=\"result7\"/><feComposite operator=\"in\" in2=\"SourceGraphic\" result=\"result9\"/><feComposite in2=\"result7\" operator=\"arithmetic\" in=\"result9\" k1=\".5\" k3=\".5\" result=\"result1\"/><feBlend in2=\"result1\" result=\"result5\" mode=\"screen\" in=\"SourceGraphic\"/><feBlend in2=\"result5\" mode=\"darken\" in=\"result5\" result=\"result6\"/><feComposite in2=\"SourceGraphic\" operator=\"in\" result=\"result8\"/></filter></defs><g style=\"display:inline;filter:url(#a)\" transform=\"translate(-4.93 1.565)scale(.1014)\"><g style=\"clip-rule:evenodd;opacity:1;fill-rule:evenodd;image-rendering:optimizeQuality;shape-rendering:geometricPrecision;text-rendering:geometricPrecision\"><g style=\"display:inline;fill:#000;fill-opacity:1\"><path style=\"opacity:.896;fill:#000;fill-opacity:1\" fill=\"#040303\" d=\"M810.5 578.5q92.502-.25 185 .5 1.493 2.751 4.5 3.5c28.61-3.413 56.45-.247 83.5 9.5 24.62 11.38 38.95 30.547 43 57.5 7.94-.406 15.77.261 23.5 2a9447 9447 0 0 1 240-23l1.5 1.5 14 .5c7.23-.516 14.4-.516 21.5 0q4.245-.554 7.5-2 3.465-.203 6 2c-5.89 1.264-11.56 3.764-17 7.5a43848 43848 0 0 0-294 28.5c2.78 23.825.62 47.158-6.5 70-22.28 45.728-57.11 59.562-104.5 41.5q-37.52-23.266-63-59.5-5.498-1.011-11 1a45.6 45.6 0 0 1-7-3q-13.132-21.267-21.5-45-1-2.5 0-5a95 95 0 0 1 8.5-8 498 498 0 0 0-7-35q-14.958-3.694-30 0a949 949 0 0 1-2.5 41q8.716-10.048 19.5-2.5 2.785 1.773 3 5a334 334 0 0 1-16.5 47.5q-12.897 10.128-22.5-2.5 1.836-3.585 1.5-7.5-17.92 36.092-46.5 64.5-13.826 12.416-32 17-27.83 3.798-48-15.5-24.287-24.067-30.5-58a297 297 0 0 1-4.5-46q-10.374 1.868-10-8.5-.327-10.045 10-8.5 2.996-63.747 67-67.5a178.7 178.7 0 0 1 32.5.5q.72-2.45 2.5-4m35 12a2209 2209 0 0 1 115-.5q-21.184 7.083-35 24.5-10.902-3.717-22.5-3l-14.5.5q-5.308.28-9.5 3.5-12.246-18.492-33.5-25\" transform=\"translate(42.925 -3.817)\"/></g><path style=\"opacity:1\" fill=\"#4f5161\" d=\"M800.5 589.5a419 419 0 0 0-34 1q9.904-2.241 20.5-2 7.02.001 13.5 1\" transform=\"translate(42.925 -3.817)\"/><path style=\"opacity:1\" fill=\"#505161\" d=\"M1034.5 589.5q-21.03-.227-42 1c8.11-1.511 16.45-2.178 25-2 5.84.001 11.51.334 17 1\" transform=\"translate(42.925 -3.817)\"/><g style=\"display:inline;opacity:.1\"><path style=\"opacity:1\" fill=\"#74778e\" d=\"M800.5 589.5q26.329.863 50 12v3q25.36 11.676 25 40-80.841-2.078-160 14v13q-4.823-29.679 8.5-57 15.947-21.158 42.5-24a419 419 0 0 1 34-1\" transform=\"translate(42.925 -3.817)\"/></g><g style=\"display:inline;opacity:.1\"><path style=\"opacity:1\" fill=\"#74778e\" d=\"M1034.5 589.5c18.92.317 36.59 4.984 53 14-.11.617-.44 1.117-1 1.5q12.6 8.262 21 20.5c4.74 9.971 8.07 20.304 10 31v5c.69 5.305 1.03 10.638 1 16a1251 1251 0 0 0-184-30q-3.294.007-6 1-6.187-39.142 32-51.5a110.3 110.3 0 0 1 32-6.5 607 607 0 0 1 42-1\" transform=\"translate(42.925 -3.817)\"/></g><path style=\"opacity:1\" fill=\"#57586a\" d=\"M850.5 601.5q31.593 15.183 27 50a25 25 0 0 0-.5-7q-.575.834-1.5 1v-1q.36-28.324-25-40z\" transform=\"translate(42.925 -3.817)\"/><path style=\"opacity:1\" fill=\"#5b5d6f\" d=\"M1087.5 603.5c11.84 6.176 20.17 15.509 25 28 .07.438-.1.772-.5 1q-1.545-4.108-4.5-7-8.4-12.238-21-20.5c.56-.383.89-.883 1-1.5\" transform=\"translate(42.925 -3.817)\"/><path style=\"opacity:1\" fill=\"#484958\" d=\"M1107.5 625.5q2.955 2.892 4.5 7c.4-.228.57-.562.5-1 4.1 7.848 5.77 16.182 5 25-1.93-10.696-5.26-21.029-10-31\" transform=\"translate(42.925 -3.817)\"/><g style=\"display:inline;opacity:.104\"><path style=\"opacity:1\" fill=\"#b9b6c7\" d=\"M875.5 644.5v1a109 109 0 0 1-6 30 10 10 0 0 0 1 3q-.143 3.429-2 6-76.635-3.544-150 18-3.762-15.061-3-31v-13q79.159-16.078 160-14\" transform=\"translate(42.925 -3.817)\"/></g><g style=\"display:inline;opacity:.1\"><path style=\"opacity:1\" fill=\"#b9b7c7\" d=\"M1118.5 677.5v25c-.24 4.342-.57 8.676-1 13q-2.055 5.191-3 11-83.37-28.284-171-38-10.776-18.592-15-40 2.706-.993 6-1a1251 1251 0 0 1 184 30\" transform=\"translate(42.925 -3.817)\"/></g><path style=\"opacity:1\" fill=\"#9795a3\" d=\"M877.5 651.5q-1.428 14.18-7 27a10 10 0 0 1-1-3 109 109 0 0 0 6-30q.925-.166 1.5-1 .745 3.465.5 7\" transform=\"translate(42.925 -3.817)\"/><path style=\"opacity:1\" fill=\"#52525d\" d=\"M1117.5 661.5c.81.929 1.65 1.929 2.5 3q.57 9.266 1.5 18.5-2.1 9.741-3 19.5v-25c.03-5.362-.31-10.695-1-16\" transform=\"translate(42.925 -3.817)\"/><g style=\"display:inline;opacity:.1\"><path style=\"opacity:1\" fill=\"#74778e\" d=\"M868.5 684.5a279.4 279.4 0 0 1-27 50q-4.015 2.337-7.5 6a27.8 27.8 0 0 1-6 8 4.93 4.93 0 0 0-.5 3 2262 2262 0 0 1-21 17.5 87.5 87.5 0 0 0-11 6q.834.575 1 1.5-21.007 7.603-40-4.5-34.039-26.313-38-69.5 73.365-21.544 150-18\" transform=\"translate(42.925 -3.817)\"/></g><g style=\"display:inline;opacity:.1\"><path style=\"opacity:1\" fill=\"#74778e\" d=\"M943.5 688.5q87.63 9.716 171 38a114 114 0 0 1-5 14c-5.01 8.448-11.34 15.948-19 22.5.92.278 1.58.778 2 1.5q-37.545 28.12-78 3.5-45.342-31.086-71-79.5\" transform=\"translate(42.925 -3.817)\"/></g><path style=\"opacity:1\" fill=\"#4b4c58\" d=\"M1117.5 715.5c.63 9.426-1.71 18.092-7 26 0-.667-.33-1-1-1 1.97-4.561 3.64-9.227 5-14q.945-5.809 3-11\" transform=\"translate(42.925 -3.817)\"/><path style=\"opacity:1\" fill=\"#5a5c6e\" d=\"M1109.5 740.5c.67 0 1 .333 1 1q-6.72 13.228-18 23c-.42-.722-1.08-1.222-2-1.5 7.66-6.552 13.99-14.052 19-22.5\" transform=\"translate(42.925 -3.817)\"/><path style=\"opacity:1\" fill=\"#686a7f\" d=\"M841.5 734.5q-14.619 22.871-37 38.5a42.3 42.3 0 0 1-8 3.5q-.166-.925-1-1.5a87.5 87.5 0 0 1 11-6 2262 2262 0 0 0 21-17.5 4.93 4.93 0 0 1 .5-3 27.8 27.8 0 0 0 6-8q3.485-3.663 7.5-6\" transform=\"translate(42.925 -3.817)\"/><path style=\"opacity:.868\" fill=\"#020101\" d=\"M1496.5 768.5c1.43.381 2.26 1.381 2.5 3 .92 5.923 2.08 11.757 3.5 17.5-3.75 4.418-8.08 8.084-13 11q-4.575 1.232-9-.5a227.4 227.4 0 0 0 16-31\" transform=\"translate(42.925 -3.817)\"/></g></g>"
            },
            GlassVariants::GLASS4 => {
                decidedGlass =
                    " style=\"clip-rule:evenodd;fill-rule:evenodd;image-rendering:optimizeQuality;shape-rendering:geometricPrecision;text-rendering:geometricPrecision\" xml:space=\"preserve\" xmlns=\"http://www.w3.org/2000/svg\"><defs><filter style=\"color-interpolation-filters:sRGB\" id=\"a\" x=\"-.015\" y=\"-.054\" width=\"1.03\" height=\"1.108\"><feGaussianBlur stdDeviation=\"5\" result=\"result3\"/><feColorMatrix values=\"1 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 0 50 0\" result=\"result7\"/><feComposite operator=\"in\" in2=\"SourceGraphic\" result=\"result9\"/><feComposite in2=\"result7\" operator=\"arithmetic\" in=\"result9\" k1=\".5\" k3=\".5\" result=\"result1\"/><feBlend in2=\"result1\" result=\"result5\" mode=\"screen\" in=\"SourceGraphic\"/><feBlend in2=\"result5\" mode=\"darken\" in=\"result5\" result=\"result6\"/><feComposite in2=\"SourceGraphic\" operator=\"in\" result=\"result8\"/></filter></defs><g style=\"display:inline;filter:url(#a)\" transform=\"translate(-4.93 1.565)scale(.1014)\"><g style=\"clip-rule:evenodd;opacity:1;fill-rule:evenodd;image-rendering:optimizeQuality;shape-rendering:geometricPrecision;text-rendering:geometricPrecision\"><g style=\"display:inline;fill:#000;fill-opacity:1\"><path style=\"opacity:.896;fill:#000;fill-opacity:1\" fill=\"#040303\" d=\"M810.5 578.5q92.502-.25 185 .5 1.493 2.751 4.5 3.5c28.61-3.413 56.45-.247 83.5 9.5 24.62 11.38 38.95 30.547 43 57.5 7.94-.406 15.77.261 23.5 2a9447 9447 0 0 1 240-23l1.5 1.5 14 .5c7.23-.516 14.4-.516 21.5 0q4.245-.554 7.5-2 3.465-.203 6 2c-5.89 1.264-11.56 3.764-17 7.5a43848 43848 0 0 0-294 28.5c2.78 23.825.62 47.158-6.5 70-22.28 45.728-57.11 59.562-104.5 41.5q-37.52-23.266-63-59.5-5.498-1.011-11 1a45.6 45.6 0 0 1-7-3q-13.132-21.267-21.5-45-1-2.5 0-5a95 95 0 0 1 8.5-8 498 498 0 0 0-7-35q-14.958-3.694-30 0a949 949 0 0 1-2.5 41q8.716-10.048 19.5-2.5 2.785 1.773 3 5a334 334 0 0 1-16.5 47.5q-12.897 10.128-22.5-2.5 1.836-3.585 1.5-7.5-17.92 36.092-46.5 64.5-13.826 12.416-32 17-27.83 3.798-48-15.5-24.287-24.067-30.5-58a297 297 0 0 1-4.5-46q-10.374 1.868-10-8.5-.327-10.045 10-8.5 2.996-63.747 67-67.5a178.7 178.7 0 0 1 32.5.5q.72-2.45 2.5-4m35 12a2209 2209 0 0 1 115-.5q-21.184 7.083-35 24.5-10.902-3.717-22.5-3l-14.5.5q-5.308.28-9.5 3.5-12.246-18.492-33.5-25\" transform=\"translate(42.925 -3.817)\"/></g><path style=\"opacity:1\" fill=\"#4f5161\" d=\"M800.5 589.5a419 419 0 0 0-34 1q9.904-2.241 20.5-2 7.02.001 13.5 1\" transform=\"translate(42.925 -3.817)\"/><path style=\"opacity:1\" fill=\"#505161\" d=\"M1034.5 589.5q-21.03-.227-42 1c8.11-1.511 16.45-2.178 25-2 5.84.001 11.51.334 17 1\" transform=\"translate(42.925 -3.817)\"/><g style=\"display:inline;opacity:.1\"><path style=\"opacity:1\" fill=\"#74778e\" d=\"M800.5 589.5q26.329.863 50 12v3q25.36 11.676 25 40-80.841-2.078-160 14v13q-4.823-29.679 8.5-57 15.947-21.158 42.5-24a419 419 0 0 1 34-1\" transform=\"translate(42.925 -3.817)\"/></g><g style=\"display:inline;opacity:.1\"><path style=\"opacity:1\" fill=\"#74778e\" d=\"M1034.5 589.5c18.92.317 36.59 4.984 53 14-.11.617-.44 1.117-1 1.5q12.6 8.262 21 20.5c4.74 9.971 8.07 20.304 10 31v5c.69 5.305 1.03 10.638 1 16a1251 1251 0 0 0-184-30q-3.294.007-6 1-6.187-39.142 32-51.5a110.3 110.3 0 0 1 32-6.5 607 607 0 0 1 42-1\" transform=\"translate(42.925 -3.817)\"/></g><path style=\"opacity:1\" fill=\"#57586a\" d=\"M850.5 601.5q31.593 15.183 27 50a25 25 0 0 0-.5-7q-.575.834-1.5 1v-1q.36-28.324-25-40z\" transform=\"translate(42.925 -3.817)\"/><path style=\"opacity:1\" fill=\"#5b5d6f\" d=\"M1087.5 603.5c11.84 6.176 20.17 15.509 25 28 .07.438-.1.772-.5 1q-1.545-4.108-4.5-7-8.4-12.238-21-20.5c.56-.383.89-.883 1-1.5\" transform=\"translate(42.925 -3.817)\"/><path style=\"opacity:1\" fill=\"#484958\" d=\"M1107.5 625.5q2.955 2.892 4.5 7c.4-.228.57-.562.5-1 4.1 7.848 5.77 16.182 5 25-1.93-10.696-5.26-21.029-10-31\" transform=\"translate(42.925 -3.817)\"/><g style=\"display:inline;opacity:.104\"><path style=\"opacity:1\" fill=\"#b9b6c7\" d=\"M875.5 644.5v1a109 109 0 0 1-6 30 10 10 0 0 0 1 3q-.143 3.429-2 6-76.635-3.544-150 18-3.762-15.061-3-31v-13q79.159-16.078 160-14\" transform=\"translate(42.925 -3.817)\"/></g><g style=\"display:inline;opacity:.1\"><path style=\"opacity:1\" fill=\"#b9b7c7\" d=\"M1118.5 677.5v25c-.24 4.342-.57 8.676-1 13q-2.055 5.191-3 11-83.37-28.284-171-38-10.776-18.592-15-40 2.706-.993 6-1a1251 1251 0 0 1 184 30\" transform=\"translate(42.925 -3.817)\"/></g><path style=\"opacity:1\" fill=\"#9795a3\" d=\"M877.5 651.5q-1.428 14.18-7 27a10 10 0 0 1-1-3 109 109 0 0 0 6-30q.925-.166 1.5-1 .745 3.465.5 7\" transform=\"translate(42.925 -3.817)\"/><path style=\"opacity:1\" fill=\"#52525d\" d=\"M1117.5 661.5c.81.929 1.65 1.929 2.5 3q.57 9.266 1.5 18.5-2.1 9.741-3 19.5v-25c.03-5.362-.31-10.695-1-16\" transform=\"translate(42.925 -3.817)\"/><g style=\"display:inline;opacity:.1\"><path style=\"opacity:1\" fill=\"#74778e\" d=\"M868.5 684.5a279.4 279.4 0 0 1-27 50q-4.015 2.337-7.5 6a27.8 27.8 0 0 1-6 8 4.93 4.93 0 0 0-.5 3 2262 2262 0 0 1-21 17.5 87.5 87.5 0 0 0-11 6q.834.575 1 1.5-21.007 7.603-40-4.5-34.039-26.313-38-69.5 73.365-21.544 150-18\" transform=\"translate(42.925 -3.817)\"/></g><g style=\"display:inline;opacity:.1\"><path style=\"opacity:1\" fill=\"#74778e\" d=\"M943.5 688.5q87.63 9.716 171 38a114 114 0 0 1-5 14c-5.01 8.448-11.34 15.948-19 22.5.92.278 1.58.778 2 1.5q-37.545 28.12-78 3.5-45.342-31.086-71-79.5\" transform=\"translate(42.925 -3.817)\"/></g><path style=\"opacity:1\" fill=\"#4b4c58\" d=\"M1117.5 715.5c.63 9.426-1.71 18.092-7 26 0-.667-.33-1-1-1 1.97-4.561 3.64-9.227 5-14q.945-5.809 3-11\" transform=\"translate(42.925 -3.817)\"/><path style=\"opacity:1\" fill=\"#5a5c6e\" d=\"M1109.5 740.5c.67 0 1 .333 1 1q-6.72 13.228-18 23c-.42-.722-1.08-1.222-2-1.5 7.66-6.552 13.99-14.052 19-22.5\" transform=\"translate(42.925 -3.817)\"/><path style=\"opacity:1\" fill=\"#686a7f\" d=\"M841.5 734.5q-14.619 22.871-37 38.5a42.3 42.3 0 0 1-8 3.5q-.166-.925-1-1.5a87.5 87.5 0 0 1 11-6 2262 2262 0 0 0 21-17.5 4.93 4.93 0 0 1 .5-3 27.8 27.8 0 0 0 6-8q3.485-3.663 7.5-6\" transform=\"translate(42.925 -3.817)\"/><path style=\"opacity:.868\" fill=\"#020101\" d=\"M1496.5 768.5c1.43.381 2.26 1.381 2.5 3 .92 5.923 2.08 11.757 3.5 17.5-3.75 4.418-8.08 8.084-13 11q-4.575 1.232-9-.5a227.4 227.4 0 0 0 16-31\" transform=\"translate(42.925 -3.817)\"/></g></g>"
            },
            GlassVariants::GLASS5 => {
                decidedGlass =
                    " style=\"clip-rule:evenodd;fill-rule:evenodd;image-rendering:optimizeQuality;shape-rendering:geometricPrecision;text-rendering:geometricPrecision\" xml:space=\"preserve\" xmlns=\"http://www.w3.org/2000/svg\"><defs><filter style=\"color-interpolation-filters:sRGB\" id=\"a\" x=\"-.015\" y=\"-.054\" width=\"1.03\" height=\"1.108\"><feGaussianBlur stdDeviation=\"5\" result=\"result3\"/><feColorMatrix values=\"1 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 0 50 0\" result=\"result7\"/><feComposite operator=\"in\" in2=\"SourceGraphic\" result=\"result9\"/><feComposite in2=\"result7\" operator=\"arithmetic\" in=\"result9\" k1=\".5\" k3=\".5\" result=\"result1\"/><feBlend in2=\"result1\" result=\"result5\" mode=\"screen\" in=\"SourceGraphic\"/><feBlend in2=\"result5\" mode=\"darken\" in=\"result5\" result=\"result6\"/><feComposite in2=\"SourceGraphic\" operator=\"in\" result=\"result8\"/></filter></defs><g style=\"display:inline;filter:url(#a)\" transform=\"translate(-4.93 1.565)scale(.1014)\"><g style=\"clip-rule:evenodd;opacity:1;fill-rule:evenodd;image-rendering:optimizeQuality;shape-rendering:geometricPrecision;text-rendering:geometricPrecision\"><g style=\"display:inline;fill:#000;fill-opacity:1\"><path style=\"opacity:.896;fill:#000;fill-opacity:1\" fill=\"#040303\" d=\"M810.5 578.5q92.502-.25 185 .5 1.493 2.751 4.5 3.5c28.61-3.413 56.45-.247 83.5 9.5 24.62 11.38 38.95 30.547 43 57.5 7.94-.406 15.77.261 23.5 2a9447 9447 0 0 1 240-23l1.5 1.5 14 .5c7.23-.516 14.4-.516 21.5 0q4.245-.554 7.5-2 3.465-.203 6 2c-5.89 1.264-11.56 3.764-17 7.5a43848 43848 0 0 0-294 28.5c2.78 23.825.62 47.158-6.5 70-22.28 45.728-57.11 59.562-104.5 41.5q-37.52-23.266-63-59.5-5.498-1.011-11 1a45.6 45.6 0 0 1-7-3q-13.132-21.267-21.5-45-1-2.5 0-5a95 95 0 0 1 8.5-8 498 498 0 0 0-7-35q-14.958-3.694-30 0a949 949 0 0 1-2.5 41q8.716-10.048 19.5-2.5 2.785 1.773 3 5a334 334 0 0 1-16.5 47.5q-12.897 10.128-22.5-2.5 1.836-3.585 1.5-7.5-17.92 36.092-46.5 64.5-13.826 12.416-32 17-27.83 3.798-48-15.5-24.287-24.067-30.5-58a297 297 0 0 1-4.5-46q-10.374 1.868-10-8.5-.327-10.045 10-8.5 2.996-63.747 67-67.5a178.7 178.7 0 0 1 32.5.5q.72-2.45 2.5-4m35 12a2209 2209 0 0 1 115-.5q-21.184 7.083-35 24.5-10.902-3.717-22.5-3l-14.5.5q-5.308.28-9.5 3.5-12.246-18.492-33.5-25\" transform=\"translate(42.925 -3.817)\"/></g><path style=\"opacity:1\" fill=\"#4f5161\" d=\"M800.5 589.5a419 419 0 0 0-34 1q9.904-2.241 20.5-2 7.02.001 13.5 1\" transform=\"translate(42.925 -3.817)\"/><path style=\"opacity:1\" fill=\"#505161\" d=\"M1034.5 589.5q-21.03-.227-42 1c8.11-1.511 16.45-2.178 25-2 5.84.001 11.51.334 17 1\" transform=\"translate(42.925 -3.817)\"/><g style=\"display:inline;opacity:.1\"><path style=\"opacity:1\" fill=\"#74778e\" d=\"M800.5 589.5q26.329.863 50 12v3q25.36 11.676 25 40-80.841-2.078-160 14v13q-4.823-29.679 8.5-57 15.947-21.158 42.5-24a419 419 0 0 1 34-1\" transform=\"translate(42.925 -3.817)\"/></g><g style=\"display:inline;opacity:.1\"><path style=\"opacity:1\" fill=\"#74778e\" d=\"M1034.5 589.5c18.92.317 36.59 4.984 53 14-.11.617-.44 1.117-1 1.5q12.6 8.262 21 20.5c4.74 9.971 8.07 20.304 10 31v5c.69 5.305 1.03 10.638 1 16a1251 1251 0 0 0-184-30q-3.294.007-6 1-6.187-39.142 32-51.5a110.3 110.3 0 0 1 32-6.5 607 607 0 0 1 42-1\" transform=\"translate(42.925 -3.817)\"/></g><path style=\"opacity:1\" fill=\"#57586a\" d=\"M850.5 601.5q31.593 15.183 27 50a25 25 0 0 0-.5-7q-.575.834-1.5 1v-1q.36-28.324-25-40z\" transform=\"translate(42.925 -3.817)\"/><path style=\"opacity:1\" fill=\"#5b5d6f\" d=\"M1087.5 603.5c11.84 6.176 20.17 15.509 25 28 .07.438-.1.772-.5 1q-1.545-4.108-4.5-7-8.4-12.238-21-20.5c.56-.383.89-.883 1-1.5\" transform=\"translate(42.925 -3.817)\"/><path style=\"opacity:1\" fill=\"#484958\" d=\"M1107.5 625.5q2.955 2.892 4.5 7c.4-.228.57-.562.5-1 4.1 7.848 5.77 16.182 5 25-1.93-10.696-5.26-21.029-10-31\" transform=\"translate(42.925 -3.817)\"/><g style=\"display:inline;opacity:.104\"><path style=\"opacity:1\" fill=\"#b9b6c7\" d=\"M875.5 644.5v1a109 109 0 0 1-6 30 10 10 0 0 0 1 3q-.143 3.429-2 6-76.635-3.544-150 18-3.762-15.061-3-31v-13q79.159-16.078 160-14\" transform=\"translate(42.925 -3.817)\"/></g><g style=\"display:inline;opacity:.1\"><path style=\"opacity:1\" fill=\"#b9b7c7\" d=\"M1118.5 677.5v25c-.24 4.342-.57 8.676-1 13q-2.055 5.191-3 11-83.37-28.284-171-38-10.776-18.592-15-40 2.706-.993 6-1a1251 1251 0 0 1 184 30\" transform=\"translate(42.925 -3.817)\"/></g><path style=\"opacity:1\" fill=\"#9795a3\" d=\"M877.5 651.5q-1.428 14.18-7 27a10 10 0 0 1-1-3 109 109 0 0 0 6-30q.925-.166 1.5-1 .745 3.465.5 7\" transform=\"translate(42.925 -3.817)\"/><path style=\"opacity:1\" fill=\"#52525d\" d=\"M1117.5 661.5c.81.929 1.65 1.929 2.5 3q.57 9.266 1.5 18.5-2.1 9.741-3 19.5v-25c.03-5.362-.31-10.695-1-16\" transform=\"translate(42.925 -3.817)\"/><g style=\"display:inline;opacity:.1\"><path style=\"opacity:1\" fill=\"#74778e\" d=\"M868.5 684.5a279.4 279.4 0 0 1-27 50q-4.015 2.337-7.5 6a27.8 27.8 0 0 1-6 8 4.93 4.93 0 0 0-.5 3 2262 2262 0 0 1-21 17.5 87.5 87.5 0 0 0-11 6q.834.575 1 1.5-21.007 7.603-40-4.5-34.039-26.313-38-69.5 73.365-21.544 150-18\" transform=\"translate(42.925 -3.817)\"/></g><g style=\"display:inline;opacity:.1\"><path style=\"opacity:1\" fill=\"#74778e\" d=\"M943.5 688.5q87.63 9.716 171 38a114 114 0 0 1-5 14c-5.01 8.448-11.34 15.948-19 22.5.92.278 1.58.778 2 1.5q-37.545 28.12-78 3.5-45.342-31.086-71-79.5\" transform=\"translate(42.925 -3.817)\"/></g><path style=\"opacity:1\" fill=\"#4b4c58\" d=\"M1117.5 715.5c.63 9.426-1.71 18.092-7 26 0-.667-.33-1-1-1 1.97-4.561 3.64-9.227 5-14q.945-5.809 3-11\" transform=\"translate(42.925 -3.817)\"/><path style=\"opacity:1\" fill=\"#5a5c6e\" d=\"M1109.5 740.5c.67 0 1 .333 1 1q-6.72 13.228-18 23c-.42-.722-1.08-1.222-2-1.5 7.66-6.552 13.99-14.052 19-22.5\" transform=\"translate(42.925 -3.817)\"/><path style=\"opacity:1\" fill=\"#686a7f\" d=\"M841.5 734.5q-14.619 22.871-37 38.5a42.3 42.3 0 0 1-8 3.5q-.166-.925-1-1.5a87.5 87.5 0 0 1 11-6 2262 2262 0 0 0 21-17.5 4.93 4.93 0 0 1 .5-3 27.8 27.8 0 0 0 6-8q3.485-3.663 7.5-6\" transform=\"translate(42.925 -3.817)\"/><path style=\"opacity:.868\" fill=\"#020101\" d=\"M1496.5 768.5c1.43.381 2.26 1.381 2.5 3 .92 5.923 2.08 11.757 3.5 17.5-3.75 4.418-8.08 8.084-13 11q-4.575 1.232-9-.5a227.4 227.4 0 0 0 16-31\" transform=\"translate(42.925 -3.817)\"/></g></g>"
            }
        }
        decidedGlass
    }
}