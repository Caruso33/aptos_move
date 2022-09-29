module Deployment::Vault {
    use std::signer;
    use Deployment::ManagedCoin;
    
    const MODULE_OWNER: address = @Owner;

    const ENOT_MODULE_OWNER: u64 = 0;
    const EVAULT_NOT_RUNNING: u64 = 1;
    
    struct VaultCoin has key, drop {
        value: u64,
     }

    struct VaultStatus has key {
        is_running: bool
    }

    public entry fun init(owner: &signer, amount: u64): u64 {
        require_is_owner(owner); 

        move_to(owner, VaultStatus { is_running: true });

        ManagedCoin::publish_balance<VaultCoin>(owner);

        let addr = signer::address_of(owner);
        ManagedCoin::mint<VaultCoin>(owner, addr, amount)
    }

    public fun init_account(owner: &signer, account: &signer) acquires VaultStatus {
        require_is_running();
        require_is_owner(owner); 

        ManagedCoin::publish_balance<VaultCoin>(account);
    }

    public fun balance_of(account: address): u64 {
        ManagedCoin::balance_of<VaultCoin>(account)
    }

    public fun mint(account: &signer, mint_addr: address, amount: u64) acquires VaultStatus {
        require_is_running();
        require_is_owner(account); 

        ManagedCoin::mint<VaultCoin>(account, mint_addr, amount);
    }

    public fun transfer(from: &signer, to: address, amount: u64) acquires VaultStatus {
        require_is_running();

        ManagedCoin::transfer<VaultCoin>(from, to, amount);
    }
    
    public fun pause(account: &signer) acquires VaultStatus {
        require_is_owner(account);

        let vault_status = borrow_global_mut<VaultStatus>(MODULE_OWNER);
        vault_status.is_running = false;
    }

    public fun unpause(account: &signer) acquires VaultStatus {
        require_is_owner(account);

        let vault_status = borrow_global_mut<VaultStatus>(MODULE_OWNER);
        vault_status.is_running = true;
    }

    fun require_is_running() acquires VaultStatus {
        let is_vault_status_running = borrow_global<VaultStatus>(MODULE_OWNER).is_running;
        assert!(is_vault_status_running, EVAULT_NOT_RUNNING);
    }

    fun require_is_owner(account: &signer) {
        assert!(signer::address_of(account) == MODULE_OWNER, ENOT_MODULE_OWNER);
    }

    /*
        TEST
    */

    // init
    #[test(owner = @Owner)]
    public fun module_can_initialize(owner: &signer) acquires VaultStatus {
        let addr = signer::address_of(owner);
        let amount = 10;

        let balance = init(owner, amount);

        assert!(balance == amount, 0);        

        let is_vault_status_running = borrow_global<VaultStatus>(addr).is_running;
        assert!(is_vault_status_running, EVAULT_NOT_RUNNING);
    }

    #[test(non_owner_account = @TestAccount)]
    #[expected_failure]
    public fun module_cant_initialize_by_nonowner(non_owner_account: &signer) {
        let amount = 10;

        init(non_owner_account, amount);
    }

    // init_account
    #[test(owner = @Owner, mint_account = @TestAccount)]
    public fun module_can_init_account_and_mint(owner: &signer, mint_account: &signer) acquires VaultStatus {
        let owner_addr = signer::address_of(owner);
        let mint_account_addr = signer::address_of(mint_account);

        let amount = 10;
        let mintAmount = 2;

        init(owner, amount);
        init_account(owner, mint_account);

        assert!(balance_of(owner_addr) == amount, 0);
        assert!(balance_of(mint_account_addr) == 0, 0);

        mint(owner, mint_account_addr, mintAmount);
        assert!(balance_of(mint_account_addr) == mintAmount, 0);
    }

    #[test(owner = @Owner, mint_account = @TestAccount)]
    #[expected_failure]
    public fun module_cant_mint_when_no_status(owner: &signer, mint_account: &signer) acquires VaultStatus {
        let addr = signer::address_of(mint_account);

        init(owner, 10);

        let is_vault_status_running = &mut borrow_global_mut<VaultStatus>(addr).is_running;
        *is_vault_status_running = false;

        let mint_account_addr = signer::address_of(mint_account);
        let mintAmount = 2;

        mint(owner, mint_account_addr, mintAmount);
    }

    #[test(owner = @Owner, account = @TestAccount)]
    #[expected_failure]
    public fun module_cant_init_account_twice<VaultCoin>(owner: &signer, account: &signer) acquires VaultStatus {
        init(owner, 10);

        init_account(owner, account);
        init_account(owner, account);
    }

    #[test(owner = @Owner, account = @TestAccount)]
    #[expected_failure]
    public fun module_cant_init_account_when_no_status<VaultCoin>(owner: &signer, account: &signer) acquires VaultStatus {
        let addr = signer::address_of(account);
        init(owner, 10);

        let is_vault_status_running = &mut borrow_global_mut<VaultStatus>(addr).is_running;
        *is_vault_status_running = false;

        init_account(owner, account);
    }

    #[test(owner = @Owner, account = @TestAccount)]
    public fun module_can_balance_of_and_transfer(owner: &signer, account: &signer) acquires VaultStatus {
        let addr_from = signer::address_of(owner);
        let addr_to = signer::address_of(account);
        
        let amount = 10;
        let transferAmount = 4;

        init(owner, amount);
        init_account(owner, account);

        let balance_from_before = balance_of(addr_from);
        let balance_to_before = balance_of(addr_to);

        assert!(balance_from_before == amount, 0);
        assert!(balance_to_before == 0, 0);

        transfer(owner, addr_to, transferAmount);

        let balance_from_after = balance_of(addr_from);
        let balance_to_after = balance_of(addr_to);

        assert!(balance_from_after == (amount - transferAmount), 0);
        assert!(balance_to_after == (0 + transferAmount), 0);
    }

    #[test(owner = @Owner, account = @TestAccount)]
    #[expected_failure]
    public fun module_cant_transfer_when_no_status(owner: &signer, account: &signer) acquires VaultStatus {
        let addr = signer::address_of(account);

        init(owner, 10);

        let is_vault_status_running = &mut borrow_global_mut<VaultStatus>(addr).is_running;
        *is_vault_status_running = false;

        let addr_to = signer::address_of(account);
        let transferAmount = 4;

        transfer(owner, addr_to, transferAmount);
    }

    #[test(owner = @Owner)]
    public fun module_can_pause(owner: &signer) acquires VaultStatus {
        let addr = signer::address_of(owner);

        init(owner, 10);

        let is_vault_status_running = borrow_global<VaultStatus>(addr).is_running;
        assert!(is_vault_status_running, 0);

        pause(owner);

        let is_vault_status_running = borrow_global<VaultStatus>(addr).is_running;
        assert!(!is_vault_status_running, 0);
    }

    #[test(owner = @Owner)]
    public fun module_can_unpause(owner: &signer) acquires VaultStatus {
        let addr = signer::address_of(owner);
        
        init(owner, 10);

        assert!(borrow_global<VaultStatus>(addr).is_running, 0);

        let is_vault_status_running = &mut borrow_global_mut<VaultStatus>(addr).is_running;
        *is_vault_status_running = false;

        assert!(!borrow_global<VaultStatus>(addr).is_running, 0);

        unpause(owner);

        let is_vault_status_running = borrow_global<VaultStatus>(addr).is_running;
        assert!(is_vault_status_running, 0);
    }
}