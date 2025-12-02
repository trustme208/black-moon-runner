 // SPDX-License-Identifier: MIT
 pragma solidity ^0.8.19;
 contract ProfileRegistry {
     mapping(address => string) private _usernameOf;
     mapping(string => address) private _ownerOfUsername;
     address public owner;
     event UsernameSet(address indexed user, string username);
     modifier onlyOwner() { require(msg.sender == owner, "not owner"); _; }
     constructor() { owner = msg.sender; }
     function usernameOf(address user) external view returns (string memory) { return _usernameOf[user]; }
     function ownerOfUsername(string calldata username) external view returns (address) { return _ownerOfUsername[username]; }
     function setUsername(string calldata username) external {
         require(bytes(username).length >= 2, "username too short");
         require(_ownerOfUsername[username] == address(0), "username taken");
         string memory prev = _usernameOf[msg.sender];
         if (bytes(prev).length != 0) { delete _ownerOfUsername[prev]; }
         _usernameOf[msg.sender] = username;
         _ownerOfUsername[username] = msg.sender;
         emit UsernameSet(msg.sender, username);
     }
     function adminRemoveUsername(address user) external onlyOwner {
         string memory prev = _usernameOf[user];
         if (bytes(prev).length != 0) {
             delete _ownerOfUsername[prev];
             delete _usernameOf[user];
         }
     }
 }
