module addr::signed_integers {
    use aptos_framework::event;

    #[event]
    struct MyEvent has drop, store {
        a: i8,
        b: i64,
        c: i128,
        d: i256,
        e: u32,
    }

    public entry fun emit_event(a: i8, b: i64, c: i128, d: i256, e: u32) {
        event::emit(MyEvent { a, b, c, d, e });
    }
}
