// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat/console.sol";

/******************************************/
/*       IERC20 starts here               */
/******************************************/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/******************************************/
/*       DemoAllocation starts here     */
/******************************************/

contract DemoAllocations {

    IERC20 public DEMO; 

    bool initialized;
    address internal deployer;
    uint256 public tickSize;

    mapping (address => Allocation[]) public allocations;

    struct Allocation {
        uint256 sharePerTick;
        uint256 lastWithdrawalBlock;
        uint256 unlockBlock;
        uint256 endBlock;
    }

    /**
     * @dev Populate allocations.
     */
    constructor() {
        
        deployer = msg.sender;

        uint256[] memory unlockBlocks = new uint[](6);
        uint256[] memory endBlocks = new uint[](6);

        // Cliff: 0 , Vest: 0
        unlockBlocks[0] = block.number;
        endBlocks[0] = block.number + 0;

        // Cliff: 0 , Vest: 0.01
        unlockBlocks[1] = block.number;
        endBlocks[1] = block.number + 4;

        // Cliff: 0 , Vest: 12
        unlockBlocks[2] = block.number;
        endBlocks[2] = block.number + 2340000;

        // Cliff: 0 , Vest: 18
        unlockBlocks[3] = block.number;
        endBlocks[3] = block.number + 3510000;
        
        // Cliff: 0 , Vest: 24
        unlockBlocks[4] = block.number;
        endBlocks[4] = block.number + 4680000;

        // Cliff: 3 , Vest: 18
        unlockBlocks[5] = block.number + 585000;
        endBlocks[5] = block.number + 3510000;

/******************************************/
/*            Cliff: 0 , Vest: 0          */
/******************************************/
/*

        allocations[0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266].push(Allocation({
            //tokensAtTGE: 0,
            //tokensAtTGEWithdrawn: true,
            sharePerTick: 10 * 1e18,
            lastWithdrawalBlock: block.number,
            unlockBlock: unlockBlocks[1],
            endBlock: endBlocks[1]
        }));

        allocations[0x70997970C51812dc3A010C7d01b50e0d17dc79C8].push(Allocation({
            //tokensAtTGE: 10 * 1e18,
            //tokensAtTGEWithdrawn: false,
            sharePerTick: 10 * 1e18,
            lastWithdrawalBlock: block.number,
            unlockBlock: block.number,
            endBlock: block.number
        }));
*/
        
        //tickSize = 5760;
        tickSize = 2;
    }

    function initialize(IERC20 _DEMO) external {
        require(initialized == false, "Already initialized.");
        require(msg.sender == deployer, "Only deployer.");
        initialized = true;
        DEMO = _DEMO;
    }

    function insertAlloc(address recipient, uint256 _sharePerTick, uint256 _unlockBlock, uint256 _endBlock) external {
        require(msg.sender == deployer, "Only deployer.");
        allocations[recipient].push(Allocation({
            sharePerTick: _sharePerTick * 2e18,
            lastWithdrawalBlock: _unlockBlock,
            unlockBlock: _unlockBlock,
            endBlock: _endBlock
        }));
    }

    /**
     * @dev Withdraw all unlocked shares.
     */
    function withdrawShare() external {
        uint256 unlockedShares;
        uint256 allocationsLength = allocations[msg.sender].length;
        for (uint256 i = 0; i < allocationsLength; i++) {
            if (allocations[msg.sender][i].lastWithdrawalBlock < allocations[msg.sender][i].endBlock && block.number >= allocations[msg.sender][i].unlockBlock) {
                uint256 distributionBlock;
                if (block.number > allocations[msg.sender][i].endBlock) {
                    distributionBlock = allocations[msg.sender][i].endBlock;
                } else {
                    distributionBlock = (block.number/tickSize)*tickSize;
                }
                console.log("Distribution block: %s", distributionBlock);
                uint256 tempLastWithdrawalBlock = allocations[msg.sender][i].lastWithdrawalBlock;
                allocations[msg.sender][i].lastWithdrawalBlock = distributionBlock;                    // Avoid reentrancy
                unlockedShares += allocations[msg.sender][i].sharePerTick * ((distributionBlock - tempLastWithdrawalBlock)/tickSize);
            }
        }
        console.log("Withdraw: %s tokens", unlockedShares/1e18);
        
        require(unlockedShares > 0, "No shares unlocked.");
        require(DEMO.balanceOf(address(this)) >= unlockedShares, "Not enough tokens on contract.");
        DEMO.transfer(msg.sender, unlockedShares);
    }

    /**
     * @dev Get the remaining balance of a shareholder's total outstanding shares.
     */
    function getOutstandingShares() external view returns(uint256) {
        uint256 outstandingShare;
        uint256 allocationsLength = allocations[msg.sender].length;
        for (uint256 i = 0; i < allocationsLength; i++) {
            outstandingShare += allocations[msg.sender][i].sharePerTick * ((allocations[msg.sender][i].endBlock - allocations[msg.sender][i].lastWithdrawalBlock)/tickSize);
            console.log("Outstanding share is %s tokens", outstandingShare/1e18);
        }
        return outstandingShare;
    }

    /**
     * @dev Get the balance of a shareholder's claimable shares.
     */
    function getUnlockedShares() external view returns(uint256) {
        uint256 unlockedShares;
        uint256 allocationsLength = allocations[msg.sender].length;
        for (uint256 i = 0; i < allocationsLength; i++) {
            if (allocations[msg.sender][i].lastWithdrawalBlock < allocations[msg.sender][i].endBlock && block.number >= allocations[msg.sender][i].unlockBlock) {
                uint256 distributionBlock;
                if (block.number > allocations[msg.sender][i].endBlock) {
                    distributionBlock = allocations[msg.sender][i].endBlock;
                } else {
                    distributionBlock = block.number;
                }
                console.log("Distributionblock: %s", distributionBlock);
                unlockedShares += allocations[msg.sender][i].sharePerTick * ((distributionBlock - allocations[msg.sender][i].lastWithdrawalBlock)/tickSize);
                console.log("UnlockedShares: %s", unlockedShares/1e18);
            }
        }
        return unlockedShares;
    }

    function getBalance() external view returns(uint256) {
        return DEMO.balanceOf(address(this));
    }

    /**
     * @dev Get the withdrawn shares of a shareholder.
     */
    function getWithdrawnShares() external view returns(uint256) {
        uint256 withdrawnShare;
        uint256 allocationsLength = allocations[msg.sender].length;
        for (uint256 i = 0; i < allocationsLength; i++) {
            withdrawnShare += allocations[msg.sender][i].sharePerTick * ((allocations[msg.sender][i].lastWithdrawalBlock - allocations[msg.sender][i].unlockBlock)/tickSize);
        }
        return withdrawnShare;
    }

    /**
     * @dev Get the total shares of shareholder.
     */
    function getTotalShares(address shareholder) external view returns(uint256) {
        uint256 totalShare;
        uint256 allocationsLength = allocations[shareholder].length;
        for (uint256 i = 0; i < allocationsLength; i++) {
            totalShare += allocations[shareholder][i].sharePerTick * ((allocations[shareholder][i].endBlock - allocations[shareholder][i].unlockBlock)/tickSize);
        }
        return totalShare;
    }
}