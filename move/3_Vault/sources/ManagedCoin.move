module Deployment::ManagedCoin {
    use std::signer;

    /// Address of the owner of this module
    const MODULE_OWNER: address = @Owner;

    /// Error codes
    const ENOT_MODULE_OWNER: u64 = 0;
    const EINSUFFICIENT_BALANCE: u64 = 1;
    const EALREADY_HAS_BALANCE: u64 = 2;

    struct Coin<phantom CoinType> has store {
        value: u64,
    }

    /// Struct representing the balance of each address.
    struct Balance<phantom CoinType> has key {
        coin: Coin<CoinType>
    }

    /// Publish an empty balance resource under `account`'s address. This function must be called before
    /// minting or transferring to the account.
    public fun publish_balance<CoinType>(account: &signer) :() {
        let addr = signer::address_of(account);
        assert!(!exists<Balance<CoinType>>(addr), EALREADY_HAS_BALANCE);

        let empty_coin = Coin<CoinType> { value: 0 };
        move_to(account, Balance<CoinType> { coin: empty_coin });
    }

    /// Initialize this module.
    public fun mint<CoinType>(module_owner: &signer, mint_addr: address, amount: u64): u64 acquires Balance {
        // Only the owner of the module can initialize this module
        assert!(signer::address_of(module_owner) == MODULE_OWNER, ENOT_MODULE_OWNER);

        // Deposit `amount` of tokens to `mint_addr`'s balance
        deposit<CoinType>(mint_addr, Coin<CoinType> { value: amount })
    }

    /// Returns the balance of `owner`.
    public fun balance_of<CoinType>(owner: address): u64 acquires Balance {
        borrow_global<Balance<CoinType>>(owner).coin.value
    }

    spec balance_of {
        pragma aborts_if_is_strict;
        aborts_if !exists<Balance<CoinType>>(owner);
    }

    /// Transfers `amount` of tokens from `from` to `to`.
    public fun transfer<CoinType: drop>(from: &signer, to: address, amount: u64) acquires Balance {
        let withdrawn_coin = withdraw(signer::address_of(from), amount);
        deposit<CoinType>(to, withdrawn_coin);
    }

    spec transfer {
        let addr_from = signer::address_of(from);

        let balance_from = global<Balance<CoinType>>(addr_from).coin.value;
        let balance_to = global<Balance<CoinType>>(to).coin.value;
        let post balance_from_post = global<Balance<CoinType>>(addr_from).coin.value;
        let post balance_to_post = global<Balance<CoinType>>(to).coin.value;

        ensures balance_from_post == balance_from - amount;
        ensures balance_to_post == balance_to + amount;
    }

    /// Withdraw `amount` number of tokens from the balance under `addr`.
    fun withdraw<CoinType>(addr: address, amount: u64): Coin<CoinType> acquires Balance {
        let balance = balance_of<CoinType>(addr);
        // balance must be greater than the withdraw amount
        assert!(balance >= amount, EINSUFFICIENT_BALANCE);
        let balance_ref = &mut borrow_global_mut<Balance<CoinType>>(addr).coin.value;
        *balance_ref = balance - amount;
        Coin<CoinType> { value: amount }
    }

    spec withdraw {
        let balance = global<Balance<CoinType>>(addr).coin.value;

        aborts_if !exists<Balance<CoinType>>(addr);
        aborts_if balance < amount;

        let post balance_post = global<Balance<CoinType>>(addr).coin.value;
        ensures result == Coin<CoinType> { value: amount };
        ensures balance_post == balance - amount;
    }

    /// Deposit `amount` number of tokens to the balance under `addr`.
    fun deposit<CoinType>(addr: address, coin: Coin<CoinType>): u64 acquires Balance {
        let Coin<CoinType> { value: amount } = coin; // unpacks the coin

        let balance_ref = &mut borrow_global_mut<Balance<CoinType>>(addr).coin.value;
        *balance_ref = *balance_ref + amount;

        *balance_ref
    }

    spec deposit {
        let balance = global<Balance<CoinType>>(addr).coin.value;
        let check_value = check.value;

        aborts_if !exists<Balance<CoinType>>(addr);
        aborts_if balance + check_value > MAX_U64;

        let post balance_post = global<Balance<CoinType>>(addr).coin.value;
        ensures balance_post == balance + check_value;
    }

    /*
        TEST
    */
    #[test_only]
    struct TestCoin has drop {
        value: u64,
    }

    // minting
    #[test(account = @Deployment)] // Creates a signer for the `account` argument with address `@0x1`
    #[expected_failure] // This test should abort
    fun mint_non_owner(account: &signer) acquires Balance {
        // Make sure the address we've chosen doesn't match the module
        // owner address
        publish_balance<TestCoin>(account);
        assert!(signer::address_of(account) != MODULE_OWNER, 0);
        mint<TestCoin>(account, @0x1, 10);
    }

    #[test(module_owner = @Owner, account = @TestAccount)] // Creates a signer for the `account` argument with the value of the named address `Owner`
    fun mint_check_balance(module_owner: &signer, account: &signer) acquires Balance {
        let addr = signer::address_of(account);
        let amount = 42;
        publish_balance<TestCoin>(account);
        
        let balance = mint<TestCoin>(module_owner, addr, amount);
        assert!(balance == amount, 0);
        assert!(balance_of<TestCoin>(addr) == amount, 0);
    }

    // publish balance
    #[test(account = @Deployment)]
    fun publish_balance_has_zero(account: &signer) acquires Balance {
        let addr = signer::address_of(account);
        publish_balance<TestCoin>(account);
        assert!(balance_of<TestCoin>(addr) == 0, 0);
    }

    #[test(account = @Deployment)]
    #[expected_failure(abort_code = 2)] // Can specify an abort code
    fun publish_balance_already_exists(account: &signer) {
        publish_balance<TestCoin>(account);
        publish_balance<TestCoin>(account);
    }

    // balance of
    #[test]
    #[expected_failure]
    fun balance_of_dne() acquires Balance {
        balance_of<TestCoin>(@0x11);
    }

    // transfer
    #[test(module_owner = @Owner, account = @TestAccount)]
    fun transfer_amount(module_owner: &signer, account: &signer) acquires Balance {
        let owner_addr = signer::address_of(module_owner);
        let account_addr = signer::address_of(account);

        let amount = 100;
        let transfer_amount = 30;

        publish_balance<TestCoin>(module_owner);
        publish_balance<TestCoin>(account);

        mint<TestCoin>(module_owner, owner_addr, amount);

        transfer<TestCoin>(module_owner, account_addr, transfer_amount);
        assert!(balance_of<TestCoin>(owner_addr) == (amount - transfer_amount), 0);
        assert!(balance_of<TestCoin>(account_addr) == transfer_amount, 0);
    }

    // withdraw
    #[test]
    #[expected_failure]
    fun withdraw_dne() acquires Balance {
        // Need to unpack the coin since `Coin` is a resource
        Coin<TestCoin> { value: _ } = withdraw(@0x1, 0);
    }

    #[test(account = @Deployment)]
    #[expected_failure] // This test should fail
    fun withdraw_too_much(account: &signer) acquires Balance {
        let addr = signer::address_of(account);
        publish_balance<TestCoin>(account);
        Coin<TestCoin> { value: _ } = withdraw(addr, 1);
    }

    #[test(account = @Owner)]
    fun can_withdraw_amount(account: &signer) acquires Balance {
        publish_balance<TestCoin>(account);
        let amount = 1000;
        let addr = signer::address_of(account);
        
        mint<TestCoin>(account, addr, amount);
        assert!(balance_of<TestCoin>(addr) == amount, 0);

        let Coin<TestCoin> { value } = withdraw<TestCoin>(addr, amount);
        assert!(value == amount, 0);
        assert!(balance_of<TestCoin>(addr) == 0, 0);
    }

    #[test(account = @Owner)]
    fun can_withdraw_some_amount(account: &signer) acquires Balance {
        publish_balance<TestCoin>(account);
        let amount = 1000;
        let withdraw_amount = 200;
        let addr = signer::address_of(account);

        mint<TestCoin>(account, addr, amount);
        assert!(balance_of<TestCoin>(addr) == amount, 0);
        
        let Coin<TestCoin> { value } = withdraw(addr, withdraw_amount);

        assert!(value == withdraw_amount, 0);
        assert!(balance_of<TestCoin>(addr) == (amount - withdraw_amount), 0);
    }

    // e2e
    #[test(module_owner = @Owner, account = @TestAccount)]
    fun can_e2e_perform(module_owner: &signer, account: &signer) acquires Balance {
        publish_balance<TestCoin>(module_owner);
        publish_balance<TestCoin>(account);

        let owner_amount = 1000;
        let account_amount = 500;

        let withdraw_amount = 200;
        let transfer_amount = 50;

        let owner_addr = signer::address_of(module_owner);
        let account_addr = signer::address_of(account);

        mint<TestCoin>(module_owner, owner_addr, owner_amount);
        mint<TestCoin>(module_owner, account_addr, account_amount);

        assert!(balance_of<TestCoin>(owner_addr) == owner_amount, 0);
        assert!(balance_of<TestCoin>(account_addr) == account_amount, 0);

        let Coin<TestCoin> { value } = withdraw<TestCoin>(account_addr, withdraw_amount);
        assert!(balance_of<TestCoin>(account_addr) == (account_amount - withdraw_amount), 0);        
        assert!(value == withdraw_amount, 0);

        let account_new_value = (account_amount - withdraw_amount + transfer_amount);
        transfer<TestCoin>(module_owner, account_addr, transfer_amount);
        assert!(balance_of<TestCoin>(owner_addr) == (owner_amount - transfer_amount), 0);
        assert!(balance_of<TestCoin>(account_addr) == account_new_value, 0);

        let owner_new_value = (owner_amount + transfer_amount);
        transfer<TestCoin>(account, owner_addr, 2 * transfer_amount);
        assert!(balance_of<TestCoin>(owner_addr) == owner_new_value, 0);
        assert!(balance_of<TestCoin>(account_addr) == (account_new_value - 2 * transfer_amount), 0);
    }
}