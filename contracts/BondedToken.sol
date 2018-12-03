pragma solidity ^0.4.23;

import "zeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "bancor-contracts/solidity/contracts/converter/BancorFormula.sol";

contract BondedToken is StandardToken, BancorFormula {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;

    uint32 public reserveRatio;  // represented in ppm, 1-1000000
    uint256 public virtualSupply;
    uint256 public virtualBalance;

    uint256 public poolBalance;

    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed burner, uint256 amount);
    event Buy(address indexed to, uint256 poolBalance, uint tokenSupply, uint256 amountTokens, uint256 totalCostEth);
    event Sell(address indexed from, uint256 poolBalance, uint tokenSupply, uint256 amountTokens, uint256 returnedEth);

    constructor (
        string _name,
        string _symbol,
        uint8 _decimals,
        uint32 _reserveRatio,
        uint256 _virtualSupply,
        uint256 _virtualBalance) public {
            
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        reserveRatio = _reserveRatio;
        virtualSupply = _virtualSupply;
        virtualBalance = _virtualBalance;
    }

    function() payable {}


    function getBuy(uint256 totalSupply, uint256 poolBalance, uint256 buyValue) public constant returns(uint256) {
        return calculatePurchaseReturn(
            safeAdd(totalSupply, virtualSupply),
            safeAdd(poolBalance, virtualBalance),
            reserveRatio,
            buyValue);
    }


    function getSell(uint256 totalSupply, uint256 poolBalance, uint256 sellAmount) public constant returns(uint256) {
        return calculateSaleReturn(
            safeAdd(totalSupply, virtualSupply),
            safeAdd(poolBalance, virtualBalance),
            reserveRatio,
            sellAmount);
    }

    /**
    * @dev buy Buy tokens for Eth
    * @param sender The recepient of bought tokens
    */
    function buy(address sender) public payable returns(bool) {
        require(msg.value > 0);
        uint256 tokens = getBuy(totalSupply_, poolBalance, msg.value);
        require(tokens > 0);
        require(_mint(sender, tokens));

        poolBalance = poolBalance.add(msg.value);
        this.transfer(msg.value);
        emit Buy(sender, poolBalance, totalSupply_, tokens, msg.value);
        return true;
    }

    /**
    * @dev sell Sell tokens for Eth
    * @param sellAmount The amount of tokens to sell
    */
    function sell(uint256 sellAmount) public returns(bool) {
        require(sellAmount > 0);
        require(balanceOf(msg.sender) >= sellAmount);

        uint256 saleReturn = getSell(totalSupply_, poolBalance, sellAmount);

        require(saleReturn > 0);
        require(saleReturn <= poolBalance);
        require(_burn(msg.sender, sellAmount));
        poolBalance = poolBalance.sub(saleReturn);

        msg.sender.transfer(saleReturn);

        emit Sell(msg.sender, poolBalance, totalSupply_, sellAmount, saleReturn);
        return true;
    }


    /// @dev                Mint new tokens with ether
    /// @param numTokens    The number of tokens you want to mint
    function _mint(address minter, uint256 numTokens) internal returns(bool){
        totalSupply_ = totalSupply_.add(numTokens);
        balances[minter] = balances[minter].add(numTokens);
        emit Mint(minter, numTokens);
        return true;
    }

    /// @dev                Burn tokens to receive ether
    /// @param burner         The number of tokens that you want to burn
    /// @param numTokens    The number of tokens that you want to burn
    function _burn(address burner, uint256 numTokens) internal returns(bool) {
        totalSupply_ = totalSupply_.sub(numTokens);
        balances[burner] = balances[burner].sub(numTokens);
        emit Burn(burner, numTokens);
        return true;
    }

}