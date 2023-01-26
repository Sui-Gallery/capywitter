module capywitter::capywittertest {
    use capywitter::cpwtoken::{Self};
    use capywitter::twitter::{Self};
    use sui::coin::{Self, Coin};
    use sui::test_scenario::{Self};
    use std::ascii::{Self};
    use std::vector as vec;

    const CAPY_OWNER: address = @0x1;
    const TOKENS_PER_CAPY: u64 = 10; 

    #[test]
    fun exchange_and_publish() {
        let scenario_val = test_scenario::begin(CAPY_OWNER);
        let scenario = &mut scenario_val;
        {
            let ctx = test_scenario::ctx(scenario);
            cpwtoken::test_init(ctx);
            twitter::test_init(ctx);
            cpwtoken::mint_capy(ctx);
        };
        test_scenario::next_tx(scenario, CAPY_OWNER);
        {
            let capy = test_scenario::take_from_address<cpwtoken::TestCapy>(scenario, CAPY_OWNER);
            let reserve = test_scenario::take_shared<cpwtoken::Reserve>(scenario);
            let ctx = test_scenario::ctx(scenario);
            let capy_vec = vec::empty<cpwtoken::TestCapy>();
            vec::push_back<cpwtoken::TestCapy>(&mut capy_vec, capy);
            cpwtoken::exchange_tokens_for_capy_test(capy_vec, &mut reserve, ctx);
            test_scenario::return_shared<cpwtoken::Reserve>(reserve);
        };
        test_scenario::next_tx(scenario, CAPY_OWNER);
        {
            let tokens = test_scenario::take_from_address<Coin<cpwtoken::CPWTOKEN>>(scenario, CAPY_OWNER);
            assert!(coin::value<cpwtoken::CPWTOKEN>(&tokens) == 10, 13);
            test_scenario::return_to_address<Coin<cpwtoken::CPWTOKEN>>(CAPY_OWNER, tokens);
        };
        test_scenario::next_tx(scenario, CAPY_OWNER);
        {
            let text_to_publish = ascii::string(b"hikmove is the greatest move dev!");
            let twitter = test_scenario::take_shared<twitter::Twitter>(scenario);
            let index = 1u8;
            let cpw_tokens = test_scenario::take_from_address<Coin<cpwtoken::CPWTOKEN>>(scenario, CAPY_OWNER);
            let ctx = test_scenario::ctx(scenario);
            let paid = coin::split(&mut cpw_tokens, 6, ctx);
            twitter::publish_text_by_index(&mut twitter, paid, text_to_publish, index, ctx);
            test_scenario::return_shared<twitter::Twitter>(twitter);
            test_scenario::return_to_address<Coin<cpwtoken::CPWTOKEN>>(CAPY_OWNER, cpw_tokens);
        };
        test_scenario::next_tx(scenario, CAPY_OWNER);
        {
            let twitter = test_scenario::take_shared<twitter::Twitter>(scenario);
            let index = 1u8;
            let text_published = twitter::get_text_by_slot_index(&mut twitter, index);
            assert!(ascii::into_bytes(text_published) == b"hikmove is the greatest move dev!", 14);
            test_scenario::return_shared<twitter::Twitter>(twitter);
        };
        test_scenario::end(scenario_val);
    } 
}