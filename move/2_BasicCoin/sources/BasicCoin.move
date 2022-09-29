module NamedAddr::BasicCoin {
    use std::signer;

    /// Address of the owner of this module
    const MODULE_OWNER: address = @NamedAddr;

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
    public fun publish_balance<CoinType>(account: &signer) {
        // TODO: add an assert to check that `account` doesn't already have a `Balance` resource.
        let pubAddress = signer::address_of(account);
        assert!(!exists<Balance<CoinType>>(pubAddress), EALREADY_HAS_BALANCE);

        let empty_coin = Coin<CoinType> { value: 0 };
        move_to(account, Balance<CoinType> { coin: empty_coin });
    }

    /// Initialize this module.
    public fun mint<CoinType>(module_owner: &signer, mint_addr: address, amount: u64) acquires Balance {
        // Only the owner of the module can initialize this module
        assert!(signer::address_of(module_owner) == MODULE_OWNER, ENOT_MODULE_OWNER);

        // Deposit `amount` of tokens to `mint_addr`'s balance
        deposit(mint_addr, Coin<CoinType> { value: amount });
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
        let check = withdraw(signer::address_of(from), amount);
        deposit<CoinType>(to, check);
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
    fun withdraw<CoinType>(addr: address, amount: u64) : Coin<CoinType> acquires Balance {
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
    fun deposit<CoinType>(_addr: address, check: Coin<CoinType>) acquires Balance {
        // TODO: follow the implementation of `withdraw` and implement me!
        let Coin<CoinType> { value: _amount } = check; // unpacks the check

        let balance_ref = &mut borrow_global_mut<Balance<CoinType>>(_addr).coin.value;
        *balance_ref = *balance_ref + _amount;
    }

    spec deposit {
        let balance = global<Balance<CoinType>>(addr).coin.value;
        let check_value = check.value;

        aborts_if !exists<Balance<CoinType>>(addr);
        aborts_if balance + check_value > MAX_U64;

        let post balance_post = global<Balance<CoinType>>(addr).coin.value;
        ensures balance_post == balance + check_value;
    }

    #[test(account = @0x1)] // Creates a signer for the `account` argument with address `@0x1`
    #[expected_failure] // This test should abort
    fun mint_non_owner<CoinType>(account: signer) acquires Balance {
        // Make sure the address we've chosen doesn't match the module
        // owner address
        publish_balance<CoinType>(&account);
        assert!(signer::address_of(&account) != MODULE_OWNER, 0);
        mint<CoinType>(&account, @0x1, 10);
    }

    // #[test(account = @NamedAddr)] // Creates a signer for the `account` argument with the value of the named address `NamedAddr`
    // fun mint_check_balance<CoinType>(account: signer) acquires Balance {
    //     let addr = signer::address_of(&account);
    //     publish_balance<CoinType>(&account);
    //     mint<CoinType>(&account, @NamedAddr, 42);
    //     assert!(balance_of<CoinType>(addr) == 42, 0);
    // }

    // #[test(account = @0x1)]
    // fun publish_balance_has_zero<CoinType>(account: signer) acquires Balance {
    //     let addr = signer::address_of(&account);
    //     publish_balance<CoinType>(&account);
    //     assert!(balance_of<CoinType>(addr) == 0, 0);
    // }

    // #[test(account = @0x1)]
    // #[expected_failure(abort_code = 2)] // Can specify an abort code
    // fun publish_balance_already_exists<CoinType>(account: signer) {
    //     publish_balance<CoinType>(&account);
    //     publish_balance<CoinType>(&account);
    // }

    #[test]
    #[expected_failure]
    fun balance_of_dne<CoinType>() acquires Balance {
        balance_of<CoinType>(@0x11);
    }

    #[test]
    #[expected_failure]
    fun withdraw_dne<CoinType>() acquires Balance {
        // Need to unpack the coin since `Coin` is a resource
        Coin<CoinType> { value: _ } = withdraw(@0x1, 0);
    }

    #[test(account = @0x1)]
    #[expected_failure] // This test should fail
    fun withdraw_too_much<CoinType>(account: signer) acquires Balance {
        let addr = signer::address_of(&account);
        publish_balance<CoinType>(&account);
        Coin<CoinType> { value: _ } = withdraw(addr, 1);
    }

    // #[test(account = @NamedAddr)]
    // fun can_withdraw_amount<CoinType>(account: signer) acquires Balance {
    //     publish_balance<CoinType>(&account);
    //     let amount = 1000;
    //     let addr = signer::address_of(&account);
    //     mint<CoinType>(&account, addr, amount);
    //     let Coin<CoinType> { value } = withdraw(addr, amount);
    //     assert!(value == amount, 0);
    // }
}