// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

contract AutoSwapperScript is Script {
    function run() external {
        uint256 masterKey = vm.envUint("MASTER_KEY");
        address masterWallet = vm.addr(masterKey);

        address tokenA = vm.envAddress("TOKEN_A");
        address tokenB = vm.envAddress("TOKEN_B");
        address routerAddress = vm.envAddress("ROUTER_ADDRESS");

        uint256 amountIn = vm.envOr("SWAP_AMOUNT", uint256(1.2e7));

        require(masterKey != 0, "Error: MASTER_KEY not set");
        require(tokenA != address(0), "Error: TOKEN_A not set");
        require(tokenB != address(0), "Error: TOKEN_B not set");
        require(routerAddress != address(0), "Error: ROUTER_ADDRESS not set");

        console.log("=== AutoSwapper - Single Wallet Mode ===");
        console.log("Master Wallet:", masterWallet);
        console.log("Token A:", tokenA);
        console.log("Token B:", tokenB);
        console.log("Router:", routerAddress);

        IUniswapV2Router router = IUniswapV2Router(routerAddress);

        uint256 balance = IERC20(tokenA).balanceOf(masterWallet);
        console.log("Token A Balance:", balance);

        if (balance == 0) {
            console.log("Skip: Zero balance for Token A");
            return;
        }

        if (balance < amountIn) {
            amountIn = balance;
        }

        console.log("Swap Amount:", amountIn);

        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;

        uint256 deadline = block.timestamp + 1200;

        vm.startBroadcast(masterKey);

        IERC20(tokenA).approve(routerAddress, amountIn);

        try router.swapExactTokensForTokens(
            amountIn,
            0,
            path,
            masterWallet,
            deadline
        ) returns (uint256[] memory amounts) {
            console.log("Swap Succeeded!");
            console.log("Token A Spent:", amounts[0]);
            console.log("Token B Received:", amounts[1]);
        } catch Error(string memory reason) {
            console.log("Swap Failed:", reason);
        } catch {
            console.log("Swap Failed: low-level revert");
        }

        vm.stopBroadcast();
    }
}
