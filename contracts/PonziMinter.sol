pragma solidity ^0.6.12;

import './PonziToken.sol';
import './PriceFormula.sol';

contract PonziMinter {
    using SafeMath for uint;

    PonziToken public token;
    PriceFormula public priceFormula;

    uint32 public reserveRatio; // precision of 1000
    uint public deflationFactor;
    uint public deflationIncPerBlock;
    uint public deflationPrecision;

    uint lastUpdatedBlock;

    constructor(
      address _token,
      address _priceFormula,
      uint32 _reserveRatio,
      uint _deflationIncPerBlock,
      uint _deflationPrecision
    ) public {
        token = PonziToken(_token);
        priceFormula = PriceFormula(_priceFormula);
        reserveRatio = _reserveRatio;
        deflationIncPerBlock = _deflationIncPerBlock;
        deflationPrecision = _deflationPrecision;
        deflationFactor = _deflationPrecision; // deflationFactor = 1
        lastUpdatedBlock = block.number;
    }

    modifier updateDeflation() {
        if (block.number > lastUpdatedBlock) {
          uint blocksPassed = (block.number).sub(lastUpdatedBlock);
          deflationFactor = deflationFactor.add(blocksPassed.mul(deflationIncPerBlock));
          lastUpdatedBlock = block.number;
        }
        _;
    }

    function getPurchaseReturn(uint _depositAmount)
        public
        view
        returns (uint amount)
    {
        uint reserveBalance = address(this).balance;
        uint tokenSupply = token.totalSupply();
        uint origReturn = priceFormula.calculatePurchaseReturn(tokenSupply, reserveBalance, reserveRatio, _depositAmount);
        uint finalReturn = origReturn.mul(deflationPrecision).div(deflationFactor);
        return finalReturn;
    }

    function getSaleReturn(uint _sellAmount)
        public
        view
        returns (uint amount)
    {
        require(_sellAmount != 0 && _sellAmount <= token.balanceOf(msg.sender)); // validate input

        uint reserveBalance = address(this).balance;
        
        uint tokenSupply = token.totalSupply();
        uint origReturn = priceFormula.calculateSaleReturn(tokenSupply, reserveBalance, reserveRatio, _sellAmount);
        uint finalReturn = origReturn.mul(deflationFactor).div(deflationPrecision);
        return finalReturn;
    }

    function buy(uint _minReturn) public payable updateDeflation() returns (uint amount) {
        amount = getPurchaseReturn(msg.value);
        require(amount != 0 && amount >= _minReturn); // ensure the trade gives something in return and meets the minimum requested amount
        token.mint(msg.sender, amount); // issue new funds to the caller in the smart token
        return amount;
    }

    function sell(uint _sellAmount, uint _minReturn) public updateDeflation() returns (uint amount) {
        amount = getSaleReturn(_sellAmount);
        require(amount != 0 && amount >= _minReturn); // ensure the trade gives something in return and meets the minimum requested amount

        uint reserveBalance = address(this).balance;

        uint tokenSupply = token.totalSupply();
        require(amount < reserveBalance || _sellAmount == tokenSupply); // ensure that the trade will only deplete the reserve if the total supply is depleted as well
        token.burn(msg.sender, _sellAmount); // burn _sellAmount from the caller's balance in the smart token
        (msg.sender).transfer(amount);
        return amount;
    }

    // fallback
    fallback() external payable {
        if (token.owner() == address(this)) {
            buy(0);
        }
    }
}
