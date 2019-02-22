pragma solidity ^0.4.1;
// Contract allows transfers in batching and holds user's ethers in storage.
contract Batching {

    mapping(address => uint) _balance;

    event BatchTransfer(address indexed from, address indexed to, uint256 value);

    // Check balance of accounts.
    function balanceOf(address addr) constant external returns (uint) {
        return _balance[addr];
    }

    // Deposit ether coins.
    function deposit() external payable {
        _balance[msg.sender] += msg.value;
    }

    // Withdraw ether coins.
    // Parameter "to" - Ethereum address where ether will be send.
    // If there is no one, message sender's address will be used.
    function withdraw(uint value, address to) external {
        // Check that a sender's balance of ether is sufficient.
        if (_balance[msg.sender] < value)
            revert();

        // Handle default value of `to` address.
        address target = (to != 0) ? to : msg.sender;

        _balance[msg.sender] -= value;

        // Try sending ether.
        // If it fails, revert the transaction.
        !target.transfer(value);
    }

    // It is used to send payments in batching by value and sender's balance.
    function batchTransfer(bytes32[] payments) external {
        uint balance = _balance[msg.sender];
        uint value = msg.value + balance;

        for (uint i = 0; i < payments.length; ++i) {
            // A payment includes compressed data:
            // first 96 bits (12 bytes) is a value,
            // next 160 bits (20 bytes) is an address.
            bytes32 payment = payments[i];
            address addr = address(payment);
            uint v = uint(payment) / 2**160;
            if (v > value)
                break;
            _balance[addr] += v;
            value -= v;
            BatchTransfer(msg.sender, addr, v);
        }

        if (value != balance) {
            // Keep the rest of value in sender's account.
            _balance[msg.sender] = value;
        }
    }
}
