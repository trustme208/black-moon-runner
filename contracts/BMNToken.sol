 // SPDX-License-Identifier: MIT
 pragma solidity ^0.8.19;
 import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
 import "@openzeppelin/contracts/access/Ownable.sol";
 contract BMNToken is ERC20, Ownable {
     constructor(uint256 initialSupply) ERC20("BlackMoon", "BMN") {
         if (initialSupply > 0) { _mint(msg.sender, initialSupply); }
     }
     function mint(address to, uint256 amount) external onlyOwner { _mint(to, amount); }
 }
