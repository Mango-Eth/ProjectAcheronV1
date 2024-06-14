// SPDX-License-Identifier: Built by Mango
pragma solidity ^0.8.20;

import "../Methods.sol";

contract PotionMinting is Methods {

    /*
    * Since potion uses the DAI_USDC pool to mint, it only has 5 different possible ticks.
    * Testing in said range.
    */
    function testMintingPotionInAllPossibleranges() public {
        int24 t1 = -276322;
        int24 t3 = -276323;
        int24 t5 = -276324;
        int24 t2 = -276325;
        int24 t4 = -276326;
        // (uint160 sqrtP_n,int24 tck,,,,,) = IUniswapV3Pool(pool_dai_usdc).slot0();
        // console.log("Current tick:", uint256(uint24(-tck)));
        // console.log(sqrtP_n, _tickToQ96(t1), 18, 6);

        _arbitragePool(pool_dai_usdc, _tickToQ96(t1));
        _mintPotions(alice.addr);

        _arbitragePool(pool_dai_usdc, _tickToQ96(t2));
        _mintPotions(alice.addr);

        _arbitragePool(pool_dai_usdc, _tickToQ96(t3));
        _mintPotions(alice.addr);

        _arbitragePool(pool_dai_usdc, _tickToQ96(t4));
        _mintPotions(alice.addr);

        _arbitragePool(pool_dai_usdc, _tickToQ96(t5));
        _mintPotions(alice.addr);
    }

    /*
    * Minting all 7000 possible Potions
    * Last mint should be reverting with A:MM.
    */
    function testMintAllPotions() public {
        for(uint256 i; i < 7001; i++){
            _mintPotions(alice.addr);
        }
        _mintSkirk(3000e18, alice.addr);
        vm.startPrank(alice.addr);
        vm.expectRevert();
        potionBlue.mint();
        vm.stopPrank();
    }

    /*
    * This test proves that any price outside the grid, will revert.
    * Expected to revert.
    */
    function testExpectedRevertDueToWrongPrice() public {
        _mintPotions(alice.addr);
        int24 t1 = -276327;
        int24 t2 = -276321;

        _arbitragePool(pool_dai_usdc, _tickToQ96(t1));
        _mintSkirk(1000e18, alice.addr);
        vm.startPrank(alice.addr);
        vm.expectRevert();
        potionBlue.mint();
        vm.stopPrank();

        _arbitragePool(pool_dai_usdc, _tickToQ96(t2));
        _mintSkirk(1000e18, alice.addr);
        vm.startPrank(alice.addr);
        vm.expectRevert();
        potionBlue.mint();
        vm.stopPrank();
    }

    /*
    * Set up to simulate arbitrage.
    */
    function uniswapV3SwapCallback(
        int256 _amount0Owed,
        int256 _amount1Owed,
        bytes calldata
    ) public override virtual {
        address pool = msg.sender;
        address token0 = IUniswapV3Pool(pool).token0();
        address token1 = IUniswapV3Pool(pool).token1();
        // Handling xSkirk being a token:
        if(token0 == address(xSKIRK) && _amount0Owed > 0){
            _mintSkirk(uint256(_amount0Owed), address(0xddddead));
            vm.startPrank(address(0xddddead));
            xSKIRK.transfer(pool, uint256(_amount0Owed));
            vm.stopPrank();
        } else if(token1 == address(xSKIRK) && _amount1Owed > 0){
            _mintSkirk(uint256(_amount1Owed), address(0xddddead));
            vm.startPrank(address(0xddddead));
            xSKIRK.transfer(pool, uint256(_amount1Owed));
            vm.stopPrank();
        } else {    // Any other pool will use MockERC20:
            if(_amount0Owed > 0){
                vm.startPrank(address(0xddddead));
                MockERC20(token0).mint(uint256(_amount0Owed));
                MockERC20(token0).transfer(pool, uint256(_amount0Owed));
                vm.stopPrank();
            }
            if(_amount1Owed > 0){
                vm.startPrank(address(0xddddead));
                MockERC20(token1).mint(uint256(_amount1Owed));
                MockERC20(token1).transfer(pool, uint256(_amount1Owed));
                vm.stopPrank();
            }
        }
    }
}