module capywitter::capy_exchange {
    use std::option;
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::balance::{Self, Balance};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, UID};
    use std::vector as vec;
    use capy::capy::Capy;
    use capywitter::cpwtoken::{Reserve, get_tokens_for_exchange};

    const TreasuryAddress: address = @0x92255b86c0740fc1e4cdf34c0a5edd34d00a8f5d;
    const TOKENS_PER_CAPY: u64 = 10;

    struct ExchangePermit {}

    public entry fun exchange_tokens_for_capy(capy_vec: vector<Capy>, reserve: &mut Reserve, ctx: &mut TxContext) {
        let capy_num = vec::length(&capy_vec);
        let i = 0u64;
        while (i < capy_num) {
            transfer::transfer(vec::pop_back<Capy>(&mut capy_vec), TreasuryAddress);
            i = i + 1;
        };
        vec::destroy_empty<Capy>(capy_vec);
        get_tokens_for_exchange(ExchangePermit {}, reserve, 
        TOKENS_PER_CAPY * capy_num, tx_context::sender(ctx), ctx);
    }


}