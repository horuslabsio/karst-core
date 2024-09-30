pub impl FeltTryIntoByteArray of TryInto<felt252, ByteArray> {
    fn try_into(self: felt252) -> Option<ByteArray> {
        let mut res: ByteArray = Default::default();
        // res.pending_word = self;
        let mut length = 0;
        let mut data: u256 = self.into();
        loop {
            if data == 0 {
                break;
            }
            data /= 0x100;
            length += 1;
        };
        // res.pending_word_len = length;
        Option::Some(res)
    }
}
