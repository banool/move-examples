module my_addr::mine {
    use other_addr::other::do_nothing;

    public entry fun do_stuff() {
        do_nothing();
    }
}
