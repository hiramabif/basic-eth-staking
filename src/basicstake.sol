// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract Stake {
    error stake__StakeMore();
    error stake__HasNotStaked();
    error stake__NotEnoughStake();

    uint256 public s_lockUpDuration;
    uint256 public constant MINIMUM_STAKE = 1 ether;

    event Staked(address indexed staker, uint256 amount, uint256 timeStaked);
    event unStaked(address indexed staker, uint256 amount, uint256 timeUnstaked);

    // how do i keep track of the stakers?
    struct Staker {
        uint256 amountStaked;
        uint256 timeStaked;
        uint256 timeCanUnstake;
        bool hasStaked; // this will be necessary later for the unstake function
    }

    mapping(address => Staker) public stakers;

    constructor(uint256 lockUpDuration) {
        s_lockUpDuration = lockUpDuration;
    }

    function stake() external payable {
        // I want them to have a minimum amount to stake
        if (msg.value < MINIMUM_STAKE) {
            revert stake__StakeMore();
        }

        // let's emit an event here
        emit Staked(msg.sender, msg.value, block.timestamp);
        // Now i guess this is where I update their details in the mapping
        stakers[msg.sender] = Staker({
            amountStaked: msg.value,
            timeStaked: block.timestamp,
            timeCanUnstake: s_lockUpDuration + block.timestamp,
            hasStaked: true
        });
    }

    function unstake(uint256 amount) external returns (bool) {
        // first have to check if they have staked
        if (!stakers[msg.sender].hasStaked) {
            revert stake__HasNotStaked();
        }

        if (amount > stakers[msg.sender].amountStaked) {
            revert stake__NotEnoughStake();
        }

        if (block.timestamp < stakers[msg.sender].timeCanUnstake) {
            revert("You cannot unstake yet");
        }
        // uint256 payoutAmount = amount + (amount / 10); // 10% interest for now
        stakers[msg.sender].amountStaked -= amount;
        if (stakers[msg.sender].amountStaked == 0) {
            stakers[msg.sender].hasStaked = false;
        }
        emit unStaked(msg.sender, amount, block.timestamp);
        // Now we send the money back to the user
        (bool success,) = msg.sender.call{value: amount}("");

        return success;
    }
}
