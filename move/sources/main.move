module MyModule::ScavengerHunt {
    use std::signer;
    use std::vector;
    use aptos_std::table::{Self, Table};

    /// Represents the game state
    struct GameState has key {
        owner: address,
        valid_keys: vector<vector<u8>>,
        user_submitted_keys: Table<address, Table<vector<u8>, bool>>,
        user_unique_key_count: Table<address, u64>,
    }

    /// Errors
    const EINVALID_KEY: u64 = 1;
    const EKEY_ALREADY_SUBMITTED: u64 = 2;
    const ENOT_INITIALIZED: u64 = 3;

    fun init_module(account: &signer) {
        let owner_addr = signer::address_of(account);
        
        // Create valid keys
        let valid_keys = vector::empty<vector<u8>>();
        vector::push_back(&mut valid_keys, b"Key1");
        vector::push_back(&mut valid_keys, b"Key2");
        vector::push_back(&mut valid_keys, b"Key3");
        vector::push_back(&mut valid_keys, b"Key4");
        vector::push_back(&mut valid_keys, b"Key5");

        move_to(account, GameState {
            owner: owner_addr,
            valid_keys,
            user_submitted_keys: table::new(),
            user_unique_key_count: table::new(),
        });
    }

    /// Internal function to check if a key is valid
    fun is_valid_key_internal(game_state: &GameState, key: &vector<u8>): bool {
        let i = 0;
        let len = vector::length(&game_state.valid_keys);
        
        while (i < len) {
            if (vector::borrow(&game_state.valid_keys, i) == key) {
                return true
            };
            i = i + 1;
        };
        false
    }

    /// Submit a key to the scavenger hunt
    public entry fun submit_key(account: &signer, key: vector<u8>) acquires GameState {
        let game_state = borrow_global_mut<GameState>(@MyModule);
        let sender_addr = signer::address_of(account);

        // Verify key is valid
        assert!(is_valid_key_internal(game_state, &key), EINVALID_KEY);

        // Initialize user's submitted keys table if not exists
        if (!table::contains(&game_state.user_submitted_keys, sender_addr)) {
            table::add(&mut game_state.user_submitted_keys, sender_addr, table::new());
        };

        // Get user's submitted keys
        let user_keys = table::borrow_mut(&mut game_state.user_submitted_keys, sender_addr);

        // Check if key was already submitted
        assert!(!table::contains(user_keys, copy key), EKEY_ALREADY_SUBMITTED);

        // Add key to user's submitted keys
        table::add(user_keys, key, true);

        // Update user's unique key count
        if (!table::contains(&game_state.user_unique_key_count, sender_addr)) {
            table::add(&mut game_state.user_unique_key_count, sender_addr, 1);
        } else {
            let count = table::borrow_mut(&mut game_state.user_unique_key_count, sender_addr);
            *count = *count + 1;
        };
    }

    /// Public function to check if a key is valid
    #[view]
    public fun is_valid_key(key: vector<u8>): bool acquires GameState {
        let game_state = borrow_global<GameState>(@MyModule);
        is_valid_key_internal(game_state, &key)
    }

    /// Get user's progress (number of unique keys submitted)
    #[view]
    public fun get_user_progress(user: address): u64 acquires GameState {
        let game_state = borrow_global<GameState>(@MyModule);
        if (table::contains(&game_state.user_unique_key_count, user)) {
            *table::borrow(&game_state.user_unique_key_count, user)
        } else {
            0
        }
    }

    #[test_only]
    public fun initialize_for_test(account: &signer) {
        init_module(account);
    }
}
