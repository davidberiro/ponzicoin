// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./IPonziPool.sol";
import "./BEP20.sol";

// RevaToken with Governance.
contract PonziToken is BEP20('Ponzi Token', 'PONZI') {
    using SafeMath for uint;

    address ponziPool;
    address dev;

    constructor(address _ponziPool, address _dev) public {
        ponziPool = _ponziPool;
        dev = _dev;
    }

    //@dev See {BEP20-transfer}.
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        uint poolCut = amount.mul(2).div(100);
        uint devCut = amount.div(100);
        uint transferAmount = amount.sub(poolCut).sub(devCut);
        _transfer(_msgSender(), ponziPool, poolCut);
        _transfer(_msgSender(), dev, devCut);
        _transfer(_msgSender(), recipient, transferAmount);
        IPonziPool(ponziPool).notifyTransferFee(poolCut);
        return true;
    }

    // @dev Creates `_amount` token to `_to`. Must only be called by the owner.
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    // @dev Burns `_amount` token from `_from`. Must only be called by the owner.
    function burn(address _from, uint256 _amount) public onlyOwner {
        _burn(_from, _amount);
    }
}
