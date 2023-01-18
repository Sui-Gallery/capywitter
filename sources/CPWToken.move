
module capywitter::cpwtoken {
    use std::option;
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::balance::{Self, Balance};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, UID};
    use std::vector as vec;
    use capy::capy::Capy;

    const INITIAL_SUPPLY: u64 = 100000;
    const TreasuryAddress: address = @0x92255b86c0740fc1e4cdf34c0a5edd34d00a8f5d;
    const TOKENS_PER_CAPY: u64 = 10;

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

        // Seperate %1 of tokens to deployer
        let coin_for_deployer = coin::split<CPWTOKEN>(&mut minted_coins, INITIAL_SUPPLY / 100 ,ctx);
        // Send deployer his tokens
        transfer::transfer(coin_for_deployer, tx_context::sender(ctx));

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

    public entry fun exchange_tokens_for_capy(capy_vec: vector<Capy>, reserve: &mut Reserve, ctx: &mut TxContext) {
        let capy_num = vec::length(&capy_vec);
        let i = 0u64;
        while (i < capy_num) {
            transfer::transfer(vec::pop_back<Capy>(&mut capy_vec), TreasuryAddress);
            i = i + 1;
        };
        vec::destroy_empty<Capy>(capy_vec);
        get_tokens_for_exchange(reserve, 
        TOKENS_PER_CAPY * capy_num, tx_context::sender(ctx), ctx);
    }

    #[test_only]
    public entry fun exchange_tokens_for_capy_test(capy_vec: vector<TestCapy>, reserve: &mut Reserve, ctx: &mut TxContext) {
        let capy_num = vec::length(&capy_vec);
        let i = 0u64;
        while (i < capy_num) {
            transfer::transfer(vec::pop_back<TestCapy>(&mut capy_vec), TreasuryAddress);
            i = i + 1;
        };
        vec::destroy_empty<TestCapy>(capy_vec);
        get_tokens_for_exchange(reserve, 
        TOKENS_PER_CAPY * capy_num, tx_context::sender(ctx), ctx);
    }

    fun get_tokens_for_exchange( reserve: &mut Reserve, 
        amount: u64, exchanged_address: address, ctx: &mut TxContext) {
        let cpw_balance_available = reserve_balance(reserve);
        assert!(amount <= cpw_balance_available, EInsufficientReserve);
        let balance_for_capy = get_reserve_balance_owned(reserve, amount);
        let tokens_for_capy = coin::from_balance(balance_for_capy, ctx);
        transfer::transfer(tokens_for_capy, exchanged_address);
    }

    public entry fun withdraw_tokens(_: &mut TreasuryCap<CPWTOKEN>, reserve: &mut Reserve, amount: u64, 
        ctx: &mut TxContext) {
        let cpw_balance = get_reserve_balance_owned(reserve, amount);
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