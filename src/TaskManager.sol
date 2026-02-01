// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./ProjectRegistry.sol";

/**
 * @title TaskManager
 * @notice Create, assign, and track tasks within projects
 * @dev Tasks can have dependencies and must be completed in order
 */
contract TaskManager is Ownable, ReentrancyGuard {
    // ============ Enums ============
    
    enum TaskState {
        Open,        // Created but not assigned
        Assigned,    // Assigned to an agent
        InProgress,  // Agent working on it
        Review,      // Submitted for review
        Complete,    // Approved and complete
        Failed       // Rejected or failed
    }

    // ============ Structs ============
    
    struct Task {
        uint256 id;
        uint256 projectId;
        address assignedAgent;
        string title;
        string description;
        uint256 paymentUSDC;        // Payment for this specific task
        TaskState state;
        uint256 createdAt;
        uint256 assignedAt;
        uint256 completedAt;
        uint256 deadline;
        uint256[] dependencies;     // Task IDs that must complete first
        string deliverableHash;     // IPFS hash of deliverable
    }

    // ============ State Variables ============
    
    ProjectRegistry public immutable projectRegistry;
    uint256 public nextTaskId = 1;
    uint256 public totalTasks;
    
    mapping(uint256 => Task) public tasks;
    mapping(uint256 => uint256[]) public projectTasks; // projectId => taskIds
    mapping(address => uint256[]) public agentTasks;   // agent => taskIds
    
    // ============ Events ============
    
    event TaskCreated(
        uint256 indexed taskId,
        uint256 indexed projectId,
        string title,
        uint256 paymentUSDC,
        uint256 timestamp
    );
    
    event TaskAssigned(
        uint256 indexed taskId,
        address indexed agent,
        uint256 timestamp
    );
    
    event TaskStateChanged(
        uint256 indexed taskId,
        TaskState oldState,
        TaskState newState,
        uint256 timestamp
    );
    
    event TaskSubmitted(
        uint256 indexed taskId,
        address indexed agent,
        string deliverableHash,
        uint256 timestamp
    );
    
    event TaskApproved(
        uint256 indexed taskId,
        uint256 timestamp
    );
    
    event TaskRejected(
        uint256 indexed taskId,
        string reason,
        uint256 timestamp
    );

    // ============ Constructor ============
    
    constructor(address _projectRegistry) Ownable(msg.sender) {
        require(_projectRegistry != address(0), "Invalid registry");
        projectRegistry = ProjectRegistry(_projectRegistry);
    }

    // ============ Core Functions ============
    
    /**
     * @notice Create a new task
     * @param _projectId Project this task belongs to
     * @param _title Task title
     * @param _description Detailed description
     * @param _paymentUSDC Payment amount in USDC
     * @param _deadline Unix timestamp deadline
     * @param _dependencies Array of task IDs that must complete first
     */
    function createTask(
        uint256 _projectId,
        string calldata _title,
        string calldata _description,
        uint256 _paymentUSDC,
        uint256 _deadline,
        uint256[] calldata _dependencies
    ) external nonReentrant returns (uint256) {
        // Verify project exists and caller is owner
        ProjectRegistry.Project memory project = projectRegistry.getProject(_projectId);
        require(project.owner == msg.sender, "Not project owner");
        require(
            uint8(project.state) >= uint8(ProjectRegistry.ProjectState.Recruiting) &&
            uint8(project.state) <= uint8(ProjectRegistry.ProjectState.Active),
            "Invalid project state"
        );
        
        require(bytes(_title).length > 0 && bytes(_title).length <= 100, "Invalid title");
        require(bytes(_description).length <= 1000, "Description too long");
        require(_paymentUSDC > 0, "Payment must be > 0");
        require(_deadline > block.timestamp, "Deadline must be in future");
        
        // Verify dependencies exist
        for (uint256 i = 0; i < _dependencies.length; i++) {
            require(tasks[_dependencies[i]].id != 0, "Invalid dependency");
            require(tasks[_dependencies[i]].projectId == _projectId, "Dependency from different project");
        }
        
        uint256 taskId = nextTaskId++;
        
        tasks[taskId] = Task({
            id: taskId,
            projectId: _projectId,
            assignedAgent: address(0),
            title: _title,
            description: _description,
            paymentUSDC: _paymentUSDC,
            state: TaskState.Open,
            createdAt: block.timestamp,
            assignedAt: 0,
            completedAt: 0,
            deadline: _deadline,
            dependencies: _dependencies,
            deliverableHash: ""
        });
        
        projectTasks[_projectId].push(taskId);
        totalTasks++;
        
        emit TaskCreated(taskId, _projectId, _title, _paymentUSDC, block.timestamp);
        
        return taskId;
    }
    
    /**
     * @notice Assign task to an agent
     * @param _taskId Task ID
     * @param _agent Agent address
     */
    function assignTask(uint256 _taskId, address _agent) external nonReentrant {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "Task does not exist");
        
        ProjectRegistry.Project memory project = projectRegistry.getProject(task.projectId);
        require(project.owner == msg.sender, "Not project owner");
        require(task.state == TaskState.Open, "Task not open");
        require(projectRegistry.isTeamMember(task.projectId, _agent), "Agent not on team");
        
        // Check dependencies are complete
        require(_dependenciesComplete(_taskId), "Dependencies not complete");
        
        task.assignedAgent = _agent;
        task.assignedAt = block.timestamp;
        agentTasks[_agent].push(_taskId);
        
        _changeTaskState(_taskId, TaskState.Assigned);
        
        emit TaskAssigned(_taskId, _agent, block.timestamp);
    }
    
    /**
     * @notice Start working on assigned task
     * @param _taskId Task ID
     */
    function startTask(uint256 _taskId) external {
        Task storage task = tasks[_taskId];
        require(task.assignedAgent == msg.sender, "Not assigned to you");
        require(task.state == TaskState.Assigned, "Task not assigned");
        
        _changeTaskState(_taskId, TaskState.InProgress);
    }
    
    /**
     * @notice Submit completed task for review
     * @param _taskId Task ID
     * @param _deliverableHash IPFS hash of deliverable
     */
    function submitTask(uint256 _taskId, string calldata _deliverableHash) external {
        Task storage task = tasks[_taskId];
        require(task.assignedAgent == msg.sender, "Not assigned to you");
        require(task.state == TaskState.InProgress, "Task not in progress");
        require(bytes(_deliverableHash).length > 0, "Must provide deliverable");
        
        task.deliverableHash = _deliverableHash;
        _changeTaskState(_taskId, TaskState.Review);
        
        emit TaskSubmitted(_taskId, msg.sender, _deliverableHash, block.timestamp);
    }
    
    /**
     * @notice Approve completed task
     * @param _taskId Task ID
     */
    function approveTask(uint256 _taskId) external {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "Task does not exist");
        
        ProjectRegistry.Project memory project = projectRegistry.getProject(task.projectId);
        require(project.owner == msg.sender, "Not project owner");
        require(task.state == TaskState.Review, "Task not in review");
        
        task.completedAt = block.timestamp;
        _changeTaskState(_taskId, TaskState.Complete);
        
        emit TaskApproved(_taskId, block.timestamp);
    }
    
    /**
     * @notice Reject task submission
     * @param _taskId Task ID
     * @param _reason Rejection reason
     */
    function rejectTask(uint256 _taskId, string calldata _reason) external {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "Task does not exist");
        
        ProjectRegistry.Project memory project = projectRegistry.getProject(task.projectId);
        require(project.owner == msg.sender, "Not project owner");
        require(task.state == TaskState.Review, "Task not in review");
        
        // Reset to InProgress so agent can resubmit
        _changeTaskState(_taskId, TaskState.InProgress);
        
        emit TaskRejected(_taskId, _reason, block.timestamp);
    }
    
    /**
     * @notice Mark task as failed (by project owner)
     * @param _taskId Task ID
     */
    function failTask(uint256 _taskId) external {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "Task does not exist");
        
        ProjectRegistry.Project memory project = projectRegistry.getProject(task.projectId);
        require(project.owner == msg.sender, "Not project owner");
        require(
            task.state == TaskState.Assigned ||
            task.state == TaskState.InProgress,
            "Cannot fail task in current state"
        );
        
        _changeTaskState(_taskId, TaskState.Failed);
    }
    
    /**
     * @notice Auto-fail task if deadline passed (anyone can call)
     * @param _taskId Task ID
     */
    function failTaskIfOverdue(uint256 _taskId) external {
        Task storage task = tasks[_taskId];
        require(task.id != 0, "Task does not exist");
        require(block.timestamp > task.deadline, "Deadline not passed");
        require(
            task.state == TaskState.Assigned ||
            task.state == TaskState.InProgress,
            "Cannot fail task in current state"
        );
        
        _changeTaskState(_taskId, TaskState.Failed);
    }
    
    /**
     * @notice Check if task is overdue
     * @param _taskId Task ID
     */
    function isTaskOverdue(uint256 _taskId) external view returns (bool) {
        Task memory task = tasks[_taskId];
        if (task.state == TaskState.Complete || task.state == TaskState.Failed) {
            return false;
        }
        return block.timestamp > task.deadline;
    }

    // ============ View Functions ============
    
    /**
     * @notice Get task details
     * @param _taskId Task ID
     */
    function getTask(uint256 _taskId) external view returns (Task memory) {
        require(tasks[_taskId].id != 0, "Task does not exist");
        return tasks[_taskId];
    }
    
    /**
     * @notice Get all tasks for a project
     * @param _projectId Project ID
     */
    function getProjectTasks(uint256 _projectId) external view returns (uint256[] memory) {
        return projectTasks[_projectId];
    }
    
    /**
     * @notice Get all tasks for an agent
     * @param _agent Agent address
     */
    function getAgentTasks(address _agent) external view returns (uint256[] memory) {
        return agentTasks[_agent];
    }
    
    /**
     * @notice Check if task dependencies are complete
     * @param _taskId Task ID
     */
    function dependenciesComplete(uint256 _taskId) external view returns (bool) {
        return _dependenciesComplete(_taskId);
    }

    // ============ Internal Functions ============
    
    function _changeTaskState(uint256 _taskId, TaskState _newState) internal {
        TaskState oldState = tasks[_taskId].state;
        tasks[_taskId].state = _newState;
        
        emit TaskStateChanged(_taskId, oldState, _newState, block.timestamp);
    }
    
    function _dependenciesComplete(uint256 _taskId) internal view returns (bool) {
        uint256[] memory deps = tasks[_taskId].dependencies;
        for (uint256 i = 0; i < deps.length; i++) {
            if (tasks[deps[i]].state != TaskState.Complete) {
                return false;
            }
        }
        return true;
    }
}
