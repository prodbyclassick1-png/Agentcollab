// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/ProjectRegistry.sol";
import "../src/TaskManager.sol";
import "../src/RevenueDistributor.sol";
import "../src/TeamRegistry.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address platformTreasury = vm.envAddress("PLATFORM_TREASURY");
        address usdcAddress = vm.envAddress("USDC_ADDRESS");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy ProjectRegistry
        ProjectRegistry projectRegistry = new ProjectRegistry();
        console.log("ProjectRegistry deployed:", address(projectRegistry));
        
        // 2. Deploy TaskManager
        TaskManager taskManager = new TaskManager(address(projectRegistry));
        console.log("TaskManager deployed:", address(taskManager));
        
        // 3. Deploy RevenueDistributor
        RevenueDistributor revenueDistributor = new RevenueDistributor(
            address(projectRegistry),
            address(taskManager),
            usdcAddress,
            platformTreasury
        );
        console.log("RevenueDistributor deployed:", address(revenueDistributor));
        
        // 4. Deploy TeamRegistry
        TeamRegistry teamRegistry = new TeamRegistry(address(projectRegistry));
        console.log("TeamRegistry deployed:", address(teamRegistry));
        
        vm.stopBroadcast();
        
        // Log summary
        console.log("\n=== Deployment Complete ===");
        console.log("Network: Base Mainnet (Chain ID: 8453)");
        console.log("ProjectRegistry:", address(projectRegistry));
        console.log("TaskManager:", address(taskManager));
        console.log("RevenueDistributor:", address(revenueDistributor));
        console.log("TeamRegistry:", address(teamRegistry));
        console.log("Platform Treasury:", platformTreasury);
        console.log("USDC:", usdcAddress);
    }
}
