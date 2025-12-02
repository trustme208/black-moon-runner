 // SPDX-License-Identifier: MIT
 pragma solidity ^0.8.19;
 import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
 import "@openzeppelin/contracts/access/Ownable.sol";
 contract WithdrawalPool is Ownable {
     IERC20 public immutable token;
     mapping(address => uint256) public lastWithdrawAt;
     uint256 public cooldownSeconds = 3600;
     uint256 public withdrawCap = 1000 * 1e18;
     event Withdraw(address indexed user, uint256 amount);
     constructor(address tokenAddr) { token = IERC20(tokenAddr); }
     function setCooldown(uint256 s) external onlyOwner { cooldownSeconds = s; }
     function setCap(uint256 cap) external onlyOwner { withdrawCap = cap; }
     function withdraw(uint256 amount) external {
         require(amount > 0, "zero");
         require(amount <= withdrawCap, "exceeds cap");
         require(block.timestamp >= lastWithdrawAt[msg.sender] + cooldownSeconds, "cooldown");
         lastWithdrawAt[msg.sender] = block.timestamp;
         require(token.transfer(msg.sender, amount), "transfer failed");
         emit Withdraw(msg.sender, amount);
     }
     function rescue(address to, uint256 amount) external onlyOwner { require(token.transfer(to, amount), "transfer failed"); }
 }
