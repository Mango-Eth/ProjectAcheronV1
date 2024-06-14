// SPDX-License-Identifier: Built by Mango
pragma solidity ^0.8.20;

import "../../Instances.sol";

contract ReadingTestnet is Instances {

    address __acheron__ = 0xe029232F41EC0f5654271eDc4D4A86D4Dbe7972a;
    address __wethSkirk__ = 0x8814c16652cbE4Bd17Cf07d58577A842978A645B;

    /*
    forge test --fork-url=https://rpc.testnet.fantom.network/ --match-test testSimulateCollectFtmTestnet -vvv
    */
    function testSimulateCollectFtmTestnet() public {

        address token0 = IUniswapV3Pool(__wethSkirk__).token0();
        address token1 = IUniswapV3Pool(__wethSkirk__).token1();

        address alice = address(0x123123);

        int24 tl = 68000;
        int24 tu = 99000;

        // Simulating collection:

        vm.startPrank(__acheron__);
        IUniswapV3Pool(__wethSkirk__).burn(
            tl,
            tu,
            0
        );
        IUniswapV3Pool(__wethSkirk__).collect(
            alice, 
            tl,
            tu,
            2**128-1,
            2**128-1
        );
        vm.startPrank(__acheron__);
        uint256 balance0 = IERC20(token0).balanceOf(alice);
        uint256 balance1 = IERC20(token1).balanceOf(alice);
        console.log(balance0, balance1);
    }
}