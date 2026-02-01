// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./ProjectRegistry.sol";

/**
 * @title TeamRegistry
 * @notice Manage agent applications and team member details
 * @dev Integrates with ProjectRegistry for team formation
 */
contract TeamRegistry is Ownable, ReentrancyGuard {
    // ============ Structs ============
    
    struct TeamMember {
        address agent;
        uint256 erc8004TokenId;     // ERC-8004 identity
        string[] skills;
        string bio;
        uint256 joinedAt;
        bool isActive;
    }
    
    struct Application {
        uint256 projectId;
        address applicant;
        uint256 erc8004TokenId;
        string pitch;
        string[] proposedSkills;
        uint256 appliedAt;
        ApplicationStatus status;
    }
    
    enum ApplicationStatus {
        Pending,
        Accepted,
        Rejected
    }

    // ============ State Variables ============
    
    ProjectRegistry public immutable projectRegistry;
    
    uint256 public nextApplicationId = 1;
    
    // Project teams (projectId => agent => TeamMember)
    mapping(uint256 => mapping(address => TeamMember)) public teamMembers;
    
    // Applications (applicationId => Application)
    mapping(uint256 => Application) public applications;
    
    // Project applications (projectId => applicationIds[])
    mapping(uint256 => uint256[]) public projectApplications;
    
    // Agent applications (agent => applicationIds[])
    mapping(address => uint256[]) public agentApplications;
    
    // Agent profile (agent => public profile data)
    mapping(address => AgentProfile) public agentProfiles;
    
    struct AgentProfile {
        uint256 erc8004TokenId;
        string bio;
        string[] skills;
        string portfolioUrl;
        uint256 profileCreatedAt;
        bool isRegistered;
    }

    // ============ Events ============
    
    event ApplicationSubmitted(
        uint256 indexed applicationId,
        uint256 indexed projectId,
        address indexed applicant,
        uint256 timestamp
    );
    
    event ApplicationAccepted(
        uint256 indexed applicationId,
        uint256 indexed projectId,
        address indexed applicant,
        uint256 timestamp
    );
    
    event ApplicationRejected(
        uint256 indexed applicationId,
        uint256 indexed projectId,
        address indexed applicant,
        uint256 timestamp
    );
    
    event TeamMemberAdded(
        uint256 indexed projectId,
        address indexed agent,
        uint256 erc8004TokenId,
        uint256 timestamp
    );
    
    event TeamMemberRemoved(
        uint256 indexed projectId,
        address indexed agent,
        uint256 timestamp
    );
    
    event AgentProfileCreated(
        address indexed agent,
        uint256 erc8004TokenId,
        uint256 timestamp
    );
    
    event AgentProfileUpdated(
        address indexed agent,
        uint256 timestamp
    );

    // ============ Constructor ============
    
    constructor(address _projectRegistry) Ownable(msg.sender) {
        require(_projectRegistry != address(0), "Invalid registry");
        projectRegistry = ProjectRegistry(_projectRegistry);
    }

    // ============ Agent Profile Functions ============
    
    /**
     * @notice Create or update agent profile
     * @param _erc8004TokenId ERC-8004 token ID
     * @param _bio Agent bio/description
     * @param _skills Array of skills
     * @param _portfolioUrl Portfolio/website URL
     */
    function setAgentProfile(
        uint256 _erc8004TokenId,
        string calldata _bio,
        string[] calldata _skills,
        string calldata _portfolioUrl
    ) external {
        require(bytes(_bio).length <= 500, "Bio too long");
        require(_skills.length > 0 && _skills.length <= 20, "Invalid skills count");
        
        bool isNewProfile = !agentProfiles[msg.sender].isRegistered;
        
        agentProfiles[msg.sender] = AgentProfile({
            erc8004TokenId: _erc8004TokenId,
            bio: _bio,
            skills: _skills,
            portfolioUrl: _portfolioUrl,
            profileCreatedAt: isNewProfile ? block.timestamp : agentProfiles[msg.sender].profileCreatedAt,
            isRegistered: true
        });
        
        if (isNewProfile) {
            emit AgentProfileCreated(msg.sender, _erc8004TokenId, block.timestamp);
        } else {
            emit AgentProfileUpdated(msg.sender, block.timestamp);
        }
    }

    // ============ Application Functions ============
    
    /**
     * @notice Apply to join a project
     * @param _projectId Project ID
     * @param _erc8004TokenId ERC-8004 token ID (if required)
     * @param _pitch Application pitch
     * @param _proposedSkills Skills you'll contribute
     */
    function applyToProject(
        uint256 _projectId,
        uint256 _erc8004TokenId,
        string calldata _pitch,
        string[] calldata _proposedSkills
    ) external nonReentrant returns (uint256) {
        ProjectRegistry.Project memory project = projectRegistry.getProject(_projectId);
        require(
            uint8(project.state) == uint8(ProjectRegistry.ProjectState.Recruiting),
            "Project not recruiting"
        );
        require(bytes(_pitch).length > 0 && bytes(_pitch).length <= 500, "Invalid pitch");
        require(_proposedSkills.length > 0, "Must propose skills");
        
        // If project requires ERC-8004, verify token ID > 0
        if (project.requiresERC8004) {
            require(_erc8004TokenId > 0, "ERC-8004 required");
        }
        
        // Check not already on team
        require(!projectRegistry.isTeamMember(_projectId, msg.sender), "Already on team");
        
        uint256 applicationId = nextApplicationId++;
        
        applications[applicationId] = Application({
            projectId: _projectId,
            applicant: msg.sender,
            erc8004TokenId: _erc8004TokenId,
            pitch: _pitch,
            proposedSkills: _proposedSkills,
            appliedAt: block.timestamp,
            status: ApplicationStatus.Pending
        });
        
        projectApplications[_projectId].push(applicationId);
        agentApplications[msg.sender].push(applicationId);
        
        emit ApplicationSubmitted(applicationId, _projectId, msg.sender, block.timestamp);
        
        return applicationId;
    }
    
    /**
     * @notice Accept an application and add agent to team
     * @param _applicationId Application ID
     */
    function acceptApplication(uint256 _applicationId) external nonReentrant {
        Application storage app = applications[_applicationId];
        require(app.projectId != 0, "Application does not exist");
        require(app.status == ApplicationStatus.Pending, "Already processed");
        
        ProjectRegistry.Project memory project = projectRegistry.getProject(app.projectId);
        require(project.owner == msg.sender, "Not project owner");
        
        app.status = ApplicationStatus.Accepted;
        
        // Note: Project owner must separately call projectRegistry.addAgent()
        // after accepting the application
        
        // Create team member record
        teamMembers[app.projectId][app.applicant] = TeamMember({
            agent: app.applicant,
            erc8004TokenId: app.erc8004TokenId,
            skills: app.proposedSkills,
            bio: agentProfiles[app.applicant].bio,
            joinedAt: block.timestamp,
            isActive: true
        });
        
        emit ApplicationAccepted(_applicationId, app.projectId, app.applicant, block.timestamp);
        emit TeamMemberAdded(app.projectId, app.applicant, app.erc8004TokenId, block.timestamp);
    }
    
    /**
     * @notice Reject an application
     * @param _applicationId Application ID
     */
    function rejectApplication(uint256 _applicationId) external {
        Application storage app = applications[_applicationId];
        require(app.projectId != 0, "Application does not exist");
        require(app.status == ApplicationStatus.Pending, "Already processed");
        
        ProjectRegistry.Project memory project = projectRegistry.getProject(app.projectId);
        require(project.owner == msg.sender, "Not project owner");
        
        app.status = ApplicationStatus.Rejected;
        
        emit ApplicationRejected(_applicationId, app.projectId, app.applicant, block.timestamp);
    }
    
    /**
     * @notice Remove team member (marks as inactive)
     * @param _projectId Project ID
     * @param _agent Agent address
     */
    function removeTeamMember(uint256 _projectId, address _agent) external {
        ProjectRegistry.Project memory project = projectRegistry.getProject(_projectId);
        require(project.owner == msg.sender, "Not project owner");
        require(teamMembers[_projectId][_agent].agent != address(0), "Not a team member");
        
        teamMembers[_projectId][_agent].isActive = false;
        
        emit TeamMemberRemoved(_projectId, _agent, block.timestamp);
    }

    // ============ View Functions ============
    
    /**
     * @notice Get team member details
     * @param _projectId Project ID
     * @param _agent Agent address
     */
    function getTeamMember(uint256 _projectId, address _agent) 
        external 
        view 
        returns (TeamMember memory) 
    {
        return teamMembers[_projectId][_agent];
    }
    
    /**
     * @notice Get all applications for a project
     * @param _projectId Project ID
     */
    function getProjectApplications(uint256 _projectId) 
        external 
        view 
        returns (uint256[] memory) 
    {
        return projectApplications[_projectId];
    }
    
    /**
     * @notice Get all applications by an agent
     * @param _agent Agent address
     */
    function getAgentApplications(address _agent) 
        external 
        view 
        returns (uint256[] memory) 
    {
        return agentApplications[_agent];
    }
    
    /**
     * @notice Get application details
     * @param _applicationId Application ID
     */
    function getApplication(uint256 _applicationId) 
        external 
        view 
        returns (Application memory) 
    {
        require(applications[_applicationId].projectId != 0, "Application does not exist");
        return applications[_applicationId];
    }
    
    /**
     * @notice Get agent profile
     * @param _agent Agent address
     */
    function getAgentProfile(address _agent) 
        external 
        view 
        returns (AgentProfile memory) 
    {
        return agentProfiles[_agent];
    }
}
