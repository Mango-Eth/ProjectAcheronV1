// SPDX-License-Identifier: Built by Mango
pragma solidity ^0.8.20;

import "../Methods.sol";

contract TestingDeployment is Methods {

    /*
    * Arbitrag WETH/SKIRK pool.
    * Mint.
    */
    function testCheckingPools() public {
        (uint160 sqrtP,,,,,,) = IUniswapV3Pool(pool_weth_xSkirk).slot0();
        console.log("WETH/SKIRK price      :", _getPrice(sqrtP, 18,18));

        // Balancing WETH/SKIRK:
        _balanceWeth_xSkirk_Pool();

        (sqrtP,,,,,,) = IUniswapV3Pool(pool_weth_xSkirk).slot0();
        console.log("WETH/SKIRK price after:", _getPrice(sqrtP, 18,18));
    }

    /*
    * Finally testing minting:
    */
    function testMintingAcheron() public {
        // Balancing WETH/SKIRK:
        _balanceWeth_xSkirk_Pool();
        _mintAcheron(alice.addr);
    }

    /*54703065641146214202922469896
    *  Looping from 2700 to 1000 on WETH/SKIRK price & minting.
    */
    function testMintingFuzzInBearMarket() public {
        uint256 startingPrice = 3000e18;
        for(uint256 i; i < 20; i++){
            uint256 spotPrice = startingPrice - (i * 100e18);
            uint256 inverse = 1e36/spotPrice;
            uint160 inverseQ96 = _getQ96(inverse, 18, 18);
            _shiftDAI_WETH_POOL(inverseQ96);
            _balanceWeth_xSkirk_Pool();

            console.log("POOL STATES:");
            // DAI/WETH
            (uint160 sqrtP,,,,,,) = IUniswapV3Pool(pool_dai_weth).slot0();
            sqrtP = _getInverseQ96(sqrtP, 18, 18);
            uint256 DAI_WETH_POOL_PRICE = _getErInBase18(sqrtP, 18, 18);
            console.log("DAI/WETH", DAI_WETH_POOL_PRICE);
            // WETH/SKIRK
            (sqrtP,,,,,,) = IUniswapV3Pool(pool_weth_xSkirk).slot0();
            uint256 WETH_SKIRK_POOL_PRICE = _getErInBase18(sqrtP, 18, 18);
            console.log("WETH/SKIRK", WETH_SKIRK_POOL_PRICE);
            uint256 id = _mintAcheron(alice.addr);
            console.log("ID of acheron:", id);
            uint256 liquidity = IUniswapV3Pool(pool_weth_xSkirk).liquidity();
            console.log("New L WETH/SKRIK:", liquidity);
            // (uint160 sqrtPrice,,,,,,) = IUniswapV3Pool(pool_dai_weth).slot0();
            // uint256 val = _getPrice(_inverse(sqrtPrice, 18, 18), 18, 18);
            // console.log("Mint successful at:", val);
        }
    }

    function testAllPriceRangesMints() public { // 1766477719156414916
        uint256 startingPrice = 900e18;         // 1766529658831091868
        for(uint256 i; i < 1910; i++){
            uint256 spotPrice = startingPrice + (i * 10e18);
            uint256 inverse = 1e36/spotPrice;
            uint160 inverseQ96 = _getQ96(inverse, 18, 18);
            _shiftDAI_WETH_POOL(inverseQ96);
            _balanceWeth_xSkirk_Pool();

            console.log("POOL STATES:");
            // DAI/WETH
            (uint160 sqrtP,,,,,,) = IUniswapV3Pool(pool_dai_weth).slot0();
            sqrtP = _getInverseQ96(sqrtP, 18, 18);
            uint256 DAI_WETH_POOL_PRICE = _getErInBase18(sqrtP, 18, 18);
            console.log("DAI/WETH", DAI_WETH_POOL_PRICE);
            // WETH/SKIRK
            (sqrtP,,,,,,) = IUniswapV3Pool(pool_weth_xSkirk).slot0();
            uint256 WETH_SKIRK_POOL_PRICE = _getErInBase18(sqrtP, 18, 18);
            console.log("WETH/SKIRK", WETH_SKIRK_POOL_PRICE);
            uint256 id = _mintAcheron(alice.addr);
            console.log("ID of acheron:", id);
            uint256 liquidity = IUniswapV3Pool(pool_weth_xSkirk).liquidity();
            console.log("New L WETH/SKRIK:", liquidity);
    }
    }

    function testGrabbingAmounts() public {
        uint256 startingPrice = 9500e18;
        uint256 depositAmount = 200e18;
        for(uint i; i <106; i++){
            uint256 currentPrice = startingPrice + (i * 100e18);
            uint256 wethAmount;
            uint256 skirkAmount;
            (wethAmount, skirkAmount) = acheron.testUppSearch(
                _getQ96(currentPrice, 18, 18),
                currentPrice,
                depositAmount
            );
            uint256 lowestTarget = depositAmount - (depositAmount / 20);
            uint256 LpValue = _calculateValue(currentPrice, wethAmount) + skirkAmount;
            if(LpValue < lowestTarget){
                console.log("FAILED AT:", currentPrice);
                console.log("VALUES   :", wethAmount, skirkAmount);
                break;
            }
            console.log("Success at   :", currentPrice, wethAmount, skirkAmount);
        }
    }

    function testGrabbingLowerAmounts() public {
        uint256 startingPrice = 9500e18;
        uint256 depositAmount = 200e18;
        for(uint i; i <86; i++){
            uint256 currentPrice = startingPrice - (i * 100e18);
            uint256 wethAmount;
            uint256 skirkAmount;
            (wethAmount, skirkAmount) = acheron.testLowerSearch(
                _getQ96(currentPrice, 18, 18),
                currentPrice,
                depositAmount
            );
            uint256 lowestTarget = depositAmount - (depositAmount / 20);
            uint256 LpValue = _calculateValue(currentPrice, wethAmount) + skirkAmount;
            if(LpValue < lowestTarget){
                console.log("FAILED AT:", currentPrice);
                console.log("VALUES   :", wethAmount, skirkAmount);
                break;
            }
            console.log("Success at   :", currentPrice, wethAmount, skirkAmount);
        }
    }

    function _calculateValue(uint256 _wethPrice, uint256 _wethAmount) internal pure returns (uint256 daiER) {
        daiER = (_wethPrice * _wethAmount) / 1e18;
    }

    /*
    * Testing weth/xskirk ranges from 3000++
    * Also minting all possible ids
    */
    function testMintingFuzzInBullMarket() public {
        uint256 startingPrice = 3000e18;
        for(uint256 i; i < 170; i++){
            uint256 spotPrice = startingPrice + (i * 100e18);
            uint256 inverse = 1e36/spotPrice;
            uint160 inverseQ96 = _getQ96(inverse, 18, 18);
            _shiftDAI_WETH_POOL(inverseQ96);
            _balanceWeth_xSkirk_Pool();

            console.log("POOL STATES:");
            // DAI/WETH
            (uint160 sqrtP,,,,,,) = IUniswapV3Pool(pool_dai_weth).slot0();
            sqrtP = _getInverseQ96(sqrtP, 18, 18);
            uint256 DAI_WETH_POOL_PRICE = _getErInBase18(sqrtP, 18, 18);
            console.log("DAI/WETH", DAI_WETH_POOL_PRICE);
            // WETH/SKIRK
            (sqrtP,,,,,,) = IUniswapV3Pool(pool_weth_xSkirk).slot0();
            uint256 WETH_SKIRK_POOL_PRICE = _getErInBase18(sqrtP, 18, 18);
            console.log("WETH/SKIRK", WETH_SKIRK_POOL_PRICE);
            uint256 id = _mintAcheron(alice.addr);
            console.log("ID of acheron:", id);
            uint256 liquidity = IUniswapV3Pool(pool_weth_xSkirk).liquidity();
            console.log("New L WETH/SKRIK:", liquidity);
        }
    }

    // Checking arbitrage methods:
    function testCheckArbitrage() public {
        (uint160 sqrtP,,,,,,) = IUniswapV3Pool(pool_dai_weth).slot0();
        uint256 DAI_WETH_POOL_PRICE = _getErInBase18(sqrtP, 18, 18);
        console.log("Starting price     :", DAI_WETH_POOL_PRICE);
        console.log("Q96 startint price :", sqrtP);

        uint256 targetPrice = 3000e18;
        console.log("SHIFT TO           :", targetPrice);
        uint160 erOverOne = _getQ96(targetPrice, 18, 18);
        uint160 oneOverEr = _getInverseQ96(erOverOne, 18, 18);
        console.log("TARGET q96         :", oneOverEr);
        _shiftDAI_WETH_POOL(oneOverEr);         // Requires me to pass regular sqrtPrice.

        console.log("Shifting");

        // AFter:
        (sqrtP,,,,,,) = IUniswapV3Pool(pool_dai_weth).slot0();
        sqrtP = _getInverseQ96(sqrtP, 18, 18);
        DAI_WETH_POOL_PRICE = _getErInBase18(sqrtP, 18, 18);
        console.log("Price After        :", DAI_WETH_POOL_PRICE);
        console.log("Q96 startint after :", sqrtP);
        console.log("TWAP PRICE         :", acheron._getWethPrice());
    }

    function testCalculator() public view {
        // uint256 sqrtPrice = 4674461588341595918019093069824;
        // console.log(_getPrice(1446501726624926448360620032, 18, 18));
        // console.log(_getSqrtP_Decimal(333333333333333));
        // console.log(sqrtu(uint160(330578512396694 << 96)));
        // console.log(_getSqrtP_Decimal_TBD(330578512396694));
        // console.log(_floatToSqrtPrice(330578512396694, 18, 18));
        // // console.log(_floatToSqrtPrice(15, 6, 8));
        // console.log(_scaleDecimals(15, 6, 8));
        // // console.log(sqrtu(_scaleDecimals(15, 6, 8)) * (2**96));
        // console.log(sqrtu(1500000000000000000000));
        // console.log(38729833462 * (2**96));
        // console.log(3068493539677728994443703042890878943232 / sqrtu(1e18));
        // console.log(_floatToSqrtPrice(15, 6, 8));

        // console.log(_getPrice(2004331587000383570417679335424, 8, 6));
        // console.log(_getExchangeRate(2004331587000383570417679335424, 8, 6));

        // console.log(_inverseAgain(2004331587000383570417679335424, 8, 6));
        // console.log(_getSqrtPriceDecimal0(66711140760, 8));

        // console.log(_getQ96(1e18/64000, 6, 8));
        // console.log(_getErInBase18(3131768045100222440636274234,6,8));
        // console.log(_getQ96(640204865556978, 6, 8));

        // PERFECTO
        // console.log(_getQ96(64_000e18, 8, 6));                                // wbtc/usdc : 2004331586972888531368361892599
        // console.log(_getErInBase18(2004331586972888531368361892599, 8, 6));  // 6400e18     er in base 1e18

        // // 1e36 / 6400e18 = er
        // // _getQ96(er) / sqrtu(1e36)

        // console.log(_getInverseQ96(2004331586972888531368361892599, 8, 6)); // usdc/wbtc : 3131768045100222440636274234
        // console.log(_getErInBase18(3131768045100222440636274234, 6, 8));    // 15624999405408 1/er in  base 1e18

        // Also perfecto!                                            // WETH/DAI : 4339505179874779672736325173248 py()
        // console.log(_getQ96(3000e18, 18, 18));      // WETH/DAI : 4339505179833849321777928796668 solc
        // console.log(_getErInBase18(4339505179833849321777928796668, 18, 18));   // 2999.999999943408062499   perfect

        //                                                                         // DAI/WETH : 1446501726624926448360620032(py)
        // console.log(_getInverseQ96(4339505179833849321777928796668, 18, 18));   // DAI/WETH : 1446501680394854973938446002(solc)

        // console.log(_getInverseQ96(1446501680394854973938446002, 18, 18));
        
        uint248 val;
        uint8 flag;
        (val, flag) = __getAmountsToArb();
        console.log(uint256(val));    
        

        // console.log(_getInverseQ96());

        /*
        Py: 
        1/64: 3067482403643444351322816512
        64  : 2004331587000383570417679335424

        Solc:
        1/64:
        64  : 
        */
    }

    /*
    * Minting some acherons
    * Causing swaps to occur in weth/xskirk
    * Calling compound
    */
    function testCompounding() public {
        
        uint256 spotPrice = 3000e18;
        uint256 inverse = 1e36/spotPrice;
        uint160 inverseQ96 = _getQ96(inverse, 18, 18);
        (uint160 sqrtP,,,,,,) = IUniswapV3Pool(pool_dai_weth).slot0();
        if(sqrtP != inverseQ96){
        _shiftDAI_WETH_POOL(inverseQ96);
        _balanceWeth_xSkirk_Pool();
        }

        _mintAcheron(bob.addr);
        _mintAcheron(bob.addr);
        _mintAcheron(bob.addr);
        _mintAcheron(bob.addr);

        _simulateSwaps();

        vm.startPrank(alice.addr);
        acheron.compoundRewards();
        vm.stopPrank();
    }

    function _simulateSwaps() public {
        uint256 price = 10000e18;
        for(uint256 i; i < 20; i++){
        uint256 spotPrice = price + (i * 100e18);
        uint256 inverse = 1e36/spotPrice;
        uint160 inverseQ96 = _getQ96(inverse, 18, 18);
        (uint160 sqrtP,,,,,,) = IUniswapV3Pool(pool_dai_weth).slot0();
        if(sqrtP != inverseQ96){
        _shiftDAI_WETH_POOL(inverseQ96);
        _balanceWeth_xSkirk_Pool();
        }
        }
    }

    /*
    * Testing CompoundRewards with only xSkirk as rewards
    * Rewards must only be in xSkirk & get recompounded as such throughout all price ranges.
    */  
    function testCompoundOnlyAmount1() public {
        uint256 startingPriceBeforeLp = 800e18;
        uint256 inverse_start = 1e36/startingPriceBeforeLp;
        uint160 inverseQ96_start = _getQ96(inverse_start, 18, 18);
        _shiftDAI_WETH_POOL(inverseQ96_start);
        _balanceWeth_xSkirk_Pool();

        // Minting 8 Acherons:
        for(uint256 i; i < 8; i++){
            if(i > 3){
                _mintAcheron(alice.addr);
            }else{
                _mintAcheron(bob.addr);
            }
        }

        for(uint256 i = 1; i<20; i++){
            uint256 spotPrice = startingPriceBeforeLp + (i * 350e18);
            uint256 inverse = 1e36/spotPrice;
            uint160 inverseQ96 = _getQ96(inverse, 18, 18);
            (uint160 sqrtP,,,,,,) = IUniswapV3Pool(pool_dai_weth).slot0();
            if(sqrtP != inverseQ96){
            _shiftDAI_WETH_POOL(inverseQ96);
            _balanceWeth_xSkirk_Pool();
            acheron.compoundRewards();
            }
            }
           
    }
}