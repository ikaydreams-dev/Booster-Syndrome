// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BoosterToken {
    string public name = "Booster Token";
    string public symbol = "BST";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(uint256 _initialSupply) {
        owner = msg.sender;
        totalSupply = _initialSupply * 10 ** uint256(decimals);
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Cannot transfer to zero address");
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Cannot transfer to zero address");
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(allowance[_from][msg.sender] >= _value, "Allowance exceeded");

        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    function mint(address _to, uint256 _value) public onlyOwner returns (bool success) {
        require(_to != address(0), "Cannot mint to zero address");

        totalSupply += _value;
        balanceOf[_to] += _value;

        emit Mint(_to, _value);
        emit Transfer(address(0), _to, _value);
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");

        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;

        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
        return true;
    }
}

contract UserRewards {
    BoosterToken public token;
    address public owner;

    mapping(address => uint256) public userPoints;
    mapping(address => uint256) public lastRewardClaim;

    uint256 public pointsToTokenRate = 100;
    uint256 public rewardCooldown = 1 days;

    event PointsEarned(address indexed user, uint256 points);
    event RewardClaimed(address indexed user, uint256 tokens);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    constructor(address _tokenAddress) {
        token = BoosterToken(_tokenAddress);
        owner = msg.sender;
    }

    function earnPoints(address _user, uint256 _points) external onlyOwner {
        userPoints[_user] += _points;
        emit PointsEarned(_user, _points);
    }

    function claimReward() external {
        require(userPoints[msg.sender] >= pointsToTokenRate, "Not enough points");
        require(block.timestamp >= lastRewardClaim[msg.sender] + rewardCooldown, "Cooldown period");

        uint256 tokensToMint = userPoints[msg.sender] / pointsToTokenRate;
        userPoints[msg.sender] %= pointsToTokenRate;

        token.mint(msg.sender, tokensToMint);
        lastRewardClaim[msg.sender] = block.timestamp;

        emit RewardClaimed(msg.sender, tokensToMint);
    }

    function getClaimableTokens(address _user) external view returns (uint256) {
        return userPoints[_user] / pointsToTokenRate;
    }
}
