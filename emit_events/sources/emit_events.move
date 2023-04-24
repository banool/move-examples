module addr::emit_events {
    use std::signer;
    use std::string::String;
    use std::vector;
    use aptos_framework::account::new_event_handle;
    use aptos_framework::event::{Self, EventHandle};

    struct FriendStore has key {
        friends: vector<String>,
		add_friend_events: EventHandle<AddFriendEvent>,
		remove_newest_friend_events: EventHandle<RemoveNewestFriendEvent>,
    }

    struct AddFriendEvent has drop, store {
        name: String,
    }

    struct RemoveNewestFriendEvent has drop, store {
        new_friend_count: u64,
    }

    public entry fun add_friend(account: &signer, name: String) acquires FriendStore {
        let addr = signer::address_of(account);

        if (!exists<FriendStore>(addr)) {
            let friend_store = FriendStore {
                friends: vector::empty(),
                add_friend_events: new_event_handle<AddFriendEvent>(account),
                remove_newest_friend_events: new_event_handle<RemoveNewestFriendEvent>(account),
            };
            move_to(account, friend_store);
        };

        let friend_store = borrow_global_mut<FriendStore>(addr);
        vector::push_back(&mut friend_store.friends, name);

        event::emit_event(
            &mut friend_store.add_friend_events,
            AddFriendEvent { name }
        );
    }

    public entry fun remove_newest_friend(account: &signer) acquires FriendStore {
        let addr = signer::address_of(account);

        let friend_store = borrow_global_mut<FriendStore>(addr);
        vector::pop_back(&mut friend_store.friends);

        event::emit_event(
            &mut friend_store.remove_newest_friend_events,
            RemoveNewestFriendEvent {
                new_friend_count: vector::length(&friend_store.friends)
            }
        );
    }
}
