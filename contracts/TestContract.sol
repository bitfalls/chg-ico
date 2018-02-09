pragma solidity ^0.4.18;

contract TestContract{
    // List of addresses who can purchase in pre-sale
    mapping(address => bool) public wl;
    address[] public wls;

    function whitelistAddresses(address[] users) external {
        for (uint i = 0; i < users.length; i++) {
            wl[users[i]] = true;
            wls.push(users[i]);
        }
    }
}