pragma solidity ^0.6.12;

import './SafeMath.sol';
import './BEP20.sol';

contract PonziMinter is IPonziMinter, PriceFormula {
    using SafeMath for uint;

    BEP20 public token;
    uint8 public reserveRatio;
    uint public deflationFactor;
    uint public deflationIncPerBlock;
    uint public deflationPrecision;

    constructor(
      address _token,
      uint8 _reserveRatio,
      uint _deflationFactor,
      uint _deflationIncPerBlock,
      uint _deflationPrecision
    ) public {
        token = BEP20(_token);
        reserveRatio = _reserveRatio;
        deflationFactor = _deflationFactor;
        deflationIncPerBlock = _deflationIncPerBlock;
        deflationPrecision = _deflationPrecision;
    }

    function getPurchaseReturn(uint _depositAmount)
        public
        constant
        returns (uint amount)
    {
        uint reserveBalance = address(this).balance;
        uint tokenSupply = token.totalSupply();
        uint origReturn = calculatePurchaseReturn(tokenSupply, reserveBalance, reserveRatio, _depositAmount);
        uint finalReturn = origReturn.mul(deflationPrecision).div(deflationFactor);
        return finalReturn;
    }

    function getSaleReturn(uint _sellAmount)
        public
        constant
        returns (uint amount)
    {
        require(_sellAmount != 0 && _sellAmount <= token.balanceOf(msg.sender)); // validate input

        uint reserveBalance = address(this).balance;
        
        uint tokenSupply = token.totalSupply();
        uint origReturn = calculateSaleReturn(tokenSupply, reserveBalance, reserveRatio, _sellAmount);
        uint finalReturn = origReturn.mul(deflationFactor).div(deflationPrecision);
        return finalReturn;
    }

    function buy(uint _minReturn) public payable returns (uint amount) {
        amount = getPurchaseReturn(msg.value);
        require(amount != 0 && amount >= _minReturn); // ensure the trade gives something in return and meets the minimum requested amount
        token.mint(msg.sender, amount); // issue new funds to the caller in the smart token
        return amount;
    }

    function sell(uint _sellAmount, uint _minReturn) public returns (uint amount) {
        amount = getSaleReturn(_sellAmount);
        require(amount != 0 && amount >= _minReturn); // ensure the trade gives something in return and meets the minimum requested amount

        uint reserveBalance = address(this).balance;

        uint tokenSupply = token.totalSupply();
        require(amount < reserveBalance || _sellAmount == tokenSupply); // ensure that the trade will only deplete the reserve if the total supply is depleted as well
        token.burn(msg.sender, _sellAmount); // burn _sellAmount from the caller's balance in the smart token
        address(msg.sender).send(amount);
        return amount;
    }

    // fallback
    function payable() returns (uint) {
        return buy(0);
    }
}
