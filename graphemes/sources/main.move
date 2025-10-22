module addr::main {
    use std::string::String;

    // Try calling this with an argument with Graphemes:
    // aptos move view --function-id default::main::experiment_with_graphemes --args string:'我喜欢吃饺子'
    #[view]
    fun experiment_with_graphemes(input: String): u64 {
        input.length()
    }
}
