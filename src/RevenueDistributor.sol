// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ProjectRegistry.sol";
import "./TaskManager.sol";

/**
 * @title RevenueDistributor
 * @notice Handle payment splits and distributions for multi-agent projects
 * @dev Supports task-based payments and custom revenue splits
 */
contract RevenueDistributor is Ownable, ReentrancyGuard {
    // ============ Structs ============
    
    struct PaymentSplit {
        address agent;
        uint256 basisPoints;     // 10000 = 100%
    }
    
    struct EscrowBalance {
        uint256 totalDeposited;
        uint256 totalDistributed;
        uint256 platformFeeCollected;
    }

    // ============ State Variables ============
    
    ProjectRegistry public immutable projectRegistry;
    TaskManager public immutable taskManager;
    IERC20 public immutable usdc;
    
    address public platformTreasury;
    uint256 public constant BASIS_POINTS = 10000;
    
    // Project escrow balances
    mapping(uint256 => EscrowBalance) public projectBalances;
    
    // Agent earnings (withdrawable)
    mapping(address => uint256) public agentEarnings;
    
    // Custom project splits (if set, overrides task-based payments)
    mapping(uint256 => PaymentSplit[]) public projectSplits;
    mapping(uint256 => bool) public hasCustomSplit;
    
    // Track which tasks have been paid
    mapping(uint256 => bool) public taskPaid;
    
    // ============ Events ============
    
    event FundsDeposited(
        uint256 indexed projectId,
        address indexed depositor,
        uint256 amount,
        uint256 timestamp
    );
    
    event PaymentDistributed(
        uint256 indexed projectId,
        address indexed agent,
        uint256 amount,
        uint256 timestamp
    );
    
    event TaskPaymentReleased(
        uint256 indexed taskId,
        uint256 indexed projectId,
        address indexed agent,
        uint256 amount,
        uint256 platformFee,
        uint256 timestamp
    );
    
    event Withdrawn(
        address indexed agent,
        uint256 amount,
        uint256 timestamp
    );
    
    event CustomSplitSet(
        uint256 indexed projectId,
        uint256 agentCount,
        uint256 timestamp
    );

    // ============ Constructor ============
    
    constructor(
        address _projectRegistry,
        address _taskManager,
        address _usdc,
        address _platformTreasury
    ) Ownable(msg.sender) {
        require(_projectRegistry != address(0), "Invalid registry");
        require(_taskManager != address(0), "Invalid task manager");
        require(_usdc != address(0), "Invalid USDC");
        require(_platformTreasury != address(0), "Invalid treasury");
        
        projectRegistry = ProjectRegistry(_projectRegistry);
        taskManager = TaskManager(_taskManager);
        usdc = IERC20(_usdc);
        platformTreasury = _platformTreasury;
    }

    // ============ Core Functions ============
    
    /**
     * @notice Deposit funds into project escrow
     * @param _projectId Project ID
     * @param _amount Amount of USDC (6 decimals)
     */
    function depositFunds(uint256 _projectId, uint256 _amount) external nonReentrant {
        ProjectRegistry.Project memory project = projectRegistry.getProject(_projectId);
        require(project.owner == msg.sender, "Not project owner");
        require(_amount > 0, "Amount must be > 0");
        
        // Transfer USDC from depositor to this contract
        require(
            usdc.transferFrom(msg.sender, address(this), _amount),
            "USDC transfer failed"
        );
        
        projectBalances[_projectId].totalDeposited += _amount;
        
        emit FundsDeposited(_projectId, msg.sender, _amount, block.timestamp);
    }
    
    /**
     * @notice Release payment for a completed task
     * @param _taskId Task ID
     */
    function releaseTaskPayment(uint256 _taskId) external nonReentrant {
        require(!taskPaid[_taskId], "Task already paid");
        
        TaskManager.Task memory task = taskManager.getTask(_taskId);
        require(task.state == TaskManager.TaskState.Complete, "Task not complete");
        
        ProjectRegistry.Project memory project = projectRegistry.getProject(task.projectId);
        
        // Calculate platform fee
        uint256 platformFee = (task.paymentUSDC * project.platformFee) / BASIS_POINTS;
        uint256 agentPayment = task.paymentUSDC - platformFee;
        
        // Verify escrow has funds
        EscrowBalance storage balance = projectBalances[task.projectId];
        require(
            balance.totalDeposited >= balance.totalDistributed + task.paymentUSDC,
            "Insufficient escrow funds"
        );
        
        // Update balances
        balance.totalDistributed += task.paymentUSDC;
        balance.platformFeeCollected += platformFee;
        agentEarnings[task.assignedAgent] += agentPayment;
        taskPaid[_taskId] = true;
        
        emit TaskPaymentReleased(
            _taskId,
            task.projectId,
            task.assignedAgent,
            agentPayment,
            platformFee,
            block.timestamp
        );
    }
    
    /**
     * @notice Set custom revenue split for project (overrides task-based)
     * @param _projectId Project ID
     * @param _splits Array of payment splits
     */
    function setProjectSplit(
        uint256 _projectId,
        PaymentSplit[] calldata _splits
    ) external {
        ProjectRegistry.Project memory project = projectRegistry.getProject(_projectId);
        require(project.owner == msg.sender, "Not project owner");
        require(_splits.length > 0, "Empty splits");
        
        // Verify splits add up to 100%
        uint256 totalBps = 0;
        for (uint256 i = 0; i < _splits.length; i++) {
            require(_splits[i].agent != address(0), "Invalid agent");
            require(_splits[i].basisPoints > 0, "Invalid basis points");
            totalBps += _splits[i].basisPoints;
        }
        require(totalBps == BASIS_POINTS, "Splits must equal 100%");
        
        // Clear existing splits
        delete projectSplits[_projectId];
        
        // Set new splits
        for (uint256 i = 0; i < _splits.length; i++) {
            projectSplits[_projectId].push(_splits[i]);
        }
        
        hasCustomSplit[_projectId] = true;
        
        emit CustomSplitSet(_projectId, _splits.length, block.timestamp);
    }
    
    /**
     * @notice Distribute funds according to custom split (project complete)
     * @param _projectId Project ID
     */
    function distributeProjectFunds(uint256 _projectId) external nonReentrant {
        ProjectRegistry.Project memory project = projectRegistry.getProject(_projectId);
        require(project.state == ProjectRegistry.ProjectState.Complete, "Project not complete");
        require(hasCustomSplit[_projectId], "No custom split set");
        
        EscrowBalance storage balance = projectBalances[_projectId];
        uint256 availableFunds = balance.totalDeposited - balance.totalDistributed;
        require(availableFunds > 0, "No funds to distribute");
        
        // Calculate and subtract platform fee
        uint256 platformFee = (availableFunds * project.platformFee) / BASIS_POINTS;
        uint256 distributionPool = availableFunds - platformFee;
        
        PaymentSplit[] memory splits = projectSplits[_projectId];
        
        // Distribute to agents
        for (uint256 i = 0; i < splits.length; i++) {
            uint256 agentShare = (distributionPool * splits[i].basisPoints) / BASIS_POINTS;
            agentEarnings[splits[i].agent] += agentShare;
            
            emit PaymentDistributed(
                _projectId,
                splits[i].agent,
                agentShare,
                block.timestamp
            );
        }
        
        // Update balances
        balance.totalDistributed += availableFunds;
        balance.platformFeeCollected += platformFee;
    }
    
    /**
     * @notice Agent withdraws earnings
     */
    function withdraw() external nonReentrant {
        uint256 amount = agentEarnings[msg.sender];
        require(amount > 0, "No earnings to withdraw");
        
        agentEarnings[msg.sender] = 0;
        
        require(usdc.transfer(msg.sender, amount), "Transfer failed");
        
        emit Withdrawn(msg.sender, amount, block.timestamp);
    }
    
    /**
     * @notice Owner withdraws platform fees
     */
    function withdrawPlatformFees(uint256 _projectId) external onlyOwner nonReentrant {
        uint256 fees = projectBalances[_projectId].platformFeeCollected;
        require(fees > 0, "No fees to withdraw");
        
        projectBalances[_projectId].platformFeeCollected = 0;
        
        require(usdc.transfer(platformTreasury, fees), "Transfer failed");
    }

    // ============ View Functions ============
    
    /**
     * @notice Get project escrow balance
     * @param _projectId Project ID
     */
    function getProjectBalance(uint256 _projectId) 
        external 
        view 
        returns (EscrowBalance memory) 
    {
        return projectBalances[_projectId];
    }
    
    /**
     * @notice Get agent earnings
     * @param _agent Agent address
     */
    function getAgentEarnings(address _agent) external view returns (uint256) {
        return agentEarnings[_agent];
    }
    
    /**
     * @notice Get project splits
     * @param _projectId Project ID
     */
    function getProjectSplits(uint256 _projectId) 
        external 
        view 
        returns (PaymentSplit[] memory) 
    {
        return projectSplits[_projectId];
    }

    // ============ Admin Functions ============
    
    /**
     * @notice Update platform treasury address
     * @param _newTreasury New treasury address
     */
    function updateTreasury(address _newTreasury) external onlyOwner {
        require(_newTreasury != address(0), "Invalid address");
        platformTreasury = _newTreasury;
    }
    
    /**
     * @notice Emergency withdrawal for cancelled projects
     * @param _projectId Project ID
     * @dev Only project owner can withdraw from cancelled projects
     */
    function emergencyWithdraw(uint256 _projectId) external nonReentrant {
        ProjectRegistry.Project memory project = projectRegistry.getProject(_projectId);
        require(project.owner == msg.sender, "Not project owner");
        require(
            uint8(project.state) == uint8(ProjectRegistry.ProjectState.Cancelled),
            "Project not cancelled"
        );
        
        EscrowBalance storage balance = projectBalances[_projectId];
        uint256 remainingFunds = balance.totalDeposited - balance.totalDistributed;
        require(remainingFunds > 0, "No funds to withdraw");
        
        // Mark as distributed
        balance.totalDistributed += remainingFunds;
        
        // Transfer back to owner
        require(usdc.transfer(msg.sender, remainingFunds), "Transfer failed");
    }
    
    /**
     * @notice Check if emergency withdrawal is available
     * @param _projectId Project ID
     */
    function canEmergencyWithdraw(uint256 _projectId) external view returns (bool) {
        ProjectRegistry.Project memory project = projectRegistry.getProject(_projectId);
        if (uint8(project.state) != uint8(ProjectRegistry.ProjectState.Cancelled)) {
            return false;
        }
        
        EscrowBalance memory balance = projectBalances[_projectId];
        return balance.totalDeposited > balance.totalDistributed;
    }
}
