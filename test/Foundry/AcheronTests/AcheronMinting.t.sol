// SPDX-License-Identifier: Built by Mango
pragma solidity ^0.8.20;

import "../Methods.sol";

contract AcheronMinting is Methods {

    using FullMath for uint256;

    /*
    * Minting in all possible price ranges. From 700 - 25k. (DONE).
    * Since minting on mainnet, is expected to happen with a 1.1 price correction with current WETH/USDC exchange rates, 
    the toleranz of the contract must be tested if the 1.1 differs due to a lack of arbitrage.
    * Compounding a lot + having xSkirk rebased, therefore the contract "holds" xSkirk which is meant to be retrieved only by users.
    * Minting, Rebasing skirk, claiming some, minting more, compounding, minting more, burning. Checking if all claims are satisfied and no
    xSkirk from users gets used during mints or compound re-aggregations.
    */

    /*
    * Mints Acherons starting from price 800 to 7000.
    * Acherons price oracle reads the weth price from the DAI/WETH(3000) pool.
    */
    function testMintAcheronAtAllPricesOne() public {
        // Minting some acheron, such that the pool has some xSkirk and weth to arbitrage:
        _mintAcheron(alice.addr);
        _mintAcheron(alice.addr);
        _mintAcheron(alice.addr);

        uint256 startingPrice = 800e18;
        for(uint256 i; i <6997; i++){
            uint256 indexPrice = startingPrice + (i * 1e18);
            console.log("At Price:", indexPrice/1e18);
            _arbPools(indexPrice);
            _mintAcheron(alice.addr);
        }
    }

    /*
    * Minting Acherons from prices 7000, 14000.
    */
    function testMintAcheronAtAllPricesTwo() public {
        _mintAcheron(alice.addr);
        _mintAcheron(alice.addr);
        _mintAcheron(alice.addr);

        uint256 startingPrice = 7000e18;
        for(uint256 i; i <6997; i++){
            uint256 indexPrice = startingPrice + (i * 1e18);
            console.log("At Price:", indexPrice/1e18);
            _arbPools(indexPrice);
            _mintAcheron(alice.addr);
        }
    }

    /*
    * Minting Acherons from prices 14000, 21000.
    */
    function testMintAcheronAtAllPricesThree() public {
        _mintAcheron(alice.addr);
        _mintAcheron(alice.addr);
        _mintAcheron(alice.addr);

        uint256 startingPrice = 14_000e18;
        for(uint256 i; i <6997; i++){
            uint256 indexPrice = startingPrice + (i * 1e18);
            console.log("At Price:", indexPrice/1e18);
            _arbPools(indexPrice);
            _mintAcheron(alice.addr);
        }
    }

    /*
    * Minting Acherons from prices 14000, 21000.
    */
    function testMintAcheronAtAllPricesFour() public {
        _mintAcheron(alice.addr);
        _mintAcheron(alice.addr);
        _mintAcheron(alice.addr);

        uint256 startingPrice = 20_000e18;
        for(uint256 i; i <6997; i++){
            uint256 indexPrice = startingPrice + (i * 1e18);
            console.log("At Price:", indexPrice/1e18);
            _arbPools(indexPrice);
            _mintAcheron(alice.addr);
        }
    } 

    /*
    * Testing ranges of toleranz, in scenarios where a lack of arbitrage might occur.
    * Ranges 800 - 7796
    */
    function testToleranzResistanceOne() public {
        uint256 startingPrice = 800e18;
        uint256 wethAmount;
        uint256 skirkAmount;
        uint256 pastSum;
        for(uint256 i; i <6997; i++){
            uint256 indexPrice = startingPrice + (i * 1e18);
            _arbPoolsWETH(indexPrice);
            _mintAcheron(alice.addr);
            wethAmount = weth.balanceOf(pool_weth_xSkirk);
            skirkAmount = xSKIRK.balanceOf(pool_weth_xSkirk);
            uint256 sum = _wethToDai(indexPrice, wethAmount) + skirkAmount;
            if(sum - pastSum < 320e18){
                console.log("Low deposit range:", indexPrice);
                console.log("SUM              :", sum);
                break;
            }
            pastSum = sum;
        }
    }

    /*
    * Testing ranges of toleranz, in scenarios where a lack of arbitrage might occur.
    * Ranges 7790 - 14780
    */
    function testToleranzResistanceTwo() public {
        uint256 startingPrice = 7790e18;
        uint256 wethAmount;
        uint256 skirkAmount;
        uint256 pastSum;
        for(uint256 i; i <6997; i++){
            uint256 indexPrice = startingPrice + (i * 1e18);
            _arbPoolsWETH(indexPrice);
            _mintAcheron(alice.addr);
            wethAmount = weth.balanceOf(pool_weth_xSkirk);
            skirkAmount = xSKIRK.balanceOf(pool_weth_xSkirk);
            uint256 sum = _wethToDai(indexPrice, wethAmount) + skirkAmount;
            if(sum - pastSum < 320e18){
                console.log("Low deposit range:", indexPrice);
                console.log("SUM              :", sum);
                break;
            }
            pastSum = sum;
        }
    }

    /*
    * Testing ranges of toleranz, in scenarios where a lack of arbitrage might occur.
    * Ranges 14780 - 21700
    */
    function testToleranzResistanceThree() public {
        uint256 startingPrice = 14780e18;
        uint256 wethAmount;
        uint256 skirkAmount;
        uint256 pastSum;
        for(uint256 i; i <6997; i++){
            uint256 indexPrice = startingPrice + (i * 1e18);
            _arbPoolsWETH(indexPrice);
            _mintAcheron(alice.addr);
            wethAmount = weth.balanceOf(pool_weth_xSkirk);
            skirkAmount = xSKIRK.balanceOf(pool_weth_xSkirk);
            uint256 sum = _wethToDai(indexPrice, wethAmount) + skirkAmount;
            if(sum - pastSum < 320e18){
                console.log("Low deposit range:", indexPrice);
                console.log("SUM              :", sum);
                break;
            }
            pastSum = sum;
        }
    }

    /*
    * Testing ranges of toleranz, in scenarios where a lack of arbitrage might occur.
    * Ranges 21700 - 21700
    */
    function testToleranzResistanceFour() public {
        uint256 startingPrice = 21700e18;
        uint256 wethAmount;
        uint256 skirkAmount;
        uint256 pastSum;
        for(uint256 i; i <6997; i++){
            uint256 indexPrice = startingPrice + (i * 1e18);
            _arbPoolsWETH(indexPrice);
            _mintAcheron(alice.addr);
            wethAmount = weth.balanceOf(pool_weth_xSkirk);
            skirkAmount = xSKIRK.balanceOf(pool_weth_xSkirk);
            uint256 sum = _wethToDai(indexPrice, wethAmount) + skirkAmount;
            if(sum - pastSum < 320e18){
                console.log("Low deposit range:", indexPrice);
                console.log("SUM              :", sum);
                break;
            }
            pastSum = sum;
        }
        /*
        152172966309347526372

        ensureOut(12731109182690602(325))
        152.172966309347526372  ??
        */  
    }

    /*
    * Unlimited minting of nfts needs to be unlocked for this test to pass.
    Otherwise A:MM will be the revert message, due to the 7000th nft having been minted.
    * Attempts all possible price manipulations possible from 100 to 100k! Goes heavy on GPU.
    * Meaning it will perform a 800 - 30k weth price sweep on all possible prices of acheron from 100 to 100k.
    VERY HEAVY test.
    */
    function testToleranzAllRangeHeavyGPU() public {
        uint256 acheronPrice = 5300e18;
        for(uint256 a; a < 3; a++){
            uint256 acheronIndex = acheronPrice + (a * 100e18);
            _arbitragePool(pool_weth_xSkirk, _getQ96(acheronIndex, 18, 18));
            uint256 poolPrice = 800e18;
            uint256 wethAmount;
            uint256 skirkAmount;
            uint256 pastSum;
            for(uint256 i; i < 29_200; i++){
                uint256 indexPrice = poolPrice + (i * 1e18);
                _arbPoolsWETH(indexPrice);
                _mintAcheron(alice.addr);
                wethAmount = weth.balanceOf(pool_weth_xSkirk);
                skirkAmount = xSKIRK.balanceOf(pool_weth_xSkirk);
                uint256 sum = _wethToDai(indexPrice, wethAmount) + skirkAmount;
                if(sum - pastSum < 320e18){
                    console.log("Low deposit range:", indexPrice);
                    console.log("SUM              :", sum);
                    break;
                }
                pastSum = sum;
            }
        }
    }
    /*
    Initial Amounts:    78690902094214396, 197680141991545660208    (0.07, 197.6)   62 + 197 = 259
    Price:          800
    WethInDai:      62.9
    wethAmount:     0.078690902094214397
    daiUsed:        62.9
    */

    /*
    * Debugging above findings.
    */
    function testDebuggingAboveFindings() public {
        uint256 acheronPrice = 3000e18;
            uint256 acheronIndex = acheronPrice + (2 * 100e18);
            _arbitragePool(pool_weth_xSkirk, _getQ96(acheronIndex, 18, 18));
            uint256 poolPrice = 800e18;
            uint256 wethAmount;
            uint256 skirkAmount;
            uint256 pastSum;
            for(uint256 i; i < 29_200; i++){
                uint256 indexPrice = poolPrice + (i * 1e18);
                _arbPoolsWETH(indexPrice);
                _mintAcheron(alice.addr);
                wethAmount = weth.balanceOf(pool_weth_xSkirk);
                skirkAmount = xSKIRK.balanceOf(pool_weth_xSkirk);
                uint256 sum = _wethToDai(indexPrice, wethAmount) + skirkAmount;
                if(sum - pastSum < 320e18){
                    console.log("Low deposit range:", indexPrice);
                    console.log("SUM              :", sum);
                    break;
                }
                pastSum = sum;
        }
    }

    /*
    * Sanity
    */
    function testAcheronMintingBasicMethods() public {
        (uint160 sqrtP_n,,,,,,) = IUniswapV3Pool(pool_dai_usdc).slot0();
        console.log(_getErInBase18(sqrtP_n, 18, 6));
        int24 tick = -276427;
        (uint256 amountUsed,) = _arbitragePool(pool_dai_usdc, _tickToQ96(tick));
        (sqrtP_n,,,,,,) = IUniswapV3Pool(pool_dai_usdc).slot0();
        console.log(_getErInBase18(sqrtP_n, 18, 6));
        console.log("amount swapped:", amountUsed);

        _mintAcheron(alice.addr);
        _arbPools(3080e18);
        (uint160 sqrtP_N,,,,,,) = IUniswapV3Pool(pool_dai_weth).slot0();
        uint256 pr = 1e36 / _getErInBase18(sqrtP_N, 18, 18);
        console.log("500 :", pr);
        ( sqrtP_N,,,,,,) = IUniswapV3Pool(pool_dai_weth_3000).slot0();
         pr = 1e36 / _getErInBase18(sqrtP_N, 18, 18);
         console.log("3000:", pr);
    }

    /*
    * Locally calculate liquidity
    */
    function testLiquidityCalculationForLowValues() public view {
        uint256 amount2SpendInDai = 350e18;     // Target for lp deposit 345-346
        uint160 LG = 2382120897181660527828393787392;
        uint160 tl_SqrtP = 2373597069249974917302093533021;
        uint160 tu_SqrtP = 11182265215894369642182094599515;
        uint256 startPrice = 900e18;
        for(uint256 i; i < 200; i++){
            uint256 wethPrice = startPrice + (i * 1e18);
            uint256 skirkSpot = wethPrice - wethPrice.mulDiv(10, 100);
            uint160 sqrtPrice = _getQ96(skirkSpot, 18, 18);
            if(sqrtPrice < LG){
                uint256 wethAmount = _daiToWeth(wethPrice, (amount2SpendInDai - amount2SpendInDai.mulDiv(22, 1000)));
                uint128 liquidity = LiquidityMath.getLiquidityForAmounts(sqrtPrice, tl_SqrtP, tu_SqrtP, wethAmount, 1e18);
                (uint256 a0, uint256 a1) = LiquidityMath.getAmountsForLiquidity(sqrtPrice, tl_SqrtP, tu_SqrtP, liquidity);
                console.log(sqrtPrice, wethAmount, 1e18);
                console.log("Sum    :", (_wethToDai(wethPrice, a0) + a1) / 1e18);
                console.log("Amounts:", a0, a1);
                console.log("Price  :", wethPrice);
                console.log("in DAI :", _wethToDai(wethPrice, a0));
            } else {
                break;
                /*
                2375656155726150409222620699848
                2381593820917186471399131708094 // Contr
                341982068356358296              // Contr
                */
            }
        }
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

/*
                (uint160 sqrtP_n,,,,,,) = IUniswapV3Pool(pool_dai_weth).slot0();
            uint256 pr = 1e36 / _getErInBase18(sqrtP_n, 18, 18);
            console.log("500 :", pr);

            ( sqrtP_n,,,,,,) = IUniswapV3Pool(pool_dai_weth_3000).slot0();
             pr = 1e36 / _getErInBase18(sqrtP_n, 18, 18);
            console.log("3000:", pr);
*/