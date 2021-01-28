pragma solidity ^0.6.11;

import "./Configurable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract MultiRewards is OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, Configurable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 constant _rewardsDistributor_ = "MR#rewardsDistributor";
    bytes32 constant _rewardsDuration_ = "MR#rewardsDuration";
    bytes32 constant _periodFinish_ = "MR#periodFinish";
    bytes32 constant _rewardRate_ = "MR#rewardRate";
    bytes32 constant _lastUpdateTime_ = "MR#lastUpdateTime";
    bytes32 constant _rewardPerTokenStored_ = "MR#rewardPerTokenStored";

    /* ========== STATE VARIABLES ========== */

    IERC20Upgradeable public stakingToken;
    address[] public rewardTokens;

    // user -> reward token -> amount
    mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;
    mapping(address => mapping(address => uint256)) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    /* ========== CONSTRUCTOR ========== */

//    constructor(
//        address _owner,
//        address _stakingToken
//    ) public Owned(_owner) {
//        stakingToken = IERC20Upgradeable(_stakingToken);
//    }

    function initialize(address _owner, address _stakingToken) public initializer {
        PausableUpgradeable.__Pausable_init();
        OwnableUpgradeable.__Ownable_init_unchained();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        stakingToken = IERC20Upgradeable(_stakingToken);
    }

    function addReward(
        address _rewardsToken,
        address _rewardsDistributor,
        uint256 _rewardsDuration
    )
    public
    onlyOwner
    {
        require(getConfig(_rewardsDuration_, _rewardsToken) == 0);
        rewardTokens.push(_rewardsToken);
        setConfigAddress(_rewardsDistributor_, _rewardsToken, _rewardsDistributor);
        setConfig(_rewardsDuration_, _rewardsToken, _rewardsDuration);
    }

    /* ========== VIEWS ========== */

    function setRewardsDistributor(address _rewardsToken, address _rewardsDistributor) external onlyOwner {
        setConfigAddress(_rewardsDistributor_, _rewardsToken, _rewardsDistributor);
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable(address _rewardsToken) public view returns (uint256) {
        return MathUpgradeable.min(block.timestamp, getConfig(_periodFinish_, _rewardsToken));
    }

    function rewardPerToken(address _rewardsToken) public view returns (uint256) {
        if (_totalSupply == 0) {
            return getConfig(_rewardPerTokenStored_, _rewardsToken);
        }
        return
        getConfig(_rewardPerTokenStored_, _rewardsToken).add(
            lastTimeRewardApplicable(_rewardsToken).sub(getConfig(_lastUpdateTime_, _rewardsToken)).mul(getConfig(_rewardRate_, _rewardsToken)).mul(1e18).div(_totalSupply)
        );
    }

    function earned(address account, address _rewardsToken) public view returns (uint256) {
        return _balances[account].mul(rewardPerToken(_rewardsToken).sub(userRewardPerTokenPaid[account][_rewardsToken])).div(1e18).add(rewards[account][_rewardsToken]);
    }

    function getRewardForDuration(address _rewardsToken) external view returns (uint256) {
        return getConfig(_rewardRate_, _rewardsToken).mul(getConfig(_rewardsDuration_, _rewardsToken));
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount) external nonReentrant whenNotPaused updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public nonReentrant updateReward(msg.sender) {

        for (uint i; i < rewardTokens.length; i++) {
            address _rewardsToken = rewardTokens[i];
            uint256 reward = rewards[msg.sender][_rewardsToken];
            if (reward > 0) {
                rewards[msg.sender][_rewardsToken] = 0;
                IERC20Upgradeable(_rewardsToken).safeTransfer(msg.sender, reward);
                emit RewardPaid(msg.sender, _rewardsToken, reward);
            }
        }
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(address _rewardsToken, uint256 reward) external updateReward(address(0)) {
        require(getConfigAddress(_rewardsDistributor_, _rewardsToken) == msg.sender);
        // handle the transfer of reward tokens via `transferFrom` to reduce the number
        // of transactions required and ensure correctness of the reward amount
        IERC20Upgradeable(_rewardsToken).safeTransferFrom(msg.sender, address(this), reward);

        if (block.timestamp >= getConfig(_periodFinish_, _rewardsToken)) {
            setConfig(_rewardRate_, _rewardsToken, reward.div(getConfig(_rewardsDuration_, _rewardsToken)));
        } else {
            uint256 remaining = getConfig(_periodFinish_, _rewardsToken).sub(block.timestamp);
            uint256 leftover = remaining.mul(getConfig(_rewardRate_, _rewardsToken));
            setConfig(_rewardRate_, _rewardsToken, reward.add(leftover).div(getConfig(_rewardsDuration_, _rewardsToken)));
        }

        setConfig(_lastUpdateTime_, _rewardsToken, block.timestamp);
        setConfig(_periodFinish_, _rewardsToken, block.timestamp.add(getConfig(_rewardsDuration_, _rewardsToken)));
        emit RewardAdded(reward);
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAddress != address(stakingToken), "Cannot withdraw the staking token");
        IERC20Upgradeable(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setRewardsDuration(address _rewardsToken, uint256 _rewardsDuration) external onlyOwner {
        require(
            block.timestamp > getConfig(_periodFinish_, _rewardsToken),
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        setConfig(_rewardsDuration_, _rewardsToken, _rewardsDuration);
        emit RewardsDurationUpdated(_rewardsToken, getConfig(_rewardsDuration_, _rewardsToken));
    }

    function rewardData(address token) public view returns (
        address rewardsDistributor,
        uint256 rewardsDuration,
        uint256 periodFinish,
        uint256 rewardRate,
        uint256 lastUpdateTime,
        uint256 rewardPerTokenStored
    ) {
        rewardsDistributor = getConfigAddress(_rewardsDistributor_, token);
        rewardsDuration = getConfig(_rewardsDuration_, token);
        periodFinish = getConfig(_periodFinish_, token);
        rewardRate = getConfig(_rewardRate_, token);
        lastUpdateTime = getConfig(_lastUpdateTime_, token);
        rewardPerTokenStored = getConfig(_rewardPerTokenStored_, token);
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        for (uint i; i < rewardTokens.length; i++) {
            address token = rewardTokens[i];

            setConfig(_rewardPerTokenStored_, token, rewardPerToken(token));
            setConfig(_lastUpdateTime_, token, lastTimeRewardApplicable(token));

            if (account != address(0)) {
                rewards[account][token] = earned(account, token);
                userRewardPerTokenPaid[account][token] = getConfig(_rewardPerTokenStored_, token);
            }
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, address indexed rewardsToken, uint256 reward);
    event RewardsDurationUpdated(address token, uint256 newDuration);
    event Recovered(address token, uint256 amount);
}
