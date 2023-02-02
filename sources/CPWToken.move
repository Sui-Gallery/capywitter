
module capywitter::cpwtoken {
    use std::option;
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::balance::{Self, Balance};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, UID};

    const INITIAL_SUPPLY: u64 = 100000;
    const TreasuryAddress: address = @0x92255b86c0740fc1e4cdf34c0a5edd34d00a8f5d;
    const TOKENS_PER_CAPY: u64 = 10;

    friend capywitter::capy_exchange;

    // Errors

    const EInsufficientReserve: u64 = 0;

    struct CPWTOKEN has drop {}

    struct Reserve has key {
        id: UID,
        balance: Balance<CPWTOKEN>,
    }

    struct TestCapy has key, store {
        id: UID
    }

    #[test_only]
    public entry fun mint_capy(ctx: &mut TxContext) {
        transfer::transfer(
            TestCapy {
                id: object::new(ctx)
            },
            tx_context::sender(ctx)
        );
    }

    fun init(witness: CPWTOKEN, ctx: &mut TxContext) {
        // Get the treasury capability and metada for the coin
        let (treasury_cap, metadata) = coin::create_currency<CPWTOKEN>(witness, 0, b"CPWTOKEN", b"Capywitter Token", 
            b"Token of Cappywitter dapp developed by Sui Gallery", option::none(), ctx);
        transfer::freeze_object(metadata);

        // Mint the inital supply
        let minted_coins = coin::mint<CPWTOKEN>(&mut treasury_cap, INITIAL_SUPPLY, ctx);
        let minted_balance = coin::into_balance<CPWTOKEN>(minted_coins);
        transfer::share_object(
            Reserve {
                id: object::new(ctx),
                balance: minted_balance
            }
        );
        // Transfer treasury capability to deployer address
        transfer::transfer(treasury_cap, tx_context::sender(ctx));
    }

    public(friend) fun get_tokens_for_exchange(reserve: &mut Reserve, 
        amount: u64, exchanged_address: address, ctx: &mut TxContext) {
        let cpw_balance_available = reserve_balance(reserve);
        assert!(amount <= cpw_balance_available, EInsufficientReserve);
        let balance_for_capy = get_reserve_balance_owned(reserve, amount);
        let tokens_for_capy = coin::from_balance(balance_for_capy, ctx);
        transfer::transfer(tokens_for_capy, exchanged_address);
    }

    public entry fun withdraw_tokens(_: &mut TreasuryCap<CPWTOKEN>, reserve: &mut Reserve, 
        ctx: &mut TxContext) {
        let reserve_balance_val = reserve_balance(reserve);
        let cpw_balance = get_reserve_balance_owned(reserve, reserve_balance_val);
        let cpw_coins = coin::from_balance(cpw_balance, ctx);
        transfer::transfer(cpw_coins, tx_context::sender(ctx));
    }

    public entry fun transfer(coin: Coin<CPWTOKEN>, to: address, amount: u64, ctx: &mut TxContext) {
        let coin_to_send = coin::split<CPWTOKEN>(&mut coin, amount, ctx);
        transfer::transfer(coin, tx_context::sender(ctx));
        transfer::transfer(coin_to_send, to);
    }

    fun get_reserve_balance_owned(reserve: &mut Reserve, amount: u64): Balance<CPWTOKEN> {
        balance::split(&mut reserve.balance, amount)
    }

    public fun reserve_balance(reserve: &Reserve): u64 {
        balance::value(&reserve.balance)
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        init(CPWTOKEN {}, ctx)
    }
}