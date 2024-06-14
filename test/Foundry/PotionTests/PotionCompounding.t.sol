// SPDX-License-Identifier: Built by Mango
pragma solidity ^0.8.20;

import "../Methods.sol";

contract PotionCompounding is Methods {

    /*
    * Compounding working in all possible 5 ticks.
    * Minting some potions, rebasing, minting, compounding, mintingAll().
    */

    /*
    * Random flow.
    */
    function testRandomFlowOfProtocol() public {
        _mintPotions(alice.addr);
        _mintPotions(alice.addr);
        _mintPotions(alice.addr);
        _mintPotions(alice.addr);
        _mintPotions(alice.addr);
        _mintAcheron(alice.addr);

        uint8[] memory flags = new uint8[](5);   // Minting(0), Rebasing(1), ClaimingRebase(2), Compounding(3), Burning(4).
        flags[0] = 0;
        flags[1] = 1;
        flags[2] = 2;
        flags[3] = 3;
        flags[4] = 4;

        uint256 initialId = 777;

        for(uint256 i; i< 10_000; i++){
            uint160 salt1 = uint160(uint256(bytes32(keccak256(abi.encodePacked(i + 82349823)))));
            uint256 r = uint256(salt1) % 5;

            if(r == flags[0]){
                _mintPotions(alice.addr);
            } else if(r == flags[1]){
                uint256 amount = uint256(salt1) % 1e20;
                amount = amount + 1;
                _mintSkirk(amount, bob.addr);
                vm.startPrank(bob.addr);
                xSKIRK.approve(address(potionBlue), 2**256-1);
                potionBlue.rebase{value:0}(amount - 1, 1);
                vm.stopPrank();
            } else if(r == flags[2]){
                uint256 bal = potionBlue.balanceOf(alice.addr);
                for(uint256 a; a < bal; a++){
                    uint256 id = initialId + a;
                    if(potionBlue.ownerOf(id) == alice.addr){
                        vm.startPrank(alice.addr);
                        potionBlue.claimReward(id);
                        vm.stopPrank();
                    }
                }
            } else if(r == flags[3]){
                uint256 usdcAmount = uint256(salt1) % 1e8;
                uint256 daiAmount = uint256(salt1) % 1e20;
                uint256 sum = daiAmount + (usdcAmount * 1e12);
                uint256 diff;
                if(sum < 50e18){
                    diff = 50e18 - sum;
                    _provideRewards(0, diff);
                }
                _provideRewards(usdcAmount, daiAmount);
                vm.startPrank(alice.addr);
                potionBlue.compound{value: 0}();
                vm.stopPrank();
            } else if(r == flags[4]){
                _mintPotions(alice.addr);
                uint256 id2Burn = initialId;
                initialId = initialId + 1;
                vm.startPrank(alice.addr);
                potionBlue.burnPotion{value: 0}(0, id2Burn);
                vm.stopPrank();
            }
        }

    }

    /*
    Compounding should work in all different prices.
    */
    function testCompoundingInAllPossibleTicks() public {
        _mintPotions(alice.addr);
        _mintPotions(alice.addr);
        _mintPotions(alice.addr);
        _mintPotions(alice.addr);
        _mintPotions(alice.addr);

        int24 t1 = -276322;
        int24 t3 = -276323;
        int24 t5 = -276324;
        int24 t2 = -276325;
        int24 t4 = -276326;

        _mintAcheron(alice.addr);
        uint256 aliceBefore = xSKIRK.balanceOf(alice.addr);

        _arbitragePool(pool_dai_usdc, _tickToQ96(t1));
        _provideRewards(100e6, 100e18);
        vm.startPrank(alice.addr);
        potionBlue.compound{value: 0}();
        vm.stopPrank();

        uint256 aliceAfter = xSKIRK.balanceOf(alice.addr);
        uint256 reward = aliceAfter - aliceBefore;
        console.log("C1:", reward);
        aliceBefore = aliceAfter;

        _arbitragePool(pool_dai_usdc, _tickToQ96(t2));
        _provideRewards(100e6, 100e18);
        vm.startPrank(alice.addr);
        potionBlue.compound{value: 0}();
        vm.stopPrank();

        aliceAfter = xSKIRK.balanceOf(alice.addr);
        reward = aliceAfter - aliceBefore;
        console.log("C2:", reward);
        aliceBefore = aliceAfter;

        _arbitragePool(pool_dai_usdc, _tickToQ96(t3));
        _provideRewards(100e6, 100e18);
        vm.startPrank(alice.addr);
        potionBlue.compound{value: 0}();
        vm.stopPrank();

        aliceAfter = xSKIRK.balanceOf(alice.addr);
        reward = aliceAfter - aliceBefore;
        console.log("C3:", reward);
        aliceBefore = aliceAfter;

        _arbitragePool(pool_dai_usdc, _tickToQ96(t4));
        _provideRewards(100e6, 100e18);
        vm.startPrank(alice.addr);
        potionBlue.compound{value: 0}();
        vm.stopPrank();

        aliceAfter = xSKIRK.balanceOf(alice.addr);
        reward = aliceAfter - aliceBefore;
        console.log("C4:", reward);
        aliceBefore = aliceAfter;

        _arbitragePool(pool_dai_usdc, _tickToQ96(t5));
        _provideRewards(100e6, 100e18);
        vm.startPrank(alice.addr);
        potionBlue.compound{value: 0}();
        vm.stopPrank();

        aliceAfter = xSKIRK.balanceOf(alice.addr);
        reward = aliceAfter - aliceBefore;
        console.log("C5:", reward);
        aliceBefore = aliceAfter;
    }

    /*
    * Fuzz testing compunds in potion.
    */
    function testFuzzingRewardAmounts() public {
        _mintPotions(alice.addr);
        _mintPotions(alice.addr);
        _mintPotions(alice.addr);
        _mintPotions(alice.addr);
        _mintPotions(alice.addr);

        int24 t1 = -276322;
        int24 t3 = -276323;
        int24 t5 = -276324;
        int24 t2 = -276325;
        int24 t4 = -276326;

        int24[] memory arr = new int24[](5);
        arr[0] = t1;
        arr[1] = t2;
        arr[2] = t3;
        arr[3] = t4;
        arr[4] = t5;

        _mintAcheron(alice.addr);
        
        for(uint256 i; i<5; i++){
            _arbitragePool(pool_dai_usdc, _tickToQ96(arr[i]));
            for(uint256 a1; a1 < 100_000; a1++){
                uint160 salt1 = uint160(uint256(bytes32(keccak256(abi.encodePacked(a1 +2)))));
                uint256 rand1 = uint256(salt1) % 1e20;
                uint160 salt2 = uint160(uint256(bytes32(keccak256(abi.encodePacked(a1 + 37)))));
                uint256 rand2 = uint256(salt2) % 1e8;

                // Ensuring enough is sent! Since amount2Deposit must be at least 10e18.
                uint256 sum = rand1 + (rand2 * 1e12);
                uint256 diff;
                if(sum < 50e18){
                    diff = 50e18 - sum;
                    _provideRewards(0, diff);
                }
    
                _provideRewards(rand2, rand1);
                vm.startPrank(alice.addr);
                potionBlue.compound{value: 0}();
                vm.stopPrank();
            }
        }
    }

    /*
    * Since potion uses balanceOf after _claim, rewards can be directly transfered.
    */
    function _provideRewards(uint256 amountUsdc, uint256 amountDai) internal {
        usdc.mint(amountUsdc);
        dai.mint(amountDai);
        usdc.transfer(address(potionBlue), amountUsdc);
        dai.transfer(address(potionBlue), amountDai);
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