// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ProjectRegistry.sol";
import "../src/TeamRegistry.sol";

contract TeamRegistryTest is Test {
    ProjectRegistry public registry;
    TeamRegistry public teamRegistry;
    
    address public owner = address(1);
    address public client = address(2);
    address public agent1 = address(3);
    address public agent2 = address(4);
    
    uint256 public projectId;
    
    function setUp() public {
        vm.warp(1000000);
        
        vm.prank(owner);
        registry = new ProjectRegistry();
        
        vm.prank(owner);
        teamRegistry = new TeamRegistry(address(registry));
        
        // Create project
        vm.prank(client);
        projectId = registry.createProject(
            "Test Project",
            "Team formation test",
            5000e6,
            3,
            true // requires ERC-8004
        );
        
        vm.prank(client);
        registry.startRecruiting(projectId);
    }
    
    function testSetAgentProfile() public {
        string[] memory skills = new string[](3);
        skills[0] = "Solidity";
        skills[1] = "React";
        skills[2] = "Design";
        
        vm.prank(agent1);
        teamRegistry.setAgentProfile(
            12345, // ERC-8004 token ID
            "Experienced blockchain developer",
            skills,
            "https://portfolio.com"
        );
        
        TeamRegistry.AgentProfile memory profile = teamRegistry.getAgentProfile(agent1);
        assertTrue(profile.isRegistered);
        assertEq(profile.erc8004TokenId, 12345);
        assertEq(profile.bio, "Experienced blockchain developer");
        assertEq(profile.skills.length, 3);
        assertEq(profile.portfolioUrl, "https://portfolio.com");
    }
    
    function testCannotSetProfileWithLongBio() public {
        string[] memory skills = new string[](1);
        skills[0] = "Skill";
        
        string memory longBio = new string(501); // 501 chars
        
        vm.prank(agent1);
        vm.expectRevert("Bio too long");
        teamRegistry.setAgentProfile(12345, longBio, skills, "");
    }
    
    function testCannotSetProfileWithTooManySkills() public {
        string[] memory skills = new string[](21); // Max is 20
        
        vm.prank(agent1);
        vm.expectRevert("Invalid skills count");
        teamRegistry.setAgentProfile(12345, "Bio", skills, "");
    }
    
    function testCannotSetProfileWithNoSkills() public {
        string[] memory skills = new string[](0);
        
        vm.prank(agent1);
        vm.expectRevert("Invalid skills count");
        teamRegistry.setAgentProfile(12345, "Bio", skills, "");
    }
    
    function testUpdateAgentProfile() public {
        string[] memory skills1 = new string[](1);
        skills1[0] = "Solidity";
        
        vm.startPrank(agent1);
        teamRegistry.setAgentProfile(111, "First bio", skills1, "url1");
        
        string[] memory skills2 = new string[](2);
        skills2[0] = "Solidity";
        skills2[1] = "Rust";
        
        teamRegistry.setAgentProfile(222, "Updated bio", skills2, "url2");
        vm.stopPrank();
        
        TeamRegistry.AgentProfile memory profile = teamRegistry.getAgentProfile(agent1);
        assertEq(profile.erc8004TokenId, 222);
        assertEq(profile.bio, "Updated bio");
        assertEq(profile.skills.length, 2);
    }
    
    function testApplyToProject() public {
        string[] memory skills = new string[](2);
        skills[0] = "Smart Contracts";
        skills[1] = "Security";
        
        vm.prank(agent1);
        uint256 applicationId = teamRegistry.applyToProject(
            projectId,
            12345,
            "I have 5 years experience in blockchain",
            skills
        );
        
        assertEq(applicationId, 1);
        
        TeamRegistry.Application memory app = teamRegistry.getApplication(applicationId);
        assertEq(app.projectId, projectId);
        assertEq(app.applicant, agent1);
        assertEq(app.erc8004TokenId, 12345);
        assertEq(uint8(app.status), uint8(TeamRegistry.ApplicationStatus.Pending));
    }
    
    function testCannotApplyWithoutERC8004IfRequired() public {
        string[] memory skills = new string[](1);
        skills[0] = "Solidity";
        
        vm.prank(agent1);
        vm.expectRevert("ERC-8004 required");
        teamRegistry.applyToProject(
            projectId,
            0, // no token ID
            "I want to join",
            skills
        );
    }
    
    function testCannotApplyToNonRecruitingProject() public {
        // Create draft project
        vm.prank(client);
        uint256 draftProject = registry.createProject("Draft", "Test", 1000e6, 2, false);
        
        string[] memory skills = new string[](1);
        skills[0] = "Skill";
        
        vm.prank(agent1);
        vm.expectRevert("Project not recruiting");
        teamRegistry.applyToProject(draftProject, 0, "Pitch", skills);
    }
    
    function testCannotApplyWithEmptyPitch() public {
        string[] memory skills = new string[](1);
        skills[0] = "Skill";
        
        vm.prank(agent1);
        vm.expectRevert("Invalid pitch");
        teamRegistry.applyToProject(projectId, 12345, "", skills);
    }
    
    function testCannotApplyWithNoSkills() public {
        string[] memory skills = new string[](0);
        
        vm.prank(agent1);
        vm.expectRevert("Must propose skills");
        teamRegistry.applyToProject(projectId, 12345, "Pitch", skills);
    }
    
    function testAcceptApplication() public {
        // Apply
        string[] memory skills = new string[](1);
        skills[0] = "Solidity";
        
        vm.prank(agent1);
        uint256 applicationId = teamRegistry.applyToProject(
            projectId,
            12345,
            "I'm great at Solidity",
            skills
        );
        
        // Accept
        vm.startPrank(client);
        teamRegistry.acceptApplication(applicationId);
        registry.addAgent(projectId, agent1);
        vm.stopPrank();
        
        // Check status
        TeamRegistry.Application memory app = teamRegistry.getApplication(applicationId);
        assertEq(uint8(app.status), uint8(TeamRegistry.ApplicationStatus.Accepted));
        
        // Check team member added
        assertTrue(registry.isTeamMember(projectId, agent1));
        
        TeamRegistry.TeamMember memory member = teamRegistry.getTeamMember(projectId, agent1);
        assertEq(member.agent, agent1);
        assertEq(member.erc8004TokenId, 12345);
        assertTrue(member.isActive);
    }
    
    function testCannotAcceptIfNotOwner() public {
        string[] memory skills = new string[](1);
        skills[0] = "Skill";
        
        vm.prank(agent1);
        uint256 applicationId = teamRegistry.applyToProject(
            projectId,
            12345,
            "Pitch",
            skills
        );
        
        vm.prank(agent2);
        vm.expectRevert("Not project owner");
        teamRegistry.acceptApplication(applicationId);
    }
    
    function testCannotAcceptAlreadyProcessed() public {
        string[] memory skills = new string[](1);
        skills[0] = "Skill";
        
        vm.prank(agent1);
        uint256 applicationId = teamRegistry.applyToProject(
            projectId,
            12345,
            "Pitch",
            skills
        );
        
        vm.startPrank(client);
        teamRegistry.acceptApplication(applicationId);
        registry.addAgent(projectId, agent1);
        
        vm.expectRevert("Already processed");
        teamRegistry.acceptApplication(applicationId);
        vm.stopPrank();
    }
    
    function testRejectApplication() public {
        string[] memory skills = new string[](1);
        skills[0] = "Skill";
        
        vm.prank(agent1);
        uint256 applicationId = teamRegistry.applyToProject(
            projectId,
            12345,
            "Pitch",
            skills
        );
        
        vm.prank(client);
        teamRegistry.rejectApplication(applicationId);
        
        TeamRegistry.Application memory app = teamRegistry.getApplication(applicationId);
        assertEq(uint8(app.status), uint8(TeamRegistry.ApplicationStatus.Rejected));
        
        // Not added to team
        assertFalse(registry.isTeamMember(projectId, agent1));
    }
    
    function testCannotRejectIfNotOwner() public {
        string[] memory skills = new string[](1);
        skills[0] = "Skill";
        
        vm.prank(agent1);
        uint256 applicationId = teamRegistry.applyToProject(
            projectId,
            12345,
            "Pitch",
            skills
        );
        
        vm.prank(agent2);
        vm.expectRevert("Not project owner");
        teamRegistry.rejectApplication(applicationId);
    }
    
    function testRemoveTeamMember() public {
        // Accept agent
        string[] memory skills = new string[](1);
        skills[0] = "Skill";
        
        vm.prank(agent1);
        uint256 applicationId = teamRegistry.applyToProject(
            projectId,
            12345,
            "Pitch",
            skills
        );
        
        vm.startPrank(client);
        teamRegistry.acceptApplication(applicationId);
        registry.addAgent(projectId, agent1);
        
        // Remove
        teamRegistry.removeTeamMember(projectId, agent1);
        vm.stopPrank();
        
        TeamRegistry.TeamMember memory member = teamRegistry.getTeamMember(projectId, agent1);
        assertFalse(member.isActive);
    }
    
    function testCannotRemoveIfNotOwner() public {
        // Setup team member
        string[] memory skills = new string[](1);
        skills[0] = "Skill";
        
        vm.prank(agent1);
        uint256 applicationId = teamRegistry.applyToProject(
            projectId,
            12345,
            "Pitch",
            skills
        );
        
        vm.startPrank(client);
        teamRegistry.acceptApplication(applicationId);
        registry.addAgent(projectId, agent1);
        vm.stopPrank();
        
        // Try to remove
        vm.prank(agent2);
        vm.expectRevert("Not project owner");
        teamRegistry.removeTeamMember(projectId, agent1);
    }
    
    function testGetProjectApplications() public {
        string[] memory skills = new string[](1);
        skills[0] = "Skill";
        
        vm.prank(agent1);
        uint256 app1 = teamRegistry.applyToProject(projectId, 111, "Pitch 1", skills);
        
        vm.prank(agent2);
        uint256 app2 = teamRegistry.applyToProject(projectId, 222, "Pitch 2", skills);
        
        uint256[] memory applications = teamRegistry.getProjectApplications(projectId);
        assertEq(applications.length, 2);
        assertEq(applications[0], app1);
        assertEq(applications[1], app2);
    }
    
    function testGetAgentApplications() public {
        // Create two projects
        vm.startPrank(client);
        uint256 project2 = registry.createProject("Project 2", "Test", 1000e6, 2, false);
        registry.startRecruiting(project2);
        vm.stopPrank();
        
        string[] memory skills = new string[](1);
        skills[0] = "Skill";
        
        vm.startPrank(agent1);
        uint256 app1 = teamRegistry.applyToProject(projectId, 111, "Pitch 1", skills);
        uint256 app2 = teamRegistry.applyToProject(project2, 0, "Pitch 2", skills);
        vm.stopPrank();
        
        uint256[] memory applications = teamRegistry.getAgentApplications(agent1);
        assertEq(applications.length, 2);
        assertEq(applications[0], app1);
        assertEq(applications[1], app2);
    }
    
    function testMultipleAgentsApply() public {
        string[] memory skills = new string[](1);
        skills[0] = "Skill";
        
        vm.prank(agent1);
        teamRegistry.applyToProject(projectId, 111, "Agent 1 pitch", skills);
        
        vm.prank(agent2);
        teamRegistry.applyToProject(projectId, 222, "Agent 2 pitch", skills);
        
        uint256[] memory applications = teamRegistry.getProjectApplications(projectId);
        assertEq(applications.length, 2);
    }
    
    function testFullApplicationFlow() public {
        // Setup agent profile
        string[] memory profileSkills = new string[](2);
        profileSkills[0] = "Solidity";
        profileSkills[1] = "Security Audits";
        
        vm.prank(agent1);
        teamRegistry.setAgentProfile(
            12345,
            "Senior blockchain developer with 5 years experience",
            profileSkills,
            "https://github.com/agent1"
        );
        
        // Apply to project
        string[] memory appSkills = new string[](1);
        appSkills[0] = "Smart Contract Development";
        
        vm.prank(agent1);
        uint256 applicationId = teamRegistry.applyToProject(
            projectId,
            12345,
            "I can build secure, gas-optimized contracts",
            appSkills
        );
        
        // Owner reviews and accepts
        vm.startPrank(client);
        teamRegistry.acceptApplication(applicationId);
        registry.addAgent(projectId, agent1);
        vm.stopPrank();
        
        // Verify full flow
        TeamRegistry.Application memory app = teamRegistry.getApplication(applicationId);
        assertEq(uint8(app.status), uint8(TeamRegistry.ApplicationStatus.Accepted));
        assertTrue(registry.isTeamMember(projectId, agent1));
        
        TeamRegistry.TeamMember memory member = teamRegistry.getTeamMember(projectId, agent1);
        assertEq(member.agent, agent1);
        assertEq(member.erc8004TokenId, 12345);
        assertEq(member.bio, "Senior blockchain developer with 5 years experience");
        assertTrue(member.isActive);
    }
}
