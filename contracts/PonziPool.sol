// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/access/Ownable.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/IBEP20.sol";

contract PonziPool is Ownable {
    using SafeMath for uint256;

    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 timeDeposited; // Timestamp that user staked at
    }

    // Info of each time pool.
    struct PoolInfo {
        uint256 allocPoint;       // How many allocation points assigned to this pool. CAKEs to distribute per block.
        uint256 lockedTime;
    }

    IBEP20 public token;
    uint256 public rewardPerTokenStaked;
    uint256 public totalTokensStaked;
    uint256 public totalAllocPoint = 0;

    PoolInfo[] public poolInfo;
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    bool initialized = false;

    function initialize(address _token) public onlyOwner {
        require(!initialized);
        token = IBEP20(_token);
        initialized = true;
        addPool(1000, 1 days);
        addPool(2000, 2 days);
        addPool(4000, 1 weeks);
        addPool(8000, 3 weeks);
    }

    function addPool(uint256 allocPoint, uint256 lockedTime) private {
        poolInfo.push(PoolInfo({
            allocPoint: allocPoint,
            lockedTime: lockedTime
        }));
        totalAllocPoint = totalAllocPoint.add(allocPoint);
    }

    function notifyTransferFee(uint _amount) public {
        require(msg.sender == address(token), "only token");
        rewardPerTokenStaked = rewardPerTokenStaked.add(_amount.mul(1e12).div(totalTokensStaked));
    }

    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        user.timeDeposited = block.timestamp;

        uint256 accRewardPerShare = rewardPerTokenStaked.mul(pool.allocPoint).div(totalAllocPoint);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                token.transfer(msg.sender, pending);
            }
        }
        token.transferFrom(address(msg.sender), address(this), _amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(accRewardPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(block.timestamp.sub(user.timeDeposited) >= pool.lockedTime, "tokens still locked");

        uint256 accRewardPerShare = rewardPerTokenStaked.mul(pool.allocPoint).div(totalAllocPoint);
        uint256 pending = user.amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
        uint withdrawAmount = user.amount.add(pending);
        user.amount = 0;
        token.transfer(address(msg.sender), withdrawAmount);
        user.rewardDebt = user.amount.mul(accRewardPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, withdrawAmount);
    }

    event Deposit(address indexed user, uint256 pid, uint256 amount);
    event Withdraw(address indexed user, uint256 pid, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

}
