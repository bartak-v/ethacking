// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract MoneySafe {
    mapping(address => uint) public userBalances;
    bool internal re_lock;

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getUserBalance() public view returns (uint) {
        return userBalances[msg.sender];
    }

    function deposit() public payable {
        userBalances[msg.sender] =  userBalances[msg.sender] + msg.value;
    }

    modifier nonReentrant() {
        require(!re_lock, "Reentrancy detected.");
        re_lock = true;
        _;
        re_lock = false;
    }

    function withdrawBalance() public nonReentrant {
        // Withdraw the whole balance of user
        uint amountToWithdraw = userBalances[msg.sender];
        userBalances[msg.sender] = 0;
        (bool successfulWithdraw, ) = msg.sender.call{value:amountToWithdraw}("");
        require(successfulWithdraw, "Failed to withdraw ether");
    }

}

contract ReentrancyAttack {
    MoneySafe public safe;

    constructor(address _safeAddress) {
        safe = MoneySafe(_safeAddress);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    fallback() external payable {
        if (address(safe).balance >= 1 ether) {
            safe.withdrawBalance();
        }
    }

    function exploit() external payable {
        require(msg.value >= 1 ether); // Send atleast 1 ETH to the attack contract
        safe.deposit{value: 1 ether}(); // Deposit it in the MoneySafe
        safe.withdrawBalance(); // Withdraw it back from the MoneySafe
    }
}