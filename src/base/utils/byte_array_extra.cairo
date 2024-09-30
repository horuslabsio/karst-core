pub impl FeltTryIntoByteArray of TryInto<felt252, ByteArray> {
    fn try_into(self: felt252) -> Option<ByteArray> {
        let mut res: ByteArray = "";
        let mut length = 0;
        let mut data: u256 = self.into();
        loop {
            if data == 0 {
                break;
            }
            data /= 0x100;
            length += 1;
        };
        
        res.append_word(self, length);
        Option::Some(res)
    }
}

#[cfg(test)]
mod tests {
    use super::FeltTryIntoByteArray;

    #[test]
    fn from_felt252() {
        let a = 'hello how are you?';
        let b: ByteArray = a.try_into().unwrap();
        
        assert(b == "hello how are you?", 'invalid byteArray');
    }
}