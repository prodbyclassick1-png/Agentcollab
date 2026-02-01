// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ProjectRegistry.sol";

contract ProjectRegistryTest is Test {
    ProjectRegistry public registry;
    
    address public owner = address(1);
    address public client = address(2);
    address public agent1 = address(3);
    address public agent2 = address(4);
    
    function setUp() public {
        vm.prank(owner);
        registry = new ProjectRegistry();
    }
    
    function testCreateProject() public {
        vm.prank(client);
        uint256 projectId = registry.createProject(
            "Build DeFi Dashboard",
            "Need smart contracts, frontend, and design",
            2000e6, // 2000 USDC
            3,      // max 3 agents
            true    // require ERC-8004
        );
        
        assertEq(projectId, 1);
        assertEq(registry.totalProjects(), 1);
        
        ProjectRegistry.Project memory project = registry.getProject(projectId);
        assertEq(project.owner, client);
        assertEq(project.title, "Build DeFi Dashboard");
        assertEq(project.budgetUSDC, 2000e6);
        assertEq(project.maxTeamSize, 3);
        assertEq(uint8(project.state), uint8(ProjectRegistry.ProjectState.Draft));
    }
    
    function testCannotCreateWithInvalidTitle() public {
        vm.prank(client);
        vm.expectRevert("Invalid title length");
        registry.createProject(
            "", // empty title
            "Description",
            1000e6,
            2,
            false
        );
    }
    
    function testCannotCreateWithZeroBudget() public {
        vm.prank(client);
        vm.expectRevert("Budget must be > 0");
        registry.createProject(
            "Title",
            "Description",
            0,
            2,
            false
        );
    }
    
    function testStartRecruiting() public {
        vm.prank(client);
        uint256 projectId = registry.createProject(
            "Test Project",
            "Description",
            1000e6,
            2,
            false
        );
        
        vm.prank(client);
        registry.startRecruiting(projectId);
        
        ProjectRegistry.Project memory project = registry.getProject(projectId);
        assertEq(uint8(project.state), uint8(ProjectRegistry.ProjectState.Recruiting));
    }
    
    function testCannotStartRecruitingIfNotOwner() public {
        vm.prank(client);
        uint256 projectId = registry.createProject(
            "Test Project",
            "Description",
            1000e6,
            2,
            false
        );
        
        vm.prank(agent1);
        vm.expectRevert("Not project owner");
        registry.startRecruiting(projectId);
    }
    
    function testAddAgent() public {
        vm.prank(client);
        uint256 projectId = registry.createProject(
            "Test Project",
            "Description",
            1000e6,
            2,
            false
        );
        
        vm.prank(client);
        registry.startRecruiting(projectId);
        
        vm.prank(client);
        registry.addAgent(projectId, agent1);
        
        ProjectRegistry.Project memory project = registry.getProject(projectId);
        assertEq(project.currentTeamSize, 1);
        assertTrue(registry.isTeamMember(projectId, agent1));
        
        address[] memory team = registry.getProjectTeam(projectId);
        assertEq(team.length, 1);
        assertEq(team[0], agent1);
    }
    
    function testCannotAddMoreThanMaxTeamSize() public {
        vm.prank(client);
        uint256 projectId = registry.createProject(
            "Test Project",
            "Description",
            1000e6,
            1, // max 1 agent
            false
        );
        
        vm.prank(client);
        registry.startRecruiting(projectId);
        
        vm.prank(client);
        registry.addAgent(projectId, agent1);
        
        vm.prank(client);
        vm.expectRevert("Team is full");
        registry.addAgent(projectId, agent2);
    }
    
    function testCannotAddSameAgentTwice() public {
        vm.prank(client);
        uint256 projectId = registry.createProject(
            "Test Project",
            "Description",
            1000e6,
            2,
            false
        );
        
        vm.prank(client);
        registry.startRecruiting(projectId);
        
        vm.prank(client);
        registry.addAgent(projectId, agent1);
        
        vm.prank(client);
        vm.expectRevert("Agent already on team");
        registry.addAgent(projectId, agent1);
    }
    
    function testRemoveAgent() public {
        vm.prank(client);
        uint256 projectId = registry.createProject(
            "Test Project",
            "Description",
            1000e6,
            2,
            false
        );
        
        vm.prank(client);
        registry.startRecruiting(projectId);
        
        vm.prank(client);
        registry.addAgent(projectId, agent1);
        
        vm.prank(client);
        registry.removeAgent(projectId, agent1);
        
        ProjectRegistry.Project memory project = registry.getProject(projectId);
        assertEq(project.currentTeamSize, 0);
        assertFalse(registry.isTeamMember(projectId, agent1));
    }
    
    function testStartProject() public {
        vm.prank(client);
        uint256 projectId = registry.createProject(
            "Test Project",
            "Description",
            1000e6,
            2,
            false
        );
        
        vm.prank(client);
        registry.startRecruiting(projectId);
        
        vm.prank(client);
        registry.addAgent(projectId, agent1);
        
        vm.prank(client);
        registry.startProject(projectId);
        
        ProjectRegistry.Project memory project = registry.getProject(projectId);
        assertEq(uint8(project.state), uint8(ProjectRegistry.ProjectState.Active));
        assertGt(project.startedAt, 0);
    }
    
    function testCannotStartProjectWithoutAgents() public {
        vm.prank(client);
        uint256 projectId = registry.createProject(
            "Test Project",
            "Description",
            1000e6,
            2,
            false
        );
        
        vm.prank(client);
        registry.startRecruiting(projectId);
        
        vm.prank(client);
        vm.expectRevert("Need at least 1 agent");
        registry.startProject(projectId);
    }
    
    function testSubmitForReview() public {
        vm.prank(client);
        uint256 projectId = registry.createProject(
            "Test Project",
            "Description",
            1000e6,
            1,
            false
        );
        
        vm.prank(client);
        registry.startRecruiting(projectId);
        
        vm.prank(client);
        registry.addAgent(projectId, agent1);
        
        vm.prank(client);
        registry.startProject(projectId);
        
        // Agent can submit for review
        vm.prank(agent1);
        registry.submitForReview(projectId);
        
        ProjectRegistry.Project memory project = registry.getProject(projectId);
        assertEq(uint8(project.state), uint8(ProjectRegistry.ProjectState.Review));
    }
    
    function testCompleteProject() public {
        vm.prank(client);
        uint256 projectId = registry.createProject(
            "Test Project",
            "Description",
            1000e6,
            1,
            false
        );
        
        vm.prank(client);
        registry.startRecruiting(projectId);
        
        vm.prank(client);
        registry.addAgent(projectId, agent1);
        
        vm.prank(client);
        registry.startProject(projectId);
        
        vm.prank(agent1);
        registry.submitForReview(projectId);
        
        vm.prank(client);
        registry.completeProject(projectId);
        
        ProjectRegistry.Project memory project = registry.getProject(projectId);
        assertEq(uint8(project.state), uint8(ProjectRegistry.ProjectState.Complete));
        assertGt(project.completedAt, 0);
    }
    
    function testCancelProject() public {
        vm.prank(client);
        uint256 projectId = registry.createProject(
            "Test Project",
            "Description",
            1000e6,
            1,
            false
        );
        
        vm.prank(client);
        registry.cancelProject(projectId);
        
        ProjectRegistry.Project memory project = registry.getProject(projectId);
        assertEq(uint8(project.state), uint8(ProjectRegistry.ProjectState.Cancelled));
    }
    
    function testPauseUnpause() public {
        vm.prank(owner);
        registry.pause();
        
        vm.prank(client);
        vm.expectRevert();
        registry.createProject(
            "Test",
            "Test",
            1000e6,
            1,
            false
        );
        
        vm.prank(owner);
        registry.unpause();
        
        vm.prank(client);
        uint256 projectId = registry.createProject(
            "Test",
            "Test",
            1000e6,
            1,
            false
        );
        
        assertEq(projectId, 1);
    }
}
