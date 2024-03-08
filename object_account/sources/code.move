module addr::object_account {
  use std::error;
  use std::signer;
  use aptos_framework::account::Account;
  use aptos_framework::aptos_account;
  use aptos_framework::object::{Self, ExtendRef, Object};

  /// You are not the owner of the object.
  const CALLER_NOT_OWNER: u64 = 1;

  // This holds the ExtendRef, which we need to get a signer for the object so we can
  // transfer funds.
  struct MyRefs has key, store {
    extend_ref: ExtendRef,
  }

  // Create an Object. Create an Account alongside it. Store MyRefs alongside it.
  entry fun create(caller: &signer) {
    // Create an object.
    let caller_address = signer::address_of(caller);
    let constructor_ref = object::create_object(caller_address);
    let object_address = object::address_from_constructor_ref(&constructor_ref);

    // Create an account alongside the object.
    aptos_account::create_account(object_address);

    // Store an ExtendRef alongside the object.
    let object_signer = object::generate_signer(&constructor_ref);
    let extend_ref = object::generate_extend_ref(&constructor_ref);
    move_to(
      &object_signer,
      MyRefs { extend_ref: extend_ref },
    );
  }

  // Transfer funds held by the account to someone. Only the owner of the object
  // can call this.
  entry fun transfer(caller: &signer, obj: Object<Account>, to: address, amount: u64) acquires MyRefs {
    let caller_address = signer::address_of(caller);
    assert!(object::is_owner(obj, caller_address), error::permission_denied(CALLER_NOT_OWNER));
    //aptos_account::transfer(caller, to, amount);
    let obj_address = object::object_address(&obj);
    let my_refs = borrow_global<MyRefs>(obj_address);
    let object_signer = object::generate_signer_for_extending(&my_refs.extend_ref);
    aptos_account::transfer(&object_signer, to, amount);
  }
}
