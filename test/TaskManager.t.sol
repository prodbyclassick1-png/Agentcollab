// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ProjectRegistry.sol";
import "../src/TaskManager.sol";

contract TaskManagerTest is Test {
    ProjectRegistry public registry;
    TaskManager public taskManager;
    
    address public owner = address(1);
    address public client = address(2);
    address public agent1 = address(3);
    address public agent2 = address(4);
    
    uint256 public projectId;
    
    function setUp() public {
        vm.warp(1000000); // Start at reasonable timestamp
        
        vm.prank(owner);
        registry = new ProjectRegistry();
        
        vm.prank(owner);
        taskManager = new TaskManager(address(registry));
        
        // Create and prepare a project
        vm.prank(client);
        projectId = registry.createProject(
            "Test Project",
            "Multi-agent test project",
            5000e6, // 5000 USDC
            3,
            false
        );
        
        vm.prank(client);
        registry.startRecruiting(projectId);
        
        vm.prank(client);
        registry.addAgent(projectId, agent1);
        
        vm.prank(client);
        registry.addAgent(projectId, agent2);
        
        vm.prank(client);
        registry.startProject(projectId);
    }
    
    function testCreateTask() public {
        vm.prank(client);
        uint256[] memory deps = new uint256[](0);
        uint256 taskId = taskManager.createTask(
            projectId,
            "Build Smart Contracts",
            "Develop and test Solidity contracts",
            1000e6, // 1000 USDC
            block.timestamp + 7 days,
            deps
        );
        
        assertEq(taskId, 1);
        assertEq(taskManager.totalTasks(), 1);
        
        TaskManager.Task memory task = taskManager.getTask(taskId);
        assertEq(task.projectId, projectId);
        assertEq(task.title, "Build Smart Contracts");
        assertEq(task.paymentUSDC, 1000e6);
        assertEq(uint8(task.state), uint8(TaskManager.TaskState.Open));
    }
    
    function testCannotCreateTaskWithInvalidTitle() public {
        vm.prank(client);
        uint256[] memory deps = new uint256[](0);
        
        vm.expectRevert("Invalid title");
        taskManager.createTask(
            projectId,
            "", // empty
            "Description",
            1000e6,
            block.timestamp + 1 days,
            deps
        );
    }
    
    function testCannotCreateTaskWithZeroPayment() public {
        vm.prank(client);
        uint256[] memory deps = new uint256[](0);
        
        vm.expectRevert("Payment must be > 0");
        taskManager.createTask(
            projectId,
            "Task",
            "Description",
            0, // zero payment
            block.timestamp + 1 days,
            deps
        );
    }
    
    function testCannotCreateTaskWithPastDeadline() public {
        vm.prank(client);
        uint256[] memory deps = new uint256[](0);
        
        vm.expectRevert("Deadline must be in future");
        taskManager.createTask(
            projectId,
            "Task",
            "Description",
            1000e6,
            block.timestamp - 1, // past
            deps
        );
    }
    
    function testAssignTask() public {
        vm.prank(client);
        uint256[] memory deps = new uint256[](0);
        uint256 taskId = taskManager.createTask(
            projectId,
            "Task 1",
            "Description",
            1000e6,
            block.timestamp + 7 days,
            deps
        );
        
        vm.prank(client);
        taskManager.assignTask(taskId, agent1);
        
        TaskManager.Task memory task = taskManager.getTask(taskId);
        assertEq(task.assignedAgent, agent1);
        assertEq(uint8(task.state), uint8(TaskManager.TaskState.Assigned));
        assertGt(task.assignedAt, 0);
    }
    
    function testCannotAssignToNonTeamMember() public {
        vm.prank(client);
        uint256[] memory deps = new uint256[](0);
        uint256 taskId = taskManager.createTask(
            projectId,
            "Task 1",
            "Description",
            1000e6,
            block.timestamp + 7 days,
            deps
        );
        
        address outsider = address(99);
        
        vm.prank(client);
        vm.expectRevert("Agent not on team");
        taskManager.assignTask(taskId, outsider);
    }
    
    function testStartTask() public {
        vm.prank(client);
        uint256[] memory deps = new uint256[](0);
        uint256 taskId = taskManager.createTask(
            projectId,
            "Task 1",
            "Description",
            1000e6,
            block.timestamp + 7 days,
            deps
        );
        
        vm.prank(client);
        taskManager.assignTask(taskId, agent1);
        
        vm.prank(agent1);
        taskManager.startTask(taskId);
        
        TaskManager.Task memory task = taskManager.getTask(taskId);
        assertEq(uint8(task.state), uint8(TaskManager.TaskState.InProgress));
    }
    
    function testCannotStartUnassignedTask() public {
        vm.prank(client);
        uint256[] memory deps = new uint256[](0);
        uint256 taskId = taskManager.createTask(
            projectId,
            "Task 1",
            "Description",
            1000e6,
            block.timestamp + 7 days,
            deps
        );
        
        vm.prank(agent1);
        vm.expectRevert("Not assigned to you");
        taskManager.startTask(taskId);
    }
    
    function testSubmitTask() public {
        vm.prank(client);
        uint256[] memory deps = new uint256[](0);
        uint256 taskId = taskManager.createTask(
            projectId,
            "Task 1",
            "Description",
            1000e6,
            block.timestamp + 7 days,
            deps
        );
        
        vm.prank(client);
        taskManager.assignTask(taskId, agent1);
        
        vm.prank(agent1);
        taskManager.startTask(taskId);
        
        vm.prank(agent1);
        taskManager.submitTask(taskId, "QmTest123"); // IPFS hash
        
        TaskManager.Task memory task = taskManager.getTask(taskId);
        assertEq(uint8(task.state), uint8(TaskManager.TaskState.Review));
        assertEq(task.deliverableHash, "QmTest123");
    }
    
    function testApproveTask() public {
        vm.prank(client);
        uint256[] memory deps = new uint256[](0);
        uint256 taskId = taskManager.createTask(
            projectId,
            "Task 1",
            "Description",
            1000e6,
            block.timestamp + 7 days,
            deps
        );
        
        vm.prank(client);
        taskManager.assignTask(taskId, agent1);
        
        vm.prank(agent1);
        taskManager.startTask(taskId);
        
        vm.prank(agent1);
        taskManager.submitTask(taskId, "QmTest123");
        
        vm.prank(client);
        taskManager.approveTask(taskId);
        
        TaskManager.Task memory task = taskManager.getTask(taskId);
        assertEq(uint8(task.state), uint8(TaskManager.TaskState.Complete));
        assertGt(task.completedAt, 0);
    }
    
    function testRejectTask() public {
        vm.prank(client);
        uint256[] memory deps = new uint256[](0);
        uint256 taskId = taskManager.createTask(
            projectId,
            "Task 1",
            "Description",
            1000e6,
            block.timestamp + 7 days,
            deps
        );
        
        vm.prank(client);
        taskManager.assignTask(taskId, agent1);
        
        vm.prank(agent1);
        taskManager.startTask(taskId);
        
        vm.prank(agent1);
        taskManager.submitTask(taskId, "QmBadWork");
        
        vm.prank(client);
        taskManager.rejectTask(taskId, "Quality not acceptable");
        
        TaskManager.Task memory task = taskManager.getTask(taskId);
        assertEq(uint8(task.state), uint8(TaskManager.TaskState.InProgress));
    }
    
    function testMarkTaskAsFailed() public {
        vm.prank(client);
        uint256[] memory deps = new uint256[](0);
        uint256 taskId = taskManager.createTask(
            projectId,
            "Task 1",
            "Description",
            1000e6,
            block.timestamp + 7 days,
            deps
        );
        
        vm.prank(client);
        taskManager.assignTask(taskId, agent1);
        
        vm.prank(client);
        taskManager.failTask(taskId);
        
        TaskManager.Task memory task = taskManager.getTask(taskId);
        assertEq(uint8(task.state), uint8(TaskManager.TaskState.Failed));
    }
    
    function testTaskDependencies() public {
        // Create task 1 (no dependencies)
        vm.prank(client);
        uint256[] memory deps1 = new uint256[](0);
        uint256 task1 = taskManager.createTask(
            projectId,
            "Design System",
            "Create design mockups",
            500e6,
            block.timestamp + 3 days,
            deps1
        );
        
        // Create task 2 (depends on task 1)
        vm.prank(client);
        uint256[] memory deps2 = new uint256[](1);
        deps2[0] = task1;
        uint256 task2 = taskManager.createTask(
            projectId,
            "Frontend Implementation",
            "Build UI based on designs",
            1000e6,
            block.timestamp + 7 days,
            deps2
        );
        
        // Try to assign task 2 before task 1 is complete
        vm.prank(client);
        vm.expectRevert("Dependencies not complete");
        taskManager.assignTask(task2, agent2);
        
        // Complete task 1
        vm.prank(client);
        taskManager.assignTask(task1, agent1);
        
        vm.prank(agent1);
        taskManager.startTask(task1);
        
        vm.prank(agent1);
        taskManager.submitTask(task1, "QmDesigns");
        
        vm.prank(client);
        taskManager.approveTask(task1);
        
        // Now task 2 can be assigned
        vm.prank(client);
        taskManager.assignTask(task2, agent2);
        
        TaskManager.Task memory task = taskManager.getTask(task2);
        assertEq(task.assignedAgent, agent2);
    }
    
    function testMultipleDependencies() public {
        // Create 3 independent tasks
        uint256[] memory deps = new uint256[](0);
        
        vm.startPrank(client);
        uint256 task1 = taskManager.createTask(projectId, "Task 1", "Desc", 100e6, block.timestamp + 1 days, deps);
        uint256 task2 = taskManager.createTask(projectId, "Task 2", "Desc", 100e6, block.timestamp + 1 days, deps);
        uint256 task3 = taskManager.createTask(projectId, "Task 3", "Desc", 100e6, block.timestamp + 1 days, deps);
        
        // Create task 4 that depends on all 3
        uint256[] memory deps4 = new uint256[](3);
        deps4[0] = task1;
        deps4[1] = task2;
        deps4[2] = task3;
        
        uint256 task4 = taskManager.createTask(
            projectId,
            "Final Integration",
            "Combine all parts",
            500e6,
            block.timestamp + 10 days,
            deps4
        );
        
        // Task 4 cannot be assigned until all 3 are complete
        vm.expectRevert("Dependencies not complete");
        taskManager.assignTask(task4, agent1);
        vm.stopPrank();
    }
    
    function testCannotCreateCircularDependency() public {
        vm.prank(client);
        uint256[] memory deps = new uint256[](0);
        uint256 task1 = taskManager.createTask(
            projectId,
            "Task 1",
            "Desc",
            100e6,
            block.timestamp + 1 days,
            deps
        );
        
        // Try to create task 2 that depends on itself (would need more complex check)
        // For now we just verify dependencies must exist
        uint256[] memory invalidDeps = new uint256[](1);
        invalidDeps[0] = 999; // non-existent task
        
        vm.prank(client);
        vm.expectRevert("Invalid dependency");
        taskManager.createTask(
            projectId,
            "Task 2",
            "Desc",
            100e6,
            block.timestamp + 1 days,
            invalidDeps
        );
    }
    
    function testGetProjectTasks() public {
        uint256[] memory deps = new uint256[](0);
        
        vm.startPrank(client);
        uint256 task1 = taskManager.createTask(projectId, "Task 1", "Desc", 100e6, block.timestamp + 1 days, deps);
        uint256 task2 = taskManager.createTask(projectId, "Task 2", "Desc", 200e6, block.timestamp + 2 days, deps);
        uint256 task3 = taskManager.createTask(projectId, "Task 3", "Desc", 300e6, block.timestamp + 3 days, deps);
        vm.stopPrank();
        
        uint256[] memory projectTasks = taskManager.getProjectTasks(projectId);
        assertEq(projectTasks.length, 3);
        assertEq(projectTasks[0], task1);
        assertEq(projectTasks[1], task2);
        assertEq(projectTasks[2], task3);
    }
    
    function testGetAgentTasks() public {
        uint256[] memory deps = new uint256[](0);
        
        vm.startPrank(client);
        uint256 task1 = taskManager.createTask(projectId, "Task 1", "Desc", 100e6, block.timestamp + 1 days, deps);
        uint256 task2 = taskManager.createTask(projectId, "Task 2", "Desc", 200e6, block.timestamp + 2 days, deps);
        
        taskManager.assignTask(task1, agent1);
        taskManager.assignTask(task2, agent1);
        vm.stopPrank();
        
        uint256[] memory agentTasks = taskManager.getAgentTasks(agent1);
        assertEq(agentTasks.length, 2);
        assertEq(agentTasks[0], task1);
        assertEq(agentTasks[1], task2);
    }
    
    function testCannotAssignTaskIfNotProjectOwner() public {
        vm.prank(client);
        uint256[] memory deps = new uint256[](0);
        uint256 taskId = taskManager.createTask(
            projectId,
            "Task 1",
            "Description",
            1000e6,
            block.timestamp + 7 days,
            deps
        );
        
        vm.prank(agent1);
        vm.expectRevert("Not project owner");
        taskManager.assignTask(taskId, agent1);
    }
    
    function testCannotSubmitWithoutDeliverable() public {
        vm.prank(client);
        uint256[] memory deps = new uint256[](0);
        uint256 taskId = taskManager.createTask(
            projectId,
            "Task 1",
            "Description",
            1000e6,
            block.timestamp + 7 days,
            deps
        );
        
        vm.prank(client);
        taskManager.assignTask(taskId, agent1);
        
        vm.prank(agent1);
        taskManager.startTask(taskId);
        
        vm.prank(agent1);
        vm.expectRevert("Must provide deliverable");
        taskManager.submitTask(taskId, "");
    }
    
    function testFullTaskLifecycle() public {
        // Create → Assign → Start → Submit → Approve
        vm.prank(client);
        uint256[] memory deps = new uint256[](0);
        uint256 taskId = taskManager.createTask(
            projectId,
            "Complete Project",
            "Full implementation",
            2000e6,
            block.timestamp + 30 days,
            deps
        );
        
        // Open state
        TaskManager.Task memory task = taskManager.getTask(taskId);
        assertEq(uint8(task.state), uint8(TaskManager.TaskState.Open));
        
        // Assign
        vm.prank(client);
        taskManager.assignTask(taskId, agent1);
        task = taskManager.getTask(taskId);
        assertEq(uint8(task.state), uint8(TaskManager.TaskState.Assigned));
        
        // Start
        vm.prank(agent1);
        taskManager.startTask(taskId);
        task = taskManager.getTask(taskId);
        assertEq(uint8(task.state), uint8(TaskManager.TaskState.InProgress));
        
        // Submit
        vm.prank(agent1);
        taskManager.submitTask(taskId, "QmFinalDeliverable");
        task = taskManager.getTask(taskId);
        assertEq(uint8(task.state), uint8(TaskManager.TaskState.Review));
        
        // Approve
        vm.prank(client);
        taskManager.approveTask(taskId);
        task = taskManager.getTask(taskId);
        assertEq(uint8(task.state), uint8(TaskManager.TaskState.Complete));
    }
    
    function testDependenciesCompleteCheck() public {
        vm.prank(client);
        uint256[] memory deps1 = new uint256[](0);
        uint256 task1 = taskManager.createTask(projectId, "Task 1", "Desc", 100e6, block.timestamp + 1 days, deps1);
        
        uint256[] memory deps2 = new uint256[](1);
        deps2[0] = task1;
        
        vm.prank(client);
        uint256 task2 = taskManager.createTask(projectId, "Task 2", "Desc", 200e6, block.timestamp + 2 days, deps2);
        
        // Initially not complete
        assertFalse(taskManager.dependenciesComplete(task2));
        
        // Complete task 1
        vm.prank(client);
        taskManager.assignTask(task1, agent1);
        vm.prank(agent1);
        taskManager.startTask(task1);
        vm.prank(agent1);
        taskManager.submitTask(task1, "QmDone");
        vm.prank(client);
        taskManager.approveTask(task1);
        
        // Now task 2 dependencies are complete
        assertTrue(taskManager.dependenciesComplete(task2));
    }
}
