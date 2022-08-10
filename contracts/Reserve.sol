//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./BancorFormula.sol";
import "./Token.sol";
// import "./utils/ABDKMathQuad.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/// @title Reserve
/// @author Joshua Healey (@alpinelines) - Credit to: Carl Farterson (@carlfarterson) && Chris Robison (@cbobrobison)
contract Reserve is BancorFormula {

    using Address for address;

    uint256 private constant PRECISION= 10**18;

    /// @dev Reserve address
    address private immutable reserve; 

    /// @dev Token issued by the bonding curve
    Token private immutable token;
    /// @dev Token used as collateral for minting/burning the Token issued by the bonding curve
    // Token private immutable collateral;
    /// @dev Formula contract
    // BancorZeroFormula private immutable formula;

    /// @dev The ratio of how much collateral "backs" the total marketcap of the Token (eg, creates the shape of the curve)
    uint32 public immutable connectorWeight;
    /// @dev The intersecting price to mint or burn a Token when supply == PRECISION (eg, creates the slope of the curve)
    uint256 public immutable baseY;

    /// @dev The amount of collateral "backing" the total marketcap of the Token
    uint256 public connectorBalance = 0;

    bool private active = false;

    constructor(
        Token _token,
        uint32 _connectorWeight,
        uint256 _baseY
    ) payable {
        require(_connectorWeight <= 1000000 && _connectorWeight > 0 && msg.value > 0);
        reserve = address(this);
        connectorBalance += msg.value;
        token = _token;
        connectorWeight = _connectorWeight;
        baseY = _baseY;
    }

    receive () external payable {
        uint256 supply = token.totalSupply();

        uint256 tokensReturned = calculatePurchaseReturn(
            supply,
            connectorBalance,
            connectorWeight,
            msg.value
        );

        require(tokensReturned != 0, "#buy(): not enough ether.");

        connectorBalance += msg.value;

        token.mint(msg.sender, tokensReturned);
        
        payable(msg.sender).transfer(
            msg.value - calculateSaleReturn(
                supply + tokensReturned,
                connectorBalance,
                connectorWeight,
                tokensReturned
            )
        );
    }

    function buy() public payable returns (uint256 tokensReturned) {
        uint256 supply = token.totalSupply();

        tokensReturned = calculatePurchaseReturn(
            supply,
            connectorBalance,
            connectorWeight,
            msg.value
        );

        connectorBalance += msg.value;

        token.mint(msg.sender, tokensReturned);
        
        payable(msg.sender).transfer(
            msg.value - calculateSaleReturn(
                supply + tokensReturned,
                connectorBalance,
                connectorWeight,
                tokensReturned
            )
        );

        return tokensReturned;
    }

    function sell(
        uint256 tokensBurned
    ) external payable returns (uint256 valueReturned) {
        uint256 supply = token.totalSupply();

        valueReturned = calculateSaleReturn(
            supply,
            connectorBalance,
            connectorWeight,
            tokensBurned
        );

        connectorBalance -= valueReturned;
        
        token.burn(msg.sender, tokensBurned);

        payable(msg.sender).transfer(valueReturned);
    }
}