// SPDX-License-Identifier: Built by Mango
pragma solidity ^0.8.20;

import "../Methods.sol";
// import {TickMath} from "MangoHat/mangoUtils/Uni-Foundry/libraries/TickMath.sol";

contract AcheronBasicTests is Methods {

    using SafeCast for uint256;

    function testingLoopSorter() public {
        uint256 wbtcPrice = 64_000e18;
        (uint256 wbtcAmount, uint256 dai,) = acheron.wrapper(
            399e18,
            2004331587000383584631039759405285376,
            wbtcPrice
        );
        uint256 wbtcDollarValue = acheron.priceWrapper(wbtcPrice, wbtcAmount);
        uint256 rawSum = dai + wbtcDollarValue;
        console.log("BTC raw amount:",      wbtcAmount);
        console.log("DAI AMOUNT",           dai);
        console.log("WBTC dollar amount:",  wbtcDollarValue);
        console.log("Raw sum",              rawSum);
    }

    /*
    * Testing sorter on a tick thats very close to lower limit.
    */
    function testLoopSorterCloseToBottom() public {
        uint256 wbtcPrice = 20_000e18;
        (uint256 wbtcAmount, uint256 dai,) = acheron.wrapperHeavy(
            200e18,
            1120455419495722764266096695099523072,
            wbtcPrice
        );
        uint256 wbtcDollarValue = acheron.priceWrapper(wbtcPrice, wbtcAmount);
        uint256 rawSum = dai + wbtcDollarValue;
        console.log("raw wbtc amount:",     wbtcAmount);
        console.log("DAI AMOUNT",           dai);
        console.log("WBTC dollar amount:",  wbtcDollarValue);
        console.log("Raw sum",              rawSum);
    }

    /*
    Fishing for limiting ticks for above functions.
    Debunked: anything bellow this sqrtP: 1553369483656550509189727096885406792 will fail.
    or 39k. BTC bellow 39k, will require to use the other iterative method.
    */
    function testCheckingLimitsBeforeOF() public {
        for(uint256 i = 1; i < 56; i++){
            uint256 tickOffset = 340941 - 339242;
            uint256 _wbtcPrice = 64e21;
            uint256 wbtcPrice = _wbtcPrice - (i * (10 ** 21));
            uint160 sqrtPrice = TickMath.getSqrtRatioAtTick(int24(uint24(340941 - (i * tickOffset))));
            (uint256 wbtcAmount, uint256 dai,) = acheron.wrapper(
                200e18,
                sqrtPrice,
                wbtcPrice
            );
            console.log("Success at:", sqrtPrice);
            require(wbtcAmount > 0 && dai > 0);
        }
    }

    /*
    Stress test for above function, using the correct function wrapper for lower tick spot prices.
    */
    function testFuzzingForLowSort() public {
        for(uint256 i = 1; i < 56; i++){
            uint256 tickOffset = 340941 - 339242;
            uint256 _wbtcPrice = 64e21;
            uint256 wbtcPrice = _wbtcPrice - (i * (10 ** 21));
            uint160 sqrtPrice = TickMath.getSqrtRatioAtTick(int24(uint24(340941 - (i * tickOffset))));
            (uint256 wbtcAmount, uint256 dai,) = acheron.wrapperHeavy(
                200e18,
                sqrtPrice,
                wbtcPrice
            );
            uint256 wbtcDollarValue = acheron.priceWrapper(wbtcPrice, wbtcAmount);
            uint256 rawSum = dai + wbtcDollarValue;
            bool success = rawSum < 200e18 && rawSum > 194e18;
            console.log(success);
            if(!success){
                console.log("Error at:");
                console.log("sqrtPrice", sqrtPrice);
                console.log("wbtcPrice", wbtcPrice);
                break;
            }
        }
    }

    /*
    Debugging lower range sorter
    */
    function testDBugLowerSorter() public {
        uint160 sqrtPrice = 1823969275989850893799504371639123968;
        uint256 wbtcPrice = 53000000000000000000000;
        (uint256 wbtcAmount, uint256 dai,) = acheron.wrapperHeavy(
            200e18,
            sqrtPrice,
            wbtcPrice
        );
        require(wbtcAmount > 0 && dai > 0);
        uint256 amountBtc = acheron.priceAmountWrapper(wbtcPrice, 200e18);
        uint256 valueBtc = acheron.priceWrapper(wbtcPrice, 177157);
        require(amountBtc > 0);
        console.log(valueBtc);
    }
    

    /*
    Success ratio test for above range function
    */
    function testAboveRangeSorter() public {
        for(uint256 i = 1; i < 130; i++){
            uint256 tickOffset = 340941 - 339242;
            uint256 _wbtcPrice = 64e21;
            uint256 wbtcPrice = _wbtcPrice + (i * (10 ** 21));
            uint160 sqrtPrice = TickMath.getSqrtRatioAtTick(int24(uint24(340941 + (i * tickOffset))));
            (uint256 wbtcAmount, uint256 dai,) = acheron.wrapper(
                200e18,
                sqrtPrice,
                wbtcPrice
            );
            uint256 wbtcDollarValue = acheron.priceWrapper(wbtcPrice, wbtcAmount);
            uint256 rawSum = dai + wbtcDollarValue;
            bool success = rawSum < 200e18 && rawSum > 194e18;
            console.log(success);
            if(!success){
                console.log("Error at:", wbtcPrice);
            }
        }
    }


    /*
    Fuzztesting lower range for sorter.
    */
    function testLowerRangeSorterFzz() public {
        uint128 startingAmount = 64000;
        // uint128 _amount = startingAmount * 1e10;
        for(uint256 i = 1; i < 170; i++){
            uint128 _amount = (startingAmount + (i.toUint128() * 1e3));
            uint256 wbtcPrice = uint256(_amount);
            uint160 sqrtPrice = _q96(_amount);
            (uint256 wbtcAmount, uint256 dai,) = acheron.wrapperHeavy(
                200e18,
                sqrtPrice,
                wbtcPrice
            );
            uint256 wbtcDollarValue = acheron.priceWrapper(wbtcPrice, wbtcAmount);
            uint256 rawSum = dai + wbtcDollarValue;
            bool success = rawSum < 200e18 && rawSum > 194e18;
            console.log(success, wbtcPrice);
            if(!success){
                console.log("Error at:", wbtcPrice);
            } 
        }
    }

    /*
    * DEFINITIVE test for lower THRESHOLD: 59k -
    */
    function testLowerRangeSorterTestFuzz() public {
        uint128 startingAmount = 64000;
        // uint128 _amount = startingAmount * 1e10;
        for(uint256 i = 1; i < 1700; i++){
            uint128 _amount = (startingAmount - (i.toUint128() * 1e2));
            uint256 wbtcPrice = uint256(_amount) *  10 ** 18;
            uint160 sqrtPrice = _q96(_amount);
            uint256 amountIn = 700e18;
            (uint256 wbtcAmount, uint256 dai,) = acheron.wrapperHeavy(
                amountIn,
                sqrtPrice,
                wbtcPrice
            );
            uint256 wbtcDollarValue = acheron.priceWrapper(wbtcPrice, wbtcAmount);
            uint256 rawSum = dai + wbtcDollarValue;
            bool success = rawSum < amountIn && rawSum > amountIn - ((amountIn * 3)/100);
            console.log(wbtcPrice, rawSum, wbtcAmount, dai);
            console.log(sqrtPrice);
            if(!success){
                console.log("Error at:", wbtcPrice);
            }
            if(wbtcPrice < 10_200  * 10 ** 18){
                break;
            }
        }
        /*
        
        
        */
    }


    /*
    * Attempting a more granular fuzz test for price ranges for the above tick range
    */
    function testGranuarlAboveRangeSorter() public {
        uint128 startingAmount = 64000;
        // uint128 _amount = startingAmount * 1e10;
        for(uint256 i = 1; i < 1700; i++){
            uint128 _amount = (startingAmount + (i.toUint128() * 1e2));
            uint256 wbtcPrice = uint256(_amount);
            uint160 sqrtPrice = _q96(_amount);

            uint256 amountIn = 700e18;
            (uint256 wbtcAmount, uint256 dai,) = acheron.wrapper(
                amountIn,
                sqrtPrice,
                wbtcPrice
            );
            uint256 wbtcDollarValue = acheron.priceWrapper(wbtcPrice, wbtcAmount);
            uint256 rawSum = dai + wbtcDollarValue;
            bool success = rawSum < amountIn && rawSum > amountIn - ((amountIn * 3) / 100);
            console.log(success, wbtcPrice, rawSum);
            if(!success){
                console.log("Error at:", wbtcPrice);
                break;
            } 
            if(wbtcPrice > 180_000){
                break;
            }
        }
    }

    function testPriceOut() public view {
        console.log(acheron.wrapperGetPrice(1823969275989850893799504371639123968));
    }

    /* 
    * Testing swap method
    */
    function testSwapMethodWBTC_In() public {
        uint256 balancePrior = dai.balanceOf(alice.addr);
        _swapSpecificTokenIn(
            pool_wbtc_dai,
            address(wbtc),
            70000,               // 40 DAI
            alice.addr          
        );
        uint256 balanceAfter = dai.balanceOf(alice.addr);
        console.log("Delta DAI:", balanceAfter - balancePrior);   // 44663381772824666130 dogeDance
    }

    function testSwapMethodDAI_In() public {
        uint256 balancePrior = wbtc.balanceOf(alice.addr);
        uint256 x = _swapSpecificTokenIn(
            pool_wbtc_dai,
            address(dai),
            80e18,               
            alice.addr          
        );
        uint256 balanceAfter = wbtc.balanceOf(alice.addr);
        console.log("Delta WBTC:", balanceAfter - balancePrior);   // 124613 dogeDance

        console.log("Amount Out:", x);
        console.log("DAI:", dai.balanceOf(alice.addr));
        console.log("WBTC:", wbtc.balanceOf(alice.addr));
    }

    /*
    * Testing explicit amountOut swap method
    */
    function testSwapExactAmountOutDAI() public {
        uint256 balancePrior = dai.balanceOf(alice.addr);
        _swapForSpecificTokenOut(
            pool_wbtc_dai,
            address(dai),
            33e18,
            alice.addr
        );
        uint256 balanceAfter = dai.balanceOf(alice.addr);
        console.log("Delta DAI:", balanceAfter - balancePrior);
    }

    function testMockTestSwapAmountOut() public {
        uint256 x = _swapForSpecificTokenOut(
            pool_wbtc_dai,
            address(dai),
            777e18,
            alice.addr
        );
        console.log("Amount Spent:", x);
        console.log("DAI:", dai.balanceOf(alice.addr));
        console.log("WBTC:", wbtc.balanceOf(alice.addr));
    }
    
    function testQuickFoo() public {
        // console.log(_invertSqrtP(
        //     1823969275989850893799504371639123968,
        //     8,
        //     18
        // ));     
        
        uint256 result = _swapForSpecificTokenOut(pool_wbtc_dai, address(wbtc), 1e8, alice.addr);
        console.log("Amount Spent:", result);
        console.log("DAI:", dai.balanceOf(alice.addr));
        console.log("WBTC:", wbtc.balanceOf(alice.addr));
    }   

    function testPool() public {
        IUniswapV3Pool(pool_wbtc_dai).swap(
            alice.addr,
            false,                      // False(UP) == MaxSqrtP : True(DOWN) MinSqrtP
            1e18,
            TickMath.MAX_SQRT_RATIO -1,
            ""
        );
    }

    function testCheckPricesToArbitrageTo() public  {

        // Checking prices of both pools first:
        (uint160 sqrtP,,,,,,) = IUniswapV3Pool(pool_wbtc_dai).slot0();
        console.log("(WBTC/DAI)", _getPrice(sqrtP, 8, 18));

        (sqrtP,,,,,,) = IUniswapV3Pool(pool_wbtc_xSkirk).slot0();
        console.log("(WBTC/xSKIRK)", _getPrice(sqrtP, 8, 18));

        _balanceSkirkWbtcPool();

        (uint248 a, uint8 b) = __getAmountsToArb();
        if(b == 3){
            console.log("Balanced");
        } else {
            console.log(uint256(a));        // Works so far.
        }
    }

    function testCheckingSqrtPrice() public view{
        // console.log(_getSqrP(64000, 8, 18));
        // 2004331564709774864860083028813152256 solc  good enough :)
        // 2004331587000383584631039759405285376 py

        console.log(_getSqrP(3100, 18, 18));
        console.log(_getPrice(4357548938284538567644917268480, 18, 18) / (10 ** 18));
        console.log(_invertSqrtP(4357548938284538567644917268480, 18, 18));
        // 4411237397794263893240602165248
        // 4357548938284538567644917268480

        // 1440512045713896981481390080 solc
        // 1419961110997888109715662319

        // TBD: Make the function inverse even 1/priced versions back to price/1. @Mango
    }

    function testSanityCheckForAddresses() public {
        IUniswapV3Pool(pool_wbtc_xSkirk).swap(
            alice.addr,
            false,                      // False(UP) == MaxSqrtP : True(DOWN) MinSqrtP
            1e18,
            TickMath.MAX_SQRT_RATIO -1,
            ""
        );

        (uint160 sqrtP,,,,,,) = IUniswapV3Pool(pool_wbtc_xSkirk).slot0();
        console.log(sqrtP);
        console.log(_getPrice(sqrtP, 8, 18));
    }
}

/*

85671824990869404473

0.0 1000000


TBD: 
    wbtc/DAI pool needs to be the price oracle for arbitrage fixes. Meaning that if the price of wbtc/dai is 64k
    then we arb the wbtc/xSkirk pool to 64k - (64k * 0.1) = 57600

    Therefore, pricemoevements on wbtc/dai, must be instantly corrected in xskirk/wbtc.

    Now having a price discrepancy between wbtc/dai & skrik/wbtc, attempt the looped lp deposit on different main prices.

    This must work, for the contract to be done.

    Scortched          : 153051342134366542703
    xSkirk used in Mint: 47840451776993869625
    Dai used in Swap   : 149135188019358776181

*/