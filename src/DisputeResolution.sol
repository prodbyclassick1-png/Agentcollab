// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./ProjectRegistry.sol";
import "./TaskManager.sol";
import "./RevenueDistributor.sol";

/**
 * @title DisputeResolution
 * @notice Handle disputes between project owners and agents
 * @dev Provides mediation and resolution for failed tasks/projects
 */
contract DisputeResolution is Ownable, ReentrancyGuard {
    // ============ Enums ============
    
    enum DisputeStatus {
        Open,
        UnderReview,
        ResolvedForAgent,
        ResolvedForClient,
        Cancelled
    }
    
    enum DisputeType {
        TaskNotDelivered,
        QualityIssue,
        PaymentDispute,
        TimelineDispute,
        Other
    }

    // ============ Structs ============
    
    struct Dispute {
        uint256 id;
        uint256 projectId;
        uint256 taskId;
        address initiator;
        address respondent;
        DisputeType disputeType;
        string description;
        string evidence;
        DisputeStatus status;
        uint256 createdAt;
        uint256 resolvedAt;
        address arbiter;
        string resolution;
        uint256 refundAmount; // If any
    }

    // ============ State Variables ============
    
    ProjectRegistry public immutable projectRegistry;
    TaskManager public immutable taskManager;
    RevenueDistributor public immutable revenueDistributor;
    
    uint256 public nextDisputeId = 1;
    uint256 public constant DISPUTE_FEE = 10e6; // 10 USDC to prevent spam
    uint256 public constant MAX_RESOLUTION_TIME = 7 days;
    
    // Authorized arbiters
    mapping(address => bool) public isArbiter;
    address[] public arbiters;
    
    // Disputes
    mapping(uint256 => Dispute) public disputes;
    mapping(uint256 => uint256[]) public projectDisputes; // projectId => disputeIds
    mapping(uint256 => uint256[]) public taskDisputes;    // taskId => disputeIds
    
    // ============ Events ============
    
    event DisputeCreated(
        uint256 indexed disputeId,
        uint256 indexed projectId,
        uint256 indexed taskId,
        address initiator,
        DisputeType disputeType,
        uint256 timestamp
    );
    
    event DisputeAssigned(
        uint256 indexed disputeId,
        address indexed arbiter,
        uint256 timestamp
    );
    
    event DisputeResolved(
        uint256 indexed disputeId,
        DisputeStatus resolution,
        uint256 refundAmount,
        uint256 timestamp
    );
    
    event ArbiterAdded(address indexed arbiter);
    event ArbiterRemoved(address indexed arbiter);

    // ============ Modifiers ============
    
    modifier onlyArbiter() {
        require(isArbiter[msg.sender] || msg.sender == owner(), "Not authorized arbiter");
        _;
    }

    // ============ Constructor ============
    
    constructor(
        address _projectRegistry,
        address _taskManager,
        address _revenueDistributor
    ) Ownable(msg.sender) {
        require(_projectRegistry != address(0), "Invalid registry");
        require(_taskManager != address(0), "Invalid task manager");
        require(_revenueDistributor != address(0), "Invalid distributor");
        
        projectRegistry = ProjectRegistry(_projectRegistry);
        taskManager = TaskManager(_taskManager);
        revenueDistributor = RevenueDistributor(_revenueDistributor);
    }

    // ============ Core Functions ============
    
    /**
     * @notice Create a dispute
     * @param _projectId Project ID
     * @param _taskId Task ID (0 if project-level dispute)
     * @param _disputeType Type of dispute
     * @param _description Detailed description
     * @param _evidence Evidence/proof (IPFS hash, etc.)
     */
    function createDispute(
        uint256 _projectId,
        uint256 _taskId,
        DisputeType _disputeType,
        string calldata _description,
        string calldata _evidence
    ) external nonReentrant returns (uint256) {
        ProjectRegistry.Project memory project = projectRegistry.getProject(_projectId);
        require(project.id != 0, "Project does not exist");
        
        // Verify caller is involved in the project
        bool isOwner = project.owner == msg.sender;
        bool isTeamMember = projectRegistry.isTeamMember(_projectId, msg.sender);
        require(isOwner || isTeamMember, "Not involved in project");
        
        // Determine respondent
        address respondent = isOwner ? address(0) : project.owner; // If agent files, respondent is owner
        
        uint256 disputeId = nextDisputeId++;
        
        disputes[disputeId] = Dispute({
            id: disputeId,
            projectId: _projectId,
            taskId: _taskId,
            initiator: msg.sender,
            respondent: respondent,
            disputeType: _disputeType,
            description: _description,
            evidence: _evidence,
            status: DisputeStatus.Open,
            createdAt: block.timestamp,
            resolvedAt: 0,
            arbiter: address(0),
            resolution: "",
            refundAmount: 0
        });
        
        projectDisputes[_projectId].push(disputeId);
        if (_taskId > 0) {
            taskDisputes[_taskId].push(disputeId);
        }
        
        emit DisputeCreated(
            disputeId,
            _projectId,
            _taskId,
            msg.sender,
            _disputeType,
            block.timestamp
        );
        
        return disputeId;
    }
    
    /**
     * @notice Assign arbiter to dispute
     * @param _disputeId Dispute ID
     * @param _arbiter Arbiter address
     */
    function assignArbiter(uint256 _disputeId, address _arbiter) external onlyOwner {
        require(isArbiter[_arbiter], "Not an authorized arbiter");
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.status == DisputeStatus.Open, "Dispute not open");
        
        dispute.arbiter = _arbiter;
        dispute.status = DisputeStatus.UnderReview;
        
        emit DisputeAssigned(_disputeId, _arbiter, block.timestamp);
    }
    
    /**
     * @notice Resolve dispute (arbiter only)
     * @param _disputeId Dispute ID
     * @param _resolution Resolution status
     * @param _resolutionText Explanation
     * @param _refundAmount Refund amount (if any)
     */
    function resolveDispute(
        uint256 _disputeId,
        DisputeStatus _resolution,
        string calldata _resolutionText,
        uint256 _refundAmount
    ) external nonReentrant onlyArbiter {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.status == DisputeStatus.UnderReview, "Not under review");
        require(dispute.arbiter == msg.sender || msg.sender == owner(), "Not assigned arbiter");
        require(
            _resolution == DisputeStatus.ResolvedForAgent ||
            _resolution == DisputeStatus.ResolvedForClient,
            "Invalid resolution status"
        );
        
        dispute.status = _resolution;
        dispute.resolution = _resolutionText;
        dispute.refundAmount = _refundAmount;
        dispute.resolvedAt = block.timestamp;
        
        emit DisputeResolved(_disputeId, _resolution, _refundAmount, block.timestamp);
    }
    
    /**
     * @notice Cancel dispute (initiator only, before assignment)
     * @param _disputeId Dispute ID
     */
    function cancelDispute(uint256 _disputeId) external {
        Dispute storage dispute = disputes[_disputeId];
        require(dispute.initiator == msg.sender, "Not initiator");
        require(dispute.status == DisputeStatus.Open, "Cannot cancel");
        
        dispute.status = DisputeStatus.Cancelled;
    }

    // ============ Arbiter Management ============
    
    /**
     * @notice Add authorized arbiter
     * @param _arbiter Arbiter address
     */
    function addArbiter(address _arbiter) external onlyOwner {
        require(_arbiter != address(0), "Invalid address");
        require(!isArbiter[_arbiter], "Already arbiter");
        
        isArbiter[_arbiter] = true;
        arbiters.push(_arbiter);
        
        emit ArbiterAdded(_arbiter);
    }
    
    /**
     * @notice Remove arbiter
     * @param _arbiter Arbiter address
     */
    function removeArbiter(address _arbiter) external onlyOwner {
        require(isArbiter[_arbiter], "Not an arbiter");
        
        isArbiter[_arbiter] = false;
        
        // Remove from array
        for (uint256 i = 0; i < arbiters.length; i++) {
            if (arbiters[i] == _arbiter) {
                arbiters[i] = arbiters[arbiters.length - 1];
                arbiters.pop();
                break;
            }
        }
        
        emit ArbiterRemoved(_arbiter);
    }

    // ============ View Functions ============
    
    /**
     * @notice Get dispute details
     * @param _disputeId Dispute ID
     */
    function getDispute(uint256 _disputeId) external view returns (Dispute memory) {
        require(disputes[_disputeId].id != 0, "Dispute does not exist");
        return disputes[_disputeId];
    }
    
    /**
     * @notice Get all disputes for a project
     * @param _projectId Project ID
     */
    function getProjectDisputes(uint256 _projectId) external view returns (uint256[] memory) {
        return projectDisputes[_projectId];
    }
    
    /**
     * @notice Get all disputes for a task
     * @param _taskId Task ID
     */
    function getTaskDisputes(uint256 _taskId) external view returns (uint256[] memory) {
        return taskDisputes[_taskId];
    }
    
    /**
     * @notice Get all arbiters
     */
    function getArbiters() external view returns (address[] memory) {
        return arbiters;
    }
    
    /**
     * @notice Check if dispute is overdue for resolution
     * @param _disputeId Dispute ID
     */
    function isDisputeOverdue(uint256 _disputeId) external view returns (bool) {
        Dispute memory dispute = disputes[_disputeId];
        if (dispute.status != DisputeStatus.UnderReview) {
            return false;
        }
        return block.timestamp > dispute.createdAt + MAX_RESOLUTION_TIME;
    }
}
