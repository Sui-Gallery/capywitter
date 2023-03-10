module capywitter::twitter {

    use std::ascii::{Self, String};
    use sui::object::{Self, UID};
    use sui::tx_context::{Self,TxContext};
    use capywitter::cpwtoken::{CPWTOKEN};
    use sui::coin::{Self, Coin};
    use sui::dynamic_field as df;
    use sui::transfer;
    use sui::event;

    const MAX_TEXT_SIZE: u64 = 150;
    const MIN_INDEX: u8 = 1;
    const MAX_INDEX: u8 = 10;
    const TreasuryAddress: address = @0xa9d371945967713688913649c0756db7dfbd5b03;

    //Errors

    const EInvalidIndex: u64 = 0;
    const EInsufficientPayment: u64 = 1;
    const ETooLongText: u64 = 2;

    // Events

    struct PublishEvent has copy, drop {
        text: String,
        index: u8,
        value: u64
    }

    fun init(ctx: &mut TxContext) {
        let uid = object::new(ctx);
        let twitter = Twitter {
            id: uid
        };
        let i: u8 = 1;
        while (i <= 10) {
            let slot = Slot {
                index: i,
                text: ascii::string(b""),
                minimum_fee: 5,
                edited_by: @0x2
            };
            df::add<u8, Slot>(&mut twitter.id, i, slot);
            i = i + 1u8;
        };
        transfer::share_object(twitter);
    }

    struct Twitter has key {
        id: UID
    }

    struct Slot has store {
        index: u8,
        text: String,
        minimum_fee: u64,
        edited_by: address
    }

    public entry fun publish_text_by_index(tw: &mut Twitter, paid: Coin<CPWTOKEN>, text: String, 
        index: u8, ctx: &mut TxContext) {
        assert!(index >= MIN_INDEX && index <= MAX_INDEX, EInvalidIndex);
        assert!(ascii::length(&text) <= MAX_TEXT_SIZE, ETooLongText);
        let paid_val = coin::value(&paid);
        let min_val = get_min_fee_by_slot_index(tw, index);
        assert!(paid_val > min_val, EInsufficientPayment);
        transfer::transfer(paid, TreasuryAddress);
        let slot_ref_mut = df::borrow_mut<u8, Slot>(&mut tw.id, index);
        edit_slot(slot_ref_mut, text, paid_val, tx_context::sender(ctx));
        event::emit(
            PublishEvent {
                text,
                index,
                value: paid_val
            }
        )
    }

    fun edit_slot(slot: &mut Slot, text: String, new_min_fee: u64, new_editor: address) {
        slot.text = text;
        slot.minimum_fee = new_min_fee;
        slot.edited_by = new_editor;
    }

    public fun get_text_by_slot_index(tw: &Twitter, index: u8): String {
        let slot_ref = df::borrow<u8, Slot>(&tw.id, index);
        *&slot_ref.text
    }

    public fun get_address_by_slot_index(tw: &Twitter, index: u8): address {
        let slot_ref = df::borrow<u8, Slot>(&tw.id, index);
        *&slot_ref.edited_by
    }

    public fun get_min_fee_by_slot_index(tw: &Twitter, index: u8): u64 {
        let slot_ref = df::borrow<u8, Slot>(&tw.id, index);
        *&slot_ref.minimum_fee
    }

    #[test_only]
    public fun test_init(ctx: &mut TxContext) {
        init(ctx);
    }
}