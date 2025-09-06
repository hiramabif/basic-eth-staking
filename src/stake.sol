// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Stake {
    // Custom errors
    error Stake__StakeMore();
    error Stake__HasNotStaked();
    error Stake__NotEnoughStake();
    error Stake__StillLocked();
    error Stake__InsufficientContractBalance();
    error Stake__TransferFailed();
    error Stake__OnlyOwner();
    error Stake__ReentrancyGuard();

    // State variables
    uint256 public s_lockUpDuration;
    uint256 public s_interestRate; // in basis points (100 = 1%)
    uint256 public constant MINIMUM_STAKE = 1 ether;
    address public immutable i_owner;

    // Reentrancy guard
    bool private locked;

    // Events
    event Staked(address indexed staker, uint256 amount, uint256 timeStaked);
    event Unstaked(address indexed staker, uint256 amount, uint256 interest, uint256 timeUnstaked);
    event InterestRateUpdated(uint256 oldRate, uint256 newRate);

    // Staker struct
    struct Staker {
        uint256 amountStaked;
        uint256 timeStaked;
        uint256 timeCanUnstake;
        bool hasStaked;
    }

    mapping(address => Staker) public stakers;

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert Stake__OnlyOwner();
        }
        _;
    }

    modifier nonReentrant() {
        if (locked) {
            revert Stake__ReentrancyGuard();
        }
        locked = true;
        _;
        locked = false;
    }

    constructor(uint256 lockUpDuration, uint256 interestRate) {
        s_lockUpDuration = lockUpDuration;
        s_interestRate = interestRate; // e.g., 1000 = 10%
        i_owner = msg.sender;
    }

    function stake() external payable nonReentrant {
        if (msg.value < MINIMUM_STAKE) {
            revert Stake__StakeMore();
        }

        emit Staked(msg.sender, msg.value, block.timestamp);

        // Handle existing stakers vs new stakers
        if (stakers[msg.sender].hasStaked) {
            // Add to existing stake
            stakers[msg.sender].amountStaked += msg.value;
            // Update timing based on new total stake
            stakers[msg.sender].timeStaked = block.timestamp;
            stakers[msg.sender].timeCanUnstake = block.timestamp + s_lockUpDuration;
        } else {
            // New staker
            stakers[msg.sender] = Staker({
                amountStaked: msg.value,
                timeStaked: block.timestamp,
                timeCanUnstake: block.timestamp + s_lockUpDuration,
                hasStaked: true
            });
        }
    }

    function unstake(uint256 amount) external nonReentrant returns (bool) {
        Staker storage staker = stakers[msg.sender];

        if (!staker.hasStaked) {
            revert Stake__HasNotStaked();
        }

        if (amount > staker.amountStaked) {
            revert Stake__NotEnoughStake();
        }

        if (block.timestamp < staker.timeCanUnstake) {
            revert Stake__StillLocked();
        }

        // Calculate interest
        uint256 interest = _calculateRewards(msg.sender);
        uint256 payoutAmount = amount + interest;
        uint256 contractBalance = _getContractBalance();

        // Check contract has enough balance
        if (contractBalance < payoutAmount) {
            revert Stake__InsufficientContractBalance();
        }

        // Update staker data before transfer
        staker.amountStaked -= amount;

        // If they've unstaked everything, mark as not staked
        if (staker.amountStaked == 0) {
            staker.hasStaked = false;
        }

        emit Unstaked(msg.sender, amount, interest, block.timestamp);

        // Transfer funds
        (bool success,) = msg.sender.call{value: payoutAmount}("");
        if (!success) {
            revert Stake__TransferFailed();
        }

        return success;
    }

    function unstakeAll() external nonReentrant returns (bool) {
        Staker storage staker = stakers[msg.sender];

        if (!staker.hasStaked) {
            revert Stake__HasNotStaked();
        }

        if (block.timestamp < staker.timeCanUnstake) {
            revert Stake__StillLocked();
        }

        uint256 stakedAmount = staker.amountStaked;
        uint256 interest = _calculateRewards(msg.sender);
        uint256 payoutAmount = stakedAmount + interest;
        uint256 contractBalance = _getContractBalance();

        if (contractBalance < payoutAmount) {
            revert Stake__InsufficientContractBalance();
        }

        // Reset staker data
        staker.amountStaked = 0;
        staker.hasStaked = false;

        emit Unstaked(msg.sender, stakedAmount, interest, block.timestamp);

        (bool success,) = msg.sender.call{value: payoutAmount}("");
        if (!success) {
            revert Stake__TransferFailed();
        }

        return success;
    }

    // View functions
    function getStakerInfo(address stakerAddress) external view returns (Staker memory) {
        return stakers[stakerAddress];
    }

    function _calculateRewards(address stakerAddress) private view returns (uint256) {
        if (!stakers[stakerAddress].hasStaked) {
            return 0;
        }
        return (stakers[stakerAddress].amountStaked * s_interestRate) / 10000;
    }

    function _getTimeUntilUnlock(address stakerAddress) internal view returns (uint256) {
        if (!stakers[stakerAddress].hasStaked) {
            return 0;
        }

        if (block.timestamp >= stakers[stakerAddress].timeCanUnstake) {
            return 0;
        }

        return stakers[stakerAddress].timeCanUnstake - block.timestamp;
    }

    function _getContractBalance() internal view returns (uint256) {
        return address(this).balance;
    }

    // Owner functions
    function updateInterestRate(uint256 newInterestRate) external onlyOwner {
        uint256 oldRate = s_interestRate;
        s_interestRate = newInterestRate;
        emit InterestRateUpdated(oldRate, newInterestRate);
    }

    function fundContract() external payable onlyOwner {
        // Allow owner to add funds to pay interest
    }

    function emergencyWithdraw() external onlyOwner {
        // Emergency function - be careful with this in production
        (bool success,) = i_owner.call{value: address(this).balance}("");
        if (!success) {
            revert Stake__TransferFailed();
        }
    }

    // Fallback to accept ETH
    receive() external payable {}
}
