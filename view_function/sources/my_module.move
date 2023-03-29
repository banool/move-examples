module addr::view_func {
    use std::string::{Self, String};

    struct MyStruct {
        x: u64,
        y: String,
    }

    #[view]
    public fun get_my_struct(z: u64): MyStruct {
        MyStruct { x: 42 + z, y: string::utf8(b"Hello World!") }
    }

    #[view]
    public fun add_ints(x: u64, y: u64): u64 {
        x + y + 10
    }
}
