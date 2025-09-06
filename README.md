# Ethereum Staking Contract

A minimalist, secure staking contract that allows users to stake ETH for a fixed lockup period and earn interest rewards.

## Features

- **Fixed Lockup Period**: Configurable lock duration set at deployment
- **Interest Rewards**: Configurable interest rate (set in basis points)
- **Partial Unstaking**: Users can unstake portions of their stake after lockup expires
- **Multiple Staking**: Users can add to existing stakes (resets lock period)
- **Reentrancy Protection**: Follows checks-effects-interactions pattern with additional modifier protection
- **Owner Controls**: Interest rate updates and emergency functions
- **Gas Optimized**: Uses storage pointers and internal functions for efficiency

## Contract Details

### State Variables
- `s_lockUpDuration`: Time in seconds that funds are locked
- `s_interestRate`: Interest rate in basis points (100 = 1%)
- `MINIMUM_STAKE`: Minimum staking amount (1 ETH)
- `i_owner`: Immutable owner address set at deployment

### Events
- `Staked(address indexed staker, uint256 amount, uint256 timeStaked)`
- `Unstaked(address indexed staker, uint256 amount, uint256 interest, uint256 timeUnstaked)`
- `InterestRateUpdated(uint256 oldRate, uint256 newRate)`

## Usage

### Deployment
```solidity
// Deploy with 30-day lockup and 10% interest rate
Stake stakingContract = new Stake(2592000, 1000);
```

### For Users

#### Stake ETH
```solidity
// Stake 2 ETH (minimum 1 ETH required)
stakingContract.stake{value: 2 ether}();
```

#### Unstake Funds
```solidity
// Unstake 1 ETH after lockup period expires
stakingContract.unstake(1 ether);

// Or unstake everything
stakingContract.unstakeAll();
```

#### Check Staking Info
```solidity
// Get staker details
(uint256 amount, uint256 timeStaked, uint256 unlockTime, bool hasStaked) = 
    stakingContract.getStakerInfo(userAddress);
```

### For Owner

#### Update Interest Rate
```solidity
// Set interest rate to 5% (500 basis points)
stakingContract.updateInterestRate(500);
```

#### Fund Contract
```solidity
// Add ETH to contract for interest payments
stakingContract.fundContract{value: 10 ether}();
```

## Security Features

### Reentrancy Protection
- Utilizes checks-effects-interactions pattern
- Additional `nonReentrant` modifier for extra security
- State updates occur before external calls

### Access Control
- Owner-only functions protected by `onlyOwner` modifier
- Immutable owner address prevents ownership transfer attacks

### Input Validation
- Minimum stake requirements
- Balance sufficiency checks
- Lock period enforcement

## Error Handling

Custom errors for gas efficiency:
- `Stake__StakeMore()`: Stake amount below minimum
- `Stake__HasNotStaked()`: User has no active stake
- `Stake__NotEnoughStake()`: Attempting to unstake more than staked
- `Stake__StillLocked()`: Attempting to unstake before lockup expires
- `Stake__InsufficientContractBalance()`: Contract lacks funds for payout
- `Stake__TransferFailed()`: ETH transfer failed
- `Stake__OnlyOwner()`: Function restricted to owner
- `Stake__ReentrancyGuard()`: Reentrancy attempt blocked

## Installation & Testing

### Prerequisites
- [Foundry](https://getfoundry.sh/) or [Hardhat](https://hardhat.org/)
- [Node.js](https://nodejs.org/) (if using Hardhat)

### Clone Repository
```bash
git clone <repository-url>
cd ethereum-staking-contract
```

### Install Dependencies
```bash
# For Foundry
forge install

# For Hardhat
npm install
```

### Compile Contract
```bash
# Foundry
forge build

# Hardhat
npx hardhat compile
```

### Run Tests
```bash
# Foundry
forge test

# Hardhat
npx hardhat test
```

## Deployment Parameters

When deploying, consider these parameters:

### Lock Duration Examples
- 1 day: `86400`
- 1 week: `604800`
- 30 days: `2592000`
- 1 year: `31536000`

### Interest Rate Examples (Basis Points)
- 1%: `100`
- 5%: `500`
- 10%: `1000`
- 20%: `2000`

## Important Considerations

### For Users
- **Lock Period**: Funds are locked for the specified duration
- **Multiple Stakes**: Adding to existing stake resets the entire lock period
- **Interest Calculation**: Interest is calculated on the full staked amount
- **Gas Costs**: Consider transaction fees when staking/unstaking small amounts

### For Contract Owner
- **Funding Required**: Contract must be funded with ETH to pay interest rewards
- **Interest Rate Changes**: Only affect new stakes, not existing ones
- **Emergency Function**: `emergencyWithdraw()` should be used with extreme caution

## Gas Optimization

This contract implements several gas optimization techniques:
- Storage pointers instead of repeated mapping lookups
- Internal functions for repeated calculations
- Custom errors instead of string reverts
- Minimal storage reads through caching

## License

MIT License - see LICENSE file for details

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add comprehensive tests for new features
4. Ensure all tests pass
5. Submit a pull request

## Disclaimer

This contract is provided as-is for educational and development purposes. While security best practices have been followed, this contract has not been audited. Use at your own risk in production environments.

Always conduct thorough testing and consider professional security audits before deploying to mainnet with real funds.