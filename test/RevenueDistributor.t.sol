// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/ProjectRegistry.sol";
import "../src/TaskManager.sol";
import "../src/RevenueDistributor.sol";

// Mock USDC contract for testing
contract MockUSDC {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;
        return true;
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }
}

contract RevenueDistributorTest is Test {
    ProjectRegistry public registry;
    TaskManager public taskManager;
    RevenueDistributor public distributor;
    MockUSDC public usdc;
    
    address public owner = address(1);
    address public client = address(2);
    address public agent1 = address(3);
    address public agent2 = address(4);
    address public treasury = address(5);
    
    uint256 public projectId;
    
    function setUp() public {
        vm.warp(1000000);
        
        vm.prank(owner);
        registry = new ProjectRegistry();
        
        vm.prank(owner);
        taskManager = new TaskManager(address(registry));
        
        // Deploy mock USDC
        usdc = new MockUSDC();
        
        vm.prank(owner);
        distributor = new RevenueDistributor(
            address(registry),
            address(taskManager),
            address(usdc),
            treasury
        );
        
        // Mint USDC to client
        usdc.mint(client, 10000e6); // 10,000 USDC
        
        // Create and setup project
        vm.prank(client);
        projectId = registry.createProject(
            "Test Project",
            "Revenue distribution test",
            5000e6,
            2,
            false
        );
        
        vm.startPrank(client);
        registry.startRecruiting(projectId);
        registry.addAgent(projectId, agent1);
        registry.addAgent(projectId, agent2);
        registry.startProject(projectId);
        vm.stopPrank();
    }
    
    function testDepositFunds() public {
        uint256 amount = 1000e6;
        
        vm.startPrank(client);
        usdc.approve(address(distributor), amount);
        distributor.depositFunds(projectId, amount);
        vm.stopPrank();
        
        RevenueDistributor.EscrowBalance memory balance = distributor.getProjectBalance(projectId);
        assertEq(balance.totalDeposited, amount);
        assertEq(balance.totalDistributed, 0);
    }
    
    function testCannotDepositZero() public {
        vm.startPrank(client);
        usdc.approve(address(distributor), 1000e6);
        
        vm.expectRevert("Amount must be > 0");
        distributor.depositFunds(projectId, 0);
        vm.stopPrank();
    }
    
    function testCannotDepositIfNotOwner() public {
        vm.startPrank(agent1);
        usdc.mint(agent1, 1000e6);
        usdc.approve(address(distributor), 1000e6);
        
        vm.expectRevert("Not project owner");
        distributor.depositFunds(projectId, 1000e6);
        vm.stopPrank();
    }
    
    function testReleaseTaskPayment() public {
        // Deposit funds
        uint256 depositAmount = 2000e6;
        vm.startPrank(client);
        usdc.approve(address(distributor), depositAmount);
        distributor.depositFunds(projectId, depositAmount);
        vm.stopPrank();
        
        // Create and complete a task
        uint256[] memory deps = new uint256[](0);
        uint256 taskPayment = 1000e6;
        
        vm.startPrank(client);
        uint256 taskId = taskManager.createTask(
            projectId,
            "Smart Contracts",
            "Build contracts",
            taskPayment,
            block.timestamp + 7 days,
            deps
        );
        
        taskManager.assignTask(taskId, agent1);
        vm.stopPrank();
        
        vm.prank(agent1);
        taskManager.startTask(taskId);
        
        vm.prank(agent1);
        taskManager.submitTask(taskId, "QmDeliverable");
        
        vm.prank(client);
        taskManager.approveTask(taskId);
        
        // Release payment
        distributor.releaseTaskPayment(taskId);
        
        // Check agent earnings (1000 - 2% fee = 980)
        uint256 expectedEarnings = taskPayment * 98 / 100;
        assertEq(distributor.getAgentEarnings(agent1), expectedEarnings);
        
        // Check escrow balance
        RevenueDistributor.EscrowBalance memory balance = distributor.getProjectBalance(projectId);
        assertEq(balance.totalDistributed, taskPayment);
        assertEq(balance.platformFeeCollected, taskPayment * 2 / 100);
    }
    
    function testCannotReleasePaymentTwice() public {
        // Setup: deposit and complete task
        vm.startPrank(client);
        usdc.approve(address(distributor), 2000e6);
        distributor.depositFunds(projectId, 2000e6);
        
        uint256[] memory deps = new uint256[](0);
        uint256 taskId = taskManager.createTask(
            projectId,
            "Task",
            "Desc",
            1000e6,
            block.timestamp + 7 days,
            deps
        );
        taskManager.assignTask(taskId, agent1);
        vm.stopPrank();
        
        vm.prank(agent1);
        taskManager.startTask(taskId);
        
        vm.prank(agent1);
        taskManager.submitTask(taskId, "QmDone");
        
        vm.prank(client);
        taskManager.approveTask(taskId);
        
        // Release once
        distributor.releaseTaskPayment(taskId);
        
        // Try to release again
        vm.expectRevert("Task already paid");
        distributor.releaseTaskPayment(taskId);
    }
    
    function testCannotReleaseIfTaskNotComplete() public {
        vm.startPrank(client);
        usdc.approve(address(distributor), 1000e6);
        distributor.depositFunds(projectId, 1000e6);
        
        uint256[] memory deps = new uint256[](0);
        uint256 taskId = taskManager.createTask(
            projectId,
            "Task",
            "Desc",
            500e6,
            block.timestamp + 7 days,
            deps
        );
        vm.stopPrank();
        
        vm.expectRevert("Task not complete");
        distributor.releaseTaskPayment(taskId);
    }
    
    function testCannotReleaseIfInsufficientEscrow() public {
        // Don't deposit enough funds
        vm.startPrank(client);
        usdc.approve(address(distributor), 500e6);
        distributor.depositFunds(projectId, 500e6); // Only 500
        
        uint256[] memory deps = new uint256[](0);
        uint256 taskId = taskManager.createTask(
            projectId,
            "Task",
            "Desc",
            1000e6, // Task costs 1000
            block.timestamp + 7 days,
            deps
        );
        taskManager.assignTask(taskId, agent1);
        vm.stopPrank();
        
        vm.prank(agent1);
        taskManager.startTask(taskId);
        
        vm.prank(agent1);
        taskManager.submitTask(taskId, "QmDone");
        
        vm.prank(client);
        taskManager.approveTask(taskId);
        
        vm.expectRevert("Insufficient escrow funds");
        distributor.releaseTaskPayment(taskId);
    }
    
    function testAgentWithdraw() public {
        // Setup: complete task and release payment
        vm.startPrank(client);
        usdc.approve(address(distributor), 2000e6);
        distributor.depositFunds(projectId, 2000e6);
        
        uint256[] memory deps = new uint256[](0);
        uint256 taskId = taskManager.createTask(
            projectId,
            "Task",
            "Desc",
            1000e6,
            block.timestamp + 7 days,
            deps
        );
        taskManager.assignTask(taskId, agent1);
        vm.stopPrank();
        
        vm.prank(agent1);
        taskManager.startTask(taskId);
        
        vm.prank(agent1);
        taskManager.submitTask(taskId, "QmDone");
        
        vm.prank(client);
        taskManager.approveTask(taskId);
        
        distributor.releaseTaskPayment(taskId);
        
        // Agent withdraws
        uint256 expectedAmount = 1000e6 * 98 / 100;
        uint256 balanceBefore = usdc.balanceOf(agent1);
        
        vm.prank(agent1);
        distributor.withdraw();
        
        uint256 balanceAfter = usdc.balanceOf(agent1);
        assertEq(balanceAfter - balanceBefore, expectedAmount);
        assertEq(distributor.getAgentEarnings(agent1), 0);
    }
    
    function testCannotWithdrawWithZeroEarnings() public {
        vm.prank(agent1);
        vm.expectRevert("No earnings to withdraw");
        distributor.withdraw();
    }
    
    function testSetProjectSplit() public {
        RevenueDistributor.PaymentSplit[] memory splits = new RevenueDistributor.PaymentSplit[](2);
        splits[0] = RevenueDistributor.PaymentSplit({
            agent: agent1,
            basisPoints: 6000 // 60%
        });
        splits[1] = RevenueDistributor.PaymentSplit({
            agent: agent2,
            basisPoints: 4000 // 40%
        });
        
        vm.prank(client);
        distributor.setProjectSplit(projectId, splits);
        
        assertTrue(distributor.hasCustomSplit(projectId));
        
        RevenueDistributor.PaymentSplit[] memory retrieved = distributor.getProjectSplits(projectId);
        assertEq(retrieved.length, 2);
        assertEq(retrieved[0].agent, agent1);
        assertEq(retrieved[0].basisPoints, 6000);
        assertEq(retrieved[1].agent, agent2);
        assertEq(retrieved[1].basisPoints, 4000);
    }
    
    function testCannotSetSplitIfNotOwner() public {
        RevenueDistributor.PaymentSplit[] memory splits = new RevenueDistributor.PaymentSplit[](1);
        splits[0] = RevenueDistributor.PaymentSplit({
            agent: agent1,
            basisPoints: 10000
        });
        
        vm.prank(agent1);
        vm.expectRevert("Not project owner");
        distributor.setProjectSplit(projectId, splits);
    }
    
    function testCannotSetSplitWithWrongTotal() public {
        RevenueDistributor.PaymentSplit[] memory splits = new RevenueDistributor.PaymentSplit[](2);
        splits[0] = RevenueDistributor.PaymentSplit({
            agent: agent1,
            basisPoints: 5000 // 50%
        });
        splits[1] = RevenueDistributor.PaymentSplit({
            agent: agent2,
            basisPoints: 3000 // 30% - only 80% total!
        });
        
        vm.prank(client);
        vm.expectRevert("Splits must equal 100%");
        distributor.setProjectSplit(projectId, splits);
    }
    
    function testCannotSetEmptySplit() public {
        RevenueDistributor.PaymentSplit[] memory splits = new RevenueDistributor.PaymentSplit[](0);
        
        vm.prank(client);
        vm.expectRevert("Empty splits");
        distributor.setProjectSplit(projectId, splits);
    }
    
    function testDistributeProjectFunds() public {
        // Setup custom split
        RevenueDistributor.PaymentSplit[] memory splits = new RevenueDistributor.PaymentSplit[](2);
        splits[0] = RevenueDistributor.PaymentSplit({
            agent: agent1,
            basisPoints: 7000 // 70%
        });
        splits[1] = RevenueDistributor.PaymentSplit({
            agent: agent2,
            basisPoints: 3000 // 30%
        });
        
        vm.startPrank(client);
        distributor.setProjectSplit(projectId, splits);
        
        // Deposit funds
        uint256 amount = 1000e6;
        usdc.approve(address(distributor), amount);
        distributor.depositFunds(projectId, amount);
        
        vm.stopPrank();
        
        // Complete project (agent submits for review)
        vm.prank(agent1);
        registry.submitForReview(projectId);
        
        vm.prank(client);
        registry.completeProject(projectId);
        
        // Distribute
        distributor.distributeProjectFunds(projectId);
        
        // Check earnings (after 2% fee)
        uint256 afterFee = amount * 98 / 100;
        assertEq(distributor.getAgentEarnings(agent1), afterFee * 70 / 100);
        assertEq(distributor.getAgentEarnings(agent2), afterFee * 30 / 100);
    }
    
    function testCannotDistributeIfProjectNotComplete() public {
        // Setup split
        RevenueDistributor.PaymentSplit[] memory splits = new RevenueDistributor.PaymentSplit[](1);
        splits[0] = RevenueDistributor.PaymentSplit({
            agent: agent1,
            basisPoints: 10000
        });
        
        vm.startPrank(client);
        distributor.setProjectSplit(projectId, splits);
        usdc.approve(address(distributor), 1000e6);
        distributor.depositFunds(projectId, 1000e6);
        vm.stopPrank();
        
        // Project still active
        vm.expectRevert("Project not complete");
        distributor.distributeProjectFunds(projectId);
    }
    
    function testCannotDistributeWithoutCustomSplit() public {
        vm.startPrank(client);
        usdc.approve(address(distributor), 1000e6);
        distributor.depositFunds(projectId, 1000e6);
        vm.stopPrank();
        
        vm.prank(agent1);
        registry.submitForReview(projectId);
        
        vm.prank(client);
        registry.completeProject(projectId);
        
        vm.expectRevert("No custom split set");
        distributor.distributeProjectFunds(projectId);
    }
    
    function testWithdrawPlatformFees() public {
        // Complete a task
        vm.startPrank(client);
        usdc.approve(address(distributor), 2000e6);
        distributor.depositFunds(projectId, 2000e6);
        
        uint256[] memory deps = new uint256[](0);
        uint256 taskId = taskManager.createTask(
            projectId,
            "Task",
            "Desc",
            1000e6,
            block.timestamp + 7 days,
            deps
        );
        taskManager.assignTask(taskId, agent1);
        vm.stopPrank();
        
        vm.prank(agent1);
        taskManager.startTask(taskId);
        
        vm.prank(agent1);
        taskManager.submitTask(taskId, "QmDone");
        
        vm.prank(client);
        taskManager.approveTask(taskId);
        
        distributor.releaseTaskPayment(taskId);
        
        // Platform fee = 2% of 1000 = 20
        uint256 expectedFee = 1000e6 * 2 / 100;
        
        uint256 treasuryBefore = usdc.balanceOf(treasury);
        
        vm.prank(owner);
        distributor.withdrawPlatformFees(projectId);
        
        uint256 treasuryAfter = usdc.balanceOf(treasury);
        assertEq(treasuryAfter - treasuryBefore, expectedFee);
    }
    
    function testCannotWithdrawFeesIfNotOwner() public {
        vm.prank(client);
        vm.expectRevert();
        distributor.withdrawPlatformFees(projectId);
    }
    
    function testUpdateTreasury() public {
        address newTreasury = address(99);
        
        vm.prank(owner);
        distributor.updateTreasury(newTreasury);
        
        assertEq(distributor.platformTreasury(), newTreasury);
    }
    
    function testCannotUpdateTreasuryToZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert("Invalid address");
        distributor.updateTreasury(address(0));
    }
    
    function testMultipleTaskPayments() public {
        // Deposit funds
        vm.startPrank(client);
        usdc.approve(address(distributor), 5000e6);
        distributor.depositFunds(projectId, 5000e6);
        
        // Create 3 tasks
        uint256[] memory deps = new uint256[](0);
        uint256 task1 = taskManager.createTask(projectId, "Task 1", "Desc", 1000e6, block.timestamp + 7 days, deps);
        uint256 task2 = taskManager.createTask(projectId, "Task 2", "Desc", 1500e6, block.timestamp + 7 days, deps);
        uint256 task3 = taskManager.createTask(projectId, "Task 3", "Desc", 2000e6, block.timestamp + 7 days, deps);
        
        // Assign to different agents
        taskManager.assignTask(task1, agent1);
        taskManager.assignTask(task2, agent2);
        taskManager.assignTask(task3, agent1);
        vm.stopPrank();
        
        // Complete all tasks
        vm.prank(agent1);
        taskManager.startTask(task1);
        vm.prank(agent1);
        taskManager.submitTask(task1, "Qm1");
        vm.prank(client);
        taskManager.approveTask(task1);
        distributor.releaseTaskPayment(task1);
        
        vm.prank(agent2);
        taskManager.startTask(task2);
        vm.prank(agent2);
        taskManager.submitTask(task2, "Qm2");
        vm.prank(client);
        taskManager.approveTask(task2);
        distributor.releaseTaskPayment(task2);
        
        vm.prank(agent1);
        taskManager.startTask(task3);
        vm.prank(agent1);
        taskManager.submitTask(task3, "Qm3");
        vm.prank(client);
        taskManager.approveTask(task3);
        distributor.releaseTaskPayment(task3);
        
        // Check earnings
        uint256 agent1Expected = (1000e6 + 2000e6) * 98 / 100;
        uint256 agent2Expected = 1500e6 * 98 / 100;
        
        assertEq(distributor.getAgentEarnings(agent1), agent1Expected);
        assertEq(distributor.getAgentEarnings(agent2), agent2Expected);
    }
}
