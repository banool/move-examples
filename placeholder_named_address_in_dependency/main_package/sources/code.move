module thisaddr::basic {
    use otheraddr::basic::double_number;

    public fun quadruple_number(n: u64): u64 {
        double_number(n) * 2
    }
}
