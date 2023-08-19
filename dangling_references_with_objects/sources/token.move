// Copyright (c) Aptos Labs
// SPDX-License-Identifier: Apache-2.0

// TODO: Something else the compiler should do is complain when multiple error codes
// have the same value. I have made this mistake in the past.

// This code demonstrates a common source of pain when working with objects. Generally
// speaking it is pretty common that, in the course of a complex function, you might
// want to use both the Object<T> and a (mutable) reference to the T itself. But you
// can't do that easily, you have to use the Object<T> first and then the &T after,
// with no mixing, otherwise you'll get dangling reference errors.
//
// I describe these issues in greater detail below.

module addr::canvas_token {
    use std::error;
    use std::signer;
    use std::vector;
    use aptos_std::object::{Self, Object};

    /// Caller is not allowlisted.
    const E_NOT_ALLOWLISTED: u64 = 1;

    /// Color is not allowed.
    const E_COLOR_NOT_ALLOWED: u64 = 2;

    #[resource_group_member(group = aptos_framework::object::ObjectGroup)]
    struct Canvas has key {
        pixels: vector<Color>,
        allowlist: vector<address>,
        allowed_colors: vector<Color>,
    }

    struct Color has copy, drop, store {
        r: u8,
        g: u8,
        b: u8,
    }

    // This function actually tries to mutate the `pixels` vector. This is the error
    // you get:
    //
    // error[E07003]: invalid operation, could create dangling a reference
    //    /Users/dport/demonstration/sources/token.move:50:9
    //
    //             let canvas_ = borrow_global_mut<Canvas>(object::object_address(&canvas));
    //                           ---------------------------------------------------------- It is still being mutably borrowed by this reference
    //
    //             assert_color_is_allowed(canvas, &color);
    //             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Invalid acquiring of resource 'Canvas'
    //
    // I understand why this happens in this case. I'd rather it didn't, and the
    // compiler just magically figured out whether if what I'm doing is safe, but
    // perhaps it's just not safe at all (I haven't thought too hard about the borrow
    // behavior here).
    public entry fun draw_a(
        caller: &signer,
        canvas: Object<Canvas>,
        index: u64,
        r: u8,
        g: u8,
        b: u8,
    ) acquires Canvas {
        let caller_addr = signer::address_of(caller);

        // Make sure the caller is allowed to draw.
        assert_allowlisted_to_draw(canvas, &caller_addr);

        let canvas_ = borrow_global_mut<Canvas>(object::object_address(&canvas));

        // Make sure the color is allowed.
        let color = Color { r, g, b };
        assert_color_is_allowed(canvas, &color);

        // Write the pixel.
        *vector::borrow_mut(&mut canvas_.pixels, index) = color;
    }

    // This function does not actually try to borrow anything mutably or mutate
    // anything. Despite that, you get this error:
    //
    // error[E07003]: invalid operation, could create dangling a reference
    //    /Users/dport/demonstration/sources/token.move:50:9
    //
    //             let canvas_ = borrow_global<Canvas>(object::object_address(&canvas));
    //                           ------------------------------------------------------- It is still being borrowed by this reference
    //
    //             assert_color_is_allowed(canvas, &color);
    //             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Invalid acquiring of resource 'Canvas'
    //
    // Now this I don't really understand. As far as I'm aware we're only working
    // with immutable (shared) references, indeed the error message indicates as
    // such, so idk why we can't have multiple references.
    public entry fun draw_b(
        caller: &signer,
        canvas: Object<Canvas>,
        index: u64,
        r: u8,
        g: u8,
        b: u8,
    ) acquires Canvas {
        let caller_addr = signer::address_of(caller);

        // Make sure the caller is allowed to draw.
        assert_allowlisted_to_draw(canvas, &caller_addr);

        let canvas_ = borrow_global<Canvas>(object::object_address(&canvas));

        // Make sure the color is allowed.
        let color = Color { r, g, b };
        assert_color_is_allowed(canvas, &color);

        // Write the pixel (but not actually).
        vector::borrow(&canvas_.pixels, index);
    }

    // This function is here just to make the issue abundantly clear. As you can see,
    // in this case we call all the functions that require Object<T> first before we
    // get a &T. This function compiles happily. This inflexibility is pretty bad devex,
    // ideally we can find a way to fix it.
    public entry fun draw_c(
        caller: &signer,
        canvas: Object<Canvas>,
        index: u64,
        r: u8,
        g: u8,
        b: u8,
    ) acquires Canvas {
        let caller_addr = signer::address_of(caller);

        // Make sure the caller is allowed to draw.
        assert_allowlisted_to_draw(canvas, &caller_addr);

        // Make sure the color is allowed.
        let color = Color { r, g, b };
        assert_color_is_allowed(canvas, &color);

        let canvas_ = borrow_global<Canvas>(object::object_address(&canvas));

        // Write the pixel (but not actually).
        vector::borrow(&canvas_.pixels, index);
    }

    fun assert_allowlisted_to_draw(canvas: Object<Canvas>, caller_addr: &address) acquires Canvas {
        let canvas_ = borrow_global<Canvas>(object::object_address(&canvas));
        let allowlisted = vector::contains(&canvas_.allowlist, caller_addr);
        assert!(allowlisted, error::invalid_state(E_NOT_ALLOWLISTED));
    }

    fun assert_color_is_allowed(canvas: Object<Canvas>, color: &Color) acquires Canvas {
        let canvas_ = borrow_global<Canvas>(object::object_address(&canvas));
        let color_is_allowed = vector::contains(&canvas_.allowed_colors, color);
        assert!(color_is_allowed, error::invalid_state(E_NOT_ALLOWLISTED));
    }
}
