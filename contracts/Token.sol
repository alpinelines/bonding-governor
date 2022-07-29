// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title Token
/// @author Joshua Healey (@alpinelines) - Credit to: Carl Farterson (@carlfarterson) && Chris Robison (@cbobrobison)
contract Token is ERC20, ERC20Burnable, ERC20Votes, AccessControl {
    string public version;

    bytes32 public constant VAULT_ROLE = keccak256("VAULT_ROLE");

    constructor() ERC20("Bonding Token", "BTX") ERC20Permit("Bonding Token") {
        version = "0.2";
    }

    function setVault(address vault) public {
        require(hasRole(VAULT_ROLE, msg.sender), "ACCESS_CONTROL: function requires ADMIN_ROLE");
        grantRole(VAULT_ROLE, vault);
    }

    function mint(address to, uint256 amount) external {
        require(hasRole(VAULT_ROLE, msg.sender), "ACCESS_CONTROL: function requires ADMIN_ROLE");
        _mint(to, amount);
    }

    function burn(address from, uint256 value) external {
        require(hasRole(VAULT_ROLE, msg.sender), "ACCESS_CONTROL: function requires ADMIN_ROLE");
        _burn(from, value);
    }

    function _mint(address to, uint256 amount) internal override(ERC20, ERC20Votes) {
        require(hasRole(VAULT_ROLE, msg.sender), "ACCESS_CONTROL: function requires ADMIN_ROLE");
        ERC20Votes._mint(to, amount);
    }

    function _burn(address from, uint256 value) internal override(ERC20, ERC20Votes) {
        require(hasRole(VAULT_ROLE, msg.sender), "ACCESS_CONTROL: function requires ADMIN_ROLE");
        ERC20Votes._burn(from, value);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }
}