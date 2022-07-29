// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./BondingCurve.sol";

contract BondingBoldToken is BondingCurve, Ownable, ERC20, ERC20Votes {
    
    using SafeMath for uint256;

    uint256 public scale = 10**18;
    uint256 public reserveBalance = 10 * scale;
    uint256 public reserveRatio;

    event ContinuousMint(address _To, uint256 _amountMinted, uint256 _buyAmount);
    event ContinuousBurn(address _To, uint256 _amountMinted, uint256 _sellAmount);

    constructor(
        uint256 _reserveRatio
    ) 
        ERC20("BondingBoldToken", "BOLD")
        ERC20Permit("Bonding Token")
    { 
        reserveRatio = _reserveRatio;
        _mint(msg.sender, 1 * scale);
    }

    receive() external payable { 
        buy(msg.value);
    }

    function buy(uint256 value) public payable {
        require(value > 0, "Must send ether to buy tokens.");

        uint256 amount = calculatePurchaseReturn(totalSupply(), reserveBalance, uint32(reserveRatio), value);
        
        _mint(msg.sender, amount);
        
        emit ContinuousMint(msg.sender, amount, value);
    }

    function sell(uint256 amount) public payable {
        require(balanceOf(msg.sender) >= amount, "Insufficient tokens to burn.");

        uint256 value = calculateSaleReturn(totalSupply(), reserveBalance, uint32(reserveRatio), amount);

        _burn(msg.sender, amount);

        payable(msg.sender).transfer(value);

        emit ContinuousBurn(msg.sender, amount, value);
    }

    function _mint(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
        require(amount > 0, "Deposit must be non-zero.");
        
        super._mint(account, amount);
        reserveBalance = reserveBalance.add(amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20, ERC20Votes) {
        require(amount > 0, "Amount must be non-zero.");

        reserveBalance = reserveBalance.sub(amount);
        super._burn(account, amount);
    }
    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20) {
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