// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
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
    // همان آدرس روتر رابین‌هود که در کدهای قبلی‌ات بود
    address constant ROUTER = 0x77bF00A6A90c600f214b34BAFBB7918c0cF113A8;

    function run() external {
        address tokenA = vm.envAddress("TOKEN_A");
        address tokenB = vm.envAddress("TOKEN_B");

        uint256[] memory pks = new uint256[](3);
        pks[0] = vm.envUint("PK_1");
        pks[1] = vm.envUint("PK_2");
        pks[2] = vm.envUint("PK_3");

        for (uint256 i = 0; i < pks.length; i++) {
            uint256 pk = pks[i];
            address wallet = vm.addr(pk);

            uint256 balance = IERC20(tokenA).balanceOf(wallet);
            if (balance == 0) continue; // اگر ولت توکن نداشت، برو سراغ ولت بعدی

            // تولید یک درصد رندوم بین 1 تا 15 درصدِ موجودی ولت
            uint256 randomPercent = (uint256(keccak256(abi.encodePacked(block.timestamp, i, wallet))) % 15) + 1;
            uint256 amountToSwap = (balance * randomPercent) / 100;

            if (amountToSwap == 0) continue;

            // وصل شدن به شبکه با هویتِ کیف پولِ i
            vm.startBroadcast(pk);

            // ۱. فراخوانی تابع Approve
            IERC20(tokenA).approve(ROUTER, amountToSwap);

            // ۲. فراخوانی تابع Swap
            address[] memory path = new address[](2);
            path[0] = tokenA;
            path[1] = tokenB;

            IUniswapV2Router(ROUTER).swapExactTokensForTokens(
                amountToSwap,
                0, // حداقل دریافتی صفر (چون تستی است، نگران اسلیپیج نیستیم)
                path,
                wallet,
                block.timestamp + 300
            );

            vm.stopBroadcast();
        }
    }
}
