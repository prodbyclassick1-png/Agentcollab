// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title ProjectRegistry
 * @notice Create and manage multi-agent projects
 * @dev Projects move through states: Draft → Recruiting → Active → Review → Complete
 */
contract ProjectRegistry is Ownable, ReentrancyGuard, Pausable {
    // ============ Enums ============
    
    enum ProjectState {
        Draft,      // Project created, not yet recruiting
        Recruiting, // Accepting agent applications
        Active,     // Work in progress
        Review,     // Awaiting final review
        Complete,   // Successfully finished
        Cancelled   // Cancelled by owner
    }

    // ============ Structs ============
    
    struct Project {
        uint256 id;
        address owner;              // Client who created the project
        string title;
        string description;
        uint256 budgetUSDC;         // Total budget in USDC (6 decimals)
        ProjectState state;
        uint256 createdAt;
        uint256 startedAt;
        uint256 completedAt;
        uint8 maxTeamSize;
        uint8 currentTeamSize;
        bool requiresERC8004;       // Only verified agents can apply
        uint256 platformFee;        // Fee in basis points (200 = 2%)
    }

    // ============ State Variables ============
    
    uint256 public nextProjectId = 1;
    uint256 public constant PLATFORM_FEE_BPS = 200; // 2%
    uint256 public constant MAX_TEAM_SIZE = 50;
    uint256 public totalProjects;
    
    mapping(uint256 => Project) public projects;
    mapping(uint256 => address[]) public projectTeams; // projectId => agent addresses
    mapping(address => uint256[]) public agentProjects; // agent => projectIds they're on
    
    // ============ Events ============
    
    event ProjectCreated(
        uint256 indexed projectId,
        address indexed owner,
        string title,
        uint256 budgetUSDC,
        uint8 maxTeamSize,
        uint256 timestamp
    );
    
    event ProjectStateChanged(
        uint256 indexed projectId,
        ProjectState oldState,
        ProjectState newState,
        uint256 timestamp
    );
    
    event AgentJoined(
        uint256 indexed projectId,
        address indexed agent,
        uint256 timestamp
    );
    
    event AgentRemoved(
        uint256 indexed projectId,
        address indexed agent,
        uint256 timestamp
    );

    // ============ Constructor ============
    
    constructor() Ownable(msg.sender) {}

    // ============ Core Functions ============
    
    /**
     * @notice Create a new project
     * @param _title Project title
     * @param _description Detailed description
     * @param _budgetUSDC Total budget in USDC
     * @param _maxTeamSize Maximum number of agents
     * @param _requiresERC8004 Require ERC-8004 verification
     */
    function createProject(
        string calldata _title,
        string calldata _description,
        uint256 _budgetUSDC,
        uint8 _maxTeamSize,
        bool _requiresERC8004
    ) external whenNotPaused nonReentrant returns (uint256) {
        require(bytes(_title).length > 0 && bytes(_title).length <= 100, "Invalid title length");
        require(bytes(_description).length > 0 && bytes(_description).length <= 1000, "Invalid description length");
        require(_budgetUSDC > 0, "Budget must be > 0");
        require(_maxTeamSize > 0 && _maxTeamSize <= MAX_TEAM_SIZE, "Invalid team size");
        
        uint256 projectId = nextProjectId++;
        
        projects[projectId] = Project({
            id: projectId,
            owner: msg.sender,
            title: _title,
            description: _description,
            budgetUSDC: _budgetUSDC,
            state: ProjectState.Draft,
            createdAt: block.timestamp,
            startedAt: 0,
            completedAt: 0,
            maxTeamSize: _maxTeamSize,
            currentTeamSize: 0,
            requiresERC8004: _requiresERC8004,
            platformFee: PLATFORM_FEE_BPS
        });
        
        totalProjects++;
        
        emit ProjectCreated(
            projectId,
            msg.sender,
            _title,
            _budgetUSDC,
            _maxTeamSize,
            block.timestamp
        );
        
        return projectId;
    }
    
    /**
     * @notice Move project to Recruiting state
     * @param _projectId Project ID
     */
    function startRecruiting(uint256 _projectId) external {
        Project storage project = projects[_projectId];
        require(project.owner == msg.sender, "Not project owner");
        require(project.state == ProjectState.Draft, "Must be in Draft state");
        
        _changeState(_projectId, ProjectState.Recruiting);
    }
    
    /**
     * @notice Start the project (move to Active)
     * @param _projectId Project ID
     */
    function startProject(uint256 _projectId) external {
        Project storage project = projects[_projectId];
        require(project.owner == msg.sender, "Not project owner");
        require(project.state == ProjectState.Recruiting, "Must be Recruiting");
        require(project.currentTeamSize > 0, "Need at least 1 agent");
        
        project.startedAt = block.timestamp;
        _changeState(_projectId, ProjectState.Active);
    }
    
    /**
     * @notice Move project to Review state
     * @param _projectId Project ID
     */
    function submitForReview(uint256 _projectId) external {
        Project storage project = projects[_projectId];
        require(project.state == ProjectState.Active, "Must be Active");
        // Allow any team member to submit for review
        require(_isTeamMember(_projectId, msg.sender), "Not a team member");
        
        _changeState(_projectId, ProjectState.Review);
    }
    
    /**
     * @notice Mark project as complete
     * @param _projectId Project ID
     */
    function completeProject(uint256 _projectId) external {
        Project storage project = projects[_projectId];
        require(project.owner == msg.sender, "Not project owner");
        require(project.state == ProjectState.Review, "Must be in Review");
        
        project.completedAt = block.timestamp;
        _changeState(_projectId, ProjectState.Complete);
    }
    
    /**
     * @notice Cancel a project
     * @param _projectId Project ID
     */
    function cancelProject(uint256 _projectId) external {
        Project storage project = projects[_projectId];
        require(project.owner == msg.sender, "Not project owner");
        require(
            project.state == ProjectState.Draft ||
            project.state == ProjectState.Recruiting ||
            project.state == ProjectState.Active,
            "Cannot cancel in current state"
        );
        
        _changeState(_projectId, ProjectState.Cancelled);
    }
    
    /**
     * @notice Add an agent to the project team
     * @param _projectId Project ID
     * @param _agent Agent address
     */
    function addAgent(uint256 _projectId, address _agent) external {
        Project storage project = projects[_projectId];
        require(project.owner == msg.sender, "Not project owner");
        require(
            project.state == ProjectState.Recruiting || 
            project.state == ProjectState.Active,
            "Cannot add agents in current state"
        );
        require(project.currentTeamSize < project.maxTeamSize, "Team is full");
        require(!_isTeamMember(_projectId, _agent), "Agent already on team");
        
        projectTeams[_projectId].push(_agent);
        agentProjects[_agent].push(_projectId);
        project.currentTeamSize++;
        
        emit AgentJoined(_projectId, _agent, block.timestamp);
    }
    
    /**
     * @notice Remove an agent from the project team
     * @param _projectId Project ID
     * @param _agent Agent address
     */
    function removeAgent(uint256 _projectId, address _agent) external {
        Project storage project = projects[_projectId];
        require(project.owner == msg.sender, "Not project owner");
        require(project.state == ProjectState.Recruiting, "Can only remove during recruiting");
        require(_isTeamMember(_projectId, _agent), "Agent not on team");
        
        // Remove from projectTeams
        address[] storage team = projectTeams[_projectId];
        for (uint256 i = 0; i < team.length; i++) {
            if (team[i] == _agent) {
                team[i] = team[team.length - 1];
                team.pop();
                break;
            }
        }
        
        project.currentTeamSize--;
        
        emit AgentRemoved(_projectId, _agent, block.timestamp);
    }

    // ============ View Functions ============
    
    /**
     * @notice Get project details
     * @param _projectId Project ID
     */
    function getProject(uint256 _projectId) external view returns (Project memory) {
        require(projects[_projectId].id != 0, "Project does not exist");
        return projects[_projectId];
    }
    
    /**
     * @notice Get project team
     * @param _projectId Project ID
     */
    function getProjectTeam(uint256 _projectId) external view returns (address[] memory) {
        return projectTeams[_projectId];
    }
    
    /**
     * @notice Get projects for an agent
     * @param _agent Agent address
     */
    function getAgentProjects(address _agent) external view returns (uint256[] memory) {
        return agentProjects[_agent];
    }
    
    /**
     * @notice Check if address is on project team
     * @param _projectId Project ID
     * @param _agent Agent address
     */
    function isTeamMember(uint256 _projectId, address _agent) external view returns (bool) {
        return _isTeamMember(_projectId, _agent);
    }

    // ============ Admin Functions ============
    
    /**
     * @notice Pause contract
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @notice Unpause contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    // ============ Internal Functions ============
    
    function _changeState(uint256 _projectId, ProjectState _newState) internal {
        ProjectState oldState = projects[_projectId].state;
        projects[_projectId].state = _newState;
        
        emit ProjectStateChanged(_projectId, oldState, _newState, block.timestamp);
    }
    
    function _isTeamMember(uint256 _projectId, address _agent) internal view returns (bool) {
        address[] memory team = projectTeams[_projectId];
        for (uint256 i = 0; i < team.length; i++) {
            if (team[i] == _agent) {
                return true;
            }
        }
        return false;
    }
}
