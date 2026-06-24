// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract AutoSwapperScript is Script {
    // آدرس روتر رابینهود تستنت
    address constant ROUTER = 0x77bF00A6A90c600f214b34BAFBB7918c0cF113A8;

    function run() external {
        address tokenA = vm.envAddress("TOKEN_A");
        address tokenB = vm.envAddress("TOKEN_B");

        uint256[] memory pks = new uint256[](3);
        pks[0] = vm.envUint("KEY_1");
        pks[1] = vm.envUint("KEY_2");
        pks[2] = vm.envUint("KEY_3");

        for (uint256 i = 0; i < pks.length; i++) {
            uint256 pk = pks[i];
            address wallet = vm.addr(pk);

            uint256 balanceA = IERC20(tokenA).balanceOf(wallet);
            uint256 balanceB = IERC20(tokenB).balanceOf(wallet);

            address srcToken;
            address dstToken;
            uint256 balance;

            // سواپ هوشمند دوطرفه جهت جلوگیری از قفل شدن ربات روی موجودی صفر توکن A
            if (balanceA > balanceB && balanceA > 0) {
                srcToken = tokenA;
                dstToken = tokenB;
                balance = balanceA;
            } else if (balanceB > 0) {
                srcToken = tokenB;
                dstToken = tokenA;
                balance = balanceB;
            } else {
                continue; // هر دو موجودی صفر هستند، رفتن به ولت بعدی
            }

            // تولید یک درصد رندوم بین 1 تا 15 درصدِ موجودی ولت
            uint256 randomPercent = (uint256(keccak256(abi.encodePacked(block.timestamp, i, wallet))) % 15) + 1;
            uint256 amountToSwap = (balance * randomPercent) / 100;

            if (amountToSwap == 0) continue;

            // وصل شدن به شبکه با هویتِ کیف پولِ i
            vm.startBroadcast(pk);

            // بررسی allowance جهت جلوگیری از فراخوانی تایید (approve) غیرضروری و کاهش گاز مصرفی
            uint256 currentAllowance = IERC20(srcToken).allowance(wallet, ROUTER);
            if (currentAllowance < amountToSwap) {
                // تایید مقدار بی نهایت جهت بهینه سازی در تراکنش های بعدی
                IERC20(srcToken).approve(ROUTER, type(uint256).max);
            }

            // تعریف مسیر سواپ (سواپ دوطرفه هوشمند)
            address[] memory path = new address[](2);
            path[0] = srcToken;
            path[1] = dstToken;

            IUniswapV2Router(ROUTER).swapExactTokensForTokens(
                amountToSwap,
                0, // slippage تستی صفر
                path,
                wallet,
                block.timestamp + 300
            );

            vm.stopBroadcast();
        }
    }
}
