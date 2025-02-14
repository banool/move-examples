module thisaddr::basic {
    use otheraddrone::basic::{Self as modone};
    use otheraddrtwo::basic::{Self as modtwo};

    public fun quadruple_number(n: u64): u64 {
        modone::double_number(n) * 2
    }
}
