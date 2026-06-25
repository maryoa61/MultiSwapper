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
        // دریافت کلیدها و کانفیگ توکن‌ها از متغیرهای محیطی
        uint256 key1 = vm.envOr("KEY_1", uint256(0));
        uint256 key2 = vm.envOr("KEY_2", uint256(0));
        uint256 key3 = vm.envOr("KEY_3", uint256(0));
        
        address tokenA = vm.envOr("TOKEN_A", address(0));
        address tokenB = vm.envOr("TOKEN_B", address(0));
        
        // آدرس روتری که چکسام آن دقیقاً توسط کامپایلر تایید شده است
        address routerAddress = vm.envOr("ROUTER_ADDRESS", 0x77bF00A6A90c600f214b34BAFBB7918c0cf113A8);
        
        if (routerAddress == address(0)) {
            console.log("Error: Router address is address(0)");
            return;
        }

        if (tokenA == address(0) || tokenB == address(0)) {
            console.log("Error: TOKEN_A or TOKEN_B is not set in environment");
            return;
        }

        IUniswapV2Router router = IUniswapV2Router(routerAddress);
        
        // آرایه‌ای از کلیدها جهت پردازش خودکار
        uint256[3] memory keys = [key1, key2, key3];
        
        for (uint256 i = 0; i < keys.length; i++) {
            uint256 key = keys[i];
            if (key == 0) continue;
            
            address swapperAddress = vm.addr(key);
            console.log("-----------------------------------------");
            console.log("Processing swap for address:", swapperAddress);
            
            uint256 balanceA = IERC20(tokenA).balanceOf(swapperAddress);
            console.log("Token A balance:", balanceA);
            
            if (balanceA == 0) {
                console.log("Skip: Zero balance for Token A");
                continue;
            }
            
            // مقدار پیش‌فرض تراکنش (بر اساس لاگ ارسالی شما 1.2e7)
            uint256 amountIn = 1.2e7; 
            if (balanceA < amountIn) {
                amountIn = balanceA;
            }
            
            address[] memory path = new address[](2);
            path[0] = tokenA;
            path[1] = tokenB;
            
            // تعیین ددلاین معتبر بر اساس بلاک‌تایم جاری شبکه (۲۰ دقیقه آینده) جهت جلوگیری از انقضا
            uint256 deadline = block.timestamp + 1200;
            
            vm.startBroadcast(key);
            
            // تایید دسترسی به روت برای توکن A
            IERC20(tokenA).approve(address(router), amountIn);
            
            // اجرای سوآپ همراه با مدیریت خطاها
            try router.swapExactTokensForTokens(
                amountIn,
                0, // تحمل لغزش قیمت 100٪ برای تراکنش‌های تست‌نت
                path,
                swapperAddress,
                deadline
            ) returns (uint256[] memory amounts) {
                console.log("Swap Succeeded! Tokens received:", amounts[1]);
            } catch Error(string memory reason) {
                console.log("Swap Failed with error reason:", reason);
            } catch {
                console.log("Swap Failed with direct low-level revert");
            }
            
            vm.stopBroadcast();
        }
    }
}
