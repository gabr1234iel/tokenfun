// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
// import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
// import "@openzeppelin/contracts/access/AccessControl.sol";

contract Token is ERC20{

    address admin;

    constructor(string memory name, string memory symbol, uint initialMintValue) ERC20(name, symbol) {
        _mint(msg.sender, initialMintValue);
        admin = msg.sender;
    }

    function mint(uint amount, address to_recipient) external returns(uint) {
        require(msg.sender == admin, "Only admin can mint");
        _mint(to_recipient, amount);
        return 1;
    }
}
    