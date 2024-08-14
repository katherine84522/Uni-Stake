// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}


contract UniStake {

    struct Request {
        uint256 amount;
        uint256 targetBlock;
    }


    struct User {
        uint256 totalUniTokens;
        uint256 totalStakedTokens;
        uint256 pendingUnstakedTokens;
        Request[] requests;
    }

    User public user;

    struct Pool {
        address poolAddress;
        uint256 totalUniTokens;
        uint256 totalStakedTokens;
        uint256 minDepositAmount;
        uint256 unstakeLockedBlocks;
        mapping(address => user) allUsers; 
    }


    Pool public pool;
    mapping(uint => pool) allPools;
    mapping(address => uint) poolIDs;
    uint256[] public poolIDArray;

 
   IERC20 public token;

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    function stake(uint256 _pid, uint256 _amount) public {

        Pool storage pool = allPools[_pid];
        address poolAddress = pool.poolAddress;
        uint256 allowance = token.allowance(msg.sender, poolAddress);
        require(allowance >= _amount, "Insufficient allowance");

        uint256 minDepositAmount = pool.minDepositAmount;
        require(_amount < minDepositAmount, "Have to deposit at least" + minDepositAmount);

        pool.totalUniToken += _amount;
        pool.totalStakedTokens += _amount;

    }

    function unstake(uint256 _pid, uint _amount ) public {

        Pool storage pool = allPools[_pid];
        User storage user = pool.allUsers[msg.sender];
        uint256 stakedTokens = user.totalStakedTokens;

        require(stakedTokens >= _amount, "unsufficient staked tokens");

        user.totalStakedTokens -= _amount;
        
        uint256 targetBlock = block.number + unstakeLockedBlocks;
        Request storage newRequest;
        newRequest.targetBlock = targetBlock;
        newRequest.amount = _amount;
        user.requests.push(newRequest);
    }
 
    function withdraw(uint _pid) public {

        Pool storage pool = allPools[_pid];
        User storage user = pool.allUsers[msg.sender];
        require(user.requests.length > 0 && user.requests[0].targetBlock <= block.number);

        user.requests.pop();
    }

    function updatePool( address _stTokenAddress, uint256 _poolWeight, uint256 _minDepositAmount, uint256 _unstakLockedBlocks) public onlyManager{

        if(poolIDs[_stTokenAddress]){
            uint256 pid = pooIDs[_stTokenAddress];
            Pool storage pool = allPools[pid];

            pool.poolWeight = _poolWeight;
            pool.minDepositAmount = _minDepositAmount;
            pool.unstakeLockedBlocks = _unstakLockedBlocks;
        }else{

            uint256 latestPoolID = poolIDArray[poolIDArray.length -1];
            uint256 newPoolID = latestPoolID + 1;
            poolIDs[newPoolID] = _stTokenAddress;
            poolIDArray.push(newPoolID);

            Pool storage pool;
            pool.poolAddress = _stTokenAddress;
            pool.minDepositAmount = _minDepositAmount;
            pool.unstakeLockedBlocks = _unstakedLockedBlocks;

        }


    }

    modifier onlyManager(){

        require(msg.sender == manager, "Not manager");
        _;

    }
}
