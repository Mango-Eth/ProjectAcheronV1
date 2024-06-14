// SPDX-License-Identifier: Built by Mango
pragma solidity ^0.8.20;

import "../Methods.sol";

contract DeBugging is Methods {

    using FullMath for uint256;
    using SafeCast for uint256;
    using SafeCast for int256;

    ///@notice Marks the median of Acherons Lp range.
    uint96 immutable internal MEDIAN_POINT = 10_000e18;

    uint160 immutable internal LG = 2378033000839262826893220031138;  // 903
    
    uint160 immutable internal UG = 11203153538136334211227743944704; // 19995
                         
    ///@notice 900 in q96.
    uint160 immutable internal tl_SqrtP = 2373597069249974917302093533021;
    
    ///@notice 20k in q96.
    uint160 immutable internal tu_SqrtP = 11182265215894369642182094599515;

    uint160 sqrtP_n = _getQ96(3000e18, 18, 18);

    uint256 price = 800e18;

    /*  General knowledge:
    LMS uses getLiquidityForAmount0(,, wethAmount - weight)

    UMS uses getLiquidityForAmount1(,, usdcAmount - weight)
    */

    /*
    * 
    */
    function testFindAmounts() public {
        uint128 l = upperMedianLiquidity();
        (uint256 a0, uint256 a1) = LiquidityMath.getAmountsForLiquidity(sqrtP_n, tl_SqrtP, tu_SqrtP, l);
        console.log("L      :", l);
        console.log("amounts:", a0, a1);
        console.log("sum    :", _wethToDai(price, a0) + a1);
        console.log("sqrtP  :", sqrtP_n);
    }

    function testGettingLFromZeroFunction() public {
        uint128 liquidity = LiquidityMath.getLiquidityForAmount0(tu_SqrtP, sqrtP_n, _daiToWeth(price, 339e18));
        console.log(_getSum(price, liquidity));
        (uint256 a0, uint256 a1) = _getAmounts(liquidity);
        console.log(a0, a1);
    }

    function testGettingLWithNewLMS() public {
        uint128 l = LiquidityMath.getLiquidityForAmount0(sqrtP_n, tu_SqrtP, _daiToWeth(price, 26e18));
        (uint256 a0, uint256 a1) = LiquidityMath.getAmountsForLiquidity(sqrtP_n, tl_SqrtP, tu_SqrtP, l);
        console.log("L      :", l);
        console.log("amounts:", a0, a1);
        console.log("sum    :", (_wethToDai(price, a0) + a1) / 1e18);
        console.log("sqrtP  :", sqrtP_n);
    }

    function testGettingLWithNewNewnew() public {
        uint128 l = LiquidityMath.getLiquidityForAmount0(sqrtP_n, tu_SqrtP, _daiToWeth(price, 26e18));
        (uint256 a0, uint256 a1) = LiquidityMath.getAmountsForLiquidity(sqrtP_n, tl_SqrtP, tu_SqrtP, l);
        console.log("L      :", l);
        console.log("amounts:", a0, a1);
        console.log("sum    :", (_wethToDai(price, a0) + a1) / 1e18);
        console.log("sqrtP  :", sqrtP_n);
    }

    function testGettingLWithNewNewnewNewNewNew() public {
        sqrtP_n = _getQ96(9000e18, 18, 18);
        price = 900e18;
        // uint128 l = LiquidityMath.getLiquidityForAmount0(sqrtP_n, tu_SqrtP, _daiToWeth(price, 94e18));
        uint128 l = LiquidityMath.getLiquidityForAmount1(sqrtP_n, tl_SqrtP, 94e18);
        (uint256 a0, uint256 a1) = LiquidityMath.getAmountsForLiquidity(sqrtP_n, tl_SqrtP, tu_SqrtP, l);
        console.log("L      :", l);
        console.log("amounts:", a0, a1);
        console.log("sum    :", (_wethToDai(price, a0) + a1) / 1e18);
        console.log("sqrtP  :", sqrtP_n);
        uint256 supposed = uint256(type(int256).min);
        require(supposed == 2**255, "asdf");
    }

    function testDifferenceWithNegative() public {
        int256 val0 = -120;
        int256 val1 = 36;
        bool z;
        if(abs(val0) < abs(val1)){
            z = true;
        }
        console.log(z);
    }

    event Emission46(int256, uint8);
    function testFindingNemoItSeems() public {
        uint128 miracle = attemptingToGetL(350e18, 800e18);

        // (int256 first, uint8 flag) = _first(100e18, 3000e18);
        // uint256 amount;
        // if(first < 0){
        //     amount = uint256(-first);
        // } else {
        //     amount = first.toUint256();
        // }
        // console.log(amount, flag);
        console.log(miracle);
    }

    function testFuzzingNewLiquidityFinder() public {
        uint256 fixWethPrice = 800e18;
        uint256 startingSqrtP = 890e18;

        for(uint256 i; i < 24110; i++){
            uint256 virtualSqrtPrice = startingSqrtP + (i * 1e18);
            sqrtP_n = _getQ96(virtualSqrtPrice, 18, 18);
            uint128 liquidity = attemptingToGetL(100e18, fixWethPrice);
            uint256 sum = _getSum(fixWethPrice, liquidity);
            if(sum < 96e18){
                console.log("Broke at:", virtualSqrtPrice / 1e18);
                console.log(sum);
                break;
            }
        }
    }

    function testFuzzingCompoundLiquidity() public {
        uint256 amount2Compound = 23e18;
        uint256 startingSqrtP = 890e18;

        for(uint256 a; a<24110; a++){
            uint256 virtualSqrtPrice = startingSqrtP + (a * 1e18);
            sqrtP_n = _getQ96(virtualSqrtPrice, 18, 18);
            for(uint256 i; i<200; i++){
                uint256 virtualCompAmount = amount2Compound + (i*1e18);
                uint128 liquidity = attemptingToGetL(100e18, virtualSqrtPrice);
                uint256 sum = _getSum(virtualSqrtPrice, liquidity);
                if(sum < virtualCompAmount.mulDiv(4, 100)){
                    console.log("Broke at:", virtualSqrtPrice / 1e18);
                    console.log(sum);
                    break;
                }
            }
        }
    }



    function testDebuggingNewErrorSpot() public {
        uint256 fixWethPrice = 800e18;
        uint256 startingSqrtP = 2000e18;

        uint256 virtualSqrtPrice = startingSqrtP;
        sqrtP_n = _getQ96(virtualSqrtPrice, 18, 18);
        uint128 liquidity = attemptingToGetL(350e18, fixWethPrice);
        uint256 sum = _getSum(fixWethPrice, liquidity);

    }

    event Sum0(uint256);
    event Sum1(uint256);
    function getSum0(uint256 amount, uint256 wethPrice) internal returns(uint256){
        (uint256 a0, uint256 a1) = LiquidityMath.getAmountsForLiquidity(sqrtP_n, tl_SqrtP, tu_SqrtP, LiquidityMath.getLiquidityForAmount0(sqrtP_n, tu_SqrtP, _daiToWeth(wethPrice, amount)));
        uint256 sum = _wethToDai(wethPrice, a0) + a1;
        emit EmitAmountIn(amount);
        return sum;
    }

    function getSum1(uint256 amount, uint256 wethPrice) internal returns(uint256){
        (uint256 a0, uint256 a1) = LiquidityMath.getAmountsForLiquidity(sqrtP_n, tl_SqrtP, tu_SqrtP, LiquidityMath.getLiquidityForAmount1(sqrtP_n, tl_SqrtP, amount));
        uint256 sum = _wethToDai(wethPrice, a0) + a1;
        emit EmitAmountIn(amount);
        return sum;
    }

    event EmitAmountIn(uint256);
    event Diffs(uint256);
    function attemptingToGetL(uint256 amount2Spend, uint256 wethPrice) internal returns(uint128){
        uint128 fl;
        uint256 target = amount2Spend - amount2Spend.mulDiv(4, 100);
        uint256 sum0 = getSum0(target, wethPrice);
        uint256 sum1 = getSum1(target, wethPrice);
        emit Sum0(sum0);
        emit Sum1(sum1);
        uint256 diff0 = (sum0 > target) ? sum0 - target : target - sum0;
        uint256 diff1 = (sum1 > target) ? sum1 - target : target - sum1;
        emit Diffs(diff0);
        emit Diffs(diff1);
        
        if(sum0 >= target && sum0 < amount2Spend){
            return LiquidityMath.getLiquidityForAmount0(sqrtP_n, tu_SqrtP, _daiToWeth(wethPrice, target));
        } else if(sum1 >= target && sum1 < amount2Spend){
            return LiquidityMath.getLiquidityForAmount1(sqrtP_n, tl_SqrtP, target);
        }

        uint8 limit;
        if(diff0 < diff1){  // Means weth needs to be manipulated.
            uint256 amount;
            if(sum0 > target){
                amount = diff0 > 10e18 ? target - diff0/2 : target - diff0;
            } else {
                amount = diff0 > 10e18 ? target + diff0/2 : target + diff0;
            }

            while(limit != 13){
                emit EmitAmountIn(amount);
                uint128 l = LiquidityMath.getLiquidityForAmount0(sqrtP_n, tu_SqrtP, _daiToWeth(wethPrice, amount));
                (uint256 a0, uint256 a1) = LiquidityMath.getAmountsForLiquidity(sqrtP_n, tl_SqrtP, tu_SqrtP, l);
                sum1 = _wethToDai(wethPrice, a0) + a1;
                emit Sum0(sum1 / 1e18);
                
                if( sum1 >= target && amount2Spend > sum1 ) {
                    fl = l;
                    break;
                } else if(sum1 > target){
                    diff0 = sum1 - target;
                    amount = diff0 > 1e18 ? amount - (diff0/2) : amount - diff0;
                } else if(sum1 < target){
                    diff0 = target - sum1;
                    amount = diff0 > 1e18 ? amount + (diff0/2) : amount + 1e18;
                }
            limit++;
            }
        } else {
            uint256 amount;
            if(sum1 > target){
                amount = diff1 > 10e18 ? target - diff1/2 : target - diff1;
            } else {
                amount = diff1 > 10e18 ? target + diff1/2 : target + diff1;
            }

            while(limit != 9){
                emit EmitAmountIn(amount);
                uint128 l = LiquidityMath.getLiquidityForAmount1(sqrtP_n, tl_SqrtP, amount);
                (uint256 a0, uint256 a1) = LiquidityMath.getAmountsForLiquidity(sqrtP_n, tl_SqrtP, tu_SqrtP, l);
                sum0 = _wethToDai(wethPrice, a0) + a1;
                emit Sum1(sum0 / 1e18);
                
                if( sum0 >= target && amount2Spend > sum0 ) {
                    fl = l;
                    break;
                } else if(sum0 > target){
                    diff1 = sum0 - target;
                    amount = diff1 > 10e18 ? amount - (diff1/2) : amount - diff1;
                } else if(sum0 < target){
                    diff1 = target - sum0;
                    amount = diff1 > 1e18 ? amount + (diff1/2) : amount + 1e18;
                }
            limit++;
            }
        }
        return fl;
    }

    event Confirm(uint256);
    event Flagger(uint8);
    event AmountsInside(uint256, uint256);
    function findL(uint256 amount2Spend, uint256 wethPrice) internal returns(uint128){
        uint256 target = amount2Spend - amount2Spend.mulDiv(4, 100);
        uint128 fl;
        uint8 limit;

        (int256 diff, uint8 flag) = _first(target, wethPrice);
        uint8 addUp = diff < 0 ? 1 : 0; // 1: + : 0: -
        uint256 difference = addUp == 1 ? uint256(-diff) : diff.toUint256();
        emit Confirm(difference);
        emit Flagger(flag);
        uint256 amount;
        if(addUp == 1){
            amount = difference > 10e18 ? target + difference/2 : target + difference;
        } else {
            amount = difference > 10e18 ? target - difference/2 : target - difference;
        }
        emit Confirm(amount);

        if(flag == 0){  // WETH
            while(limit != 9){
                uint128 l = LiquidityMath.getLiquidityForAmount0(sqrtP_n, tu_SqrtP, _daiToWeth(wethPrice, amount));
                (uint256 a0, uint256 a1) = LiquidityMath.getAmountsForLiquidity(sqrtP_n, tl_SqrtP, tu_SqrtP, l);
                emit AmountsInside(a0, a1);
                uint256 sum = _wethToDai(wethPrice, a0) + a1;
                emit Confirm(sum);
                if( sum >= target && amount2Spend > sum ) {
                    fl = l;
                    break;
                } else if(sum > target){
                    difference = sum - target;
                    require(addUp == 1 ? uint256(-diff) > difference : diff.toUint256() > difference, "add");    // TBDeleted
                    if(addUp == 1){
                        amount = difference >= 10e18 ? amount + difference/2 : amount + difference;
                    } else {
                        amount = difference >= 10e18 ? amount - difference/2 : amount - difference;
                    }
                } else if(sum < target){
                    difference = target - sum;
                    require(addUp == 1 ? uint256(-diff) > difference : diff.toUint256() > difference, "add");    // TBDeleted
                    if(addUp == 1){
                        amount = difference >= 10e18 ? amount + difference/2 : amount + difference;
                    } else {
                        amount = difference >= 10e18 ? amount - difference/2 : amount - difference;
                    }
                }
                limit++;
            }
        } else {
            while(limit != 9){
                uint128 l = LiquidityMath.getLiquidityForAmount1(tl_SqrtP, sqrtP_n, amount);
                (uint256 a0, uint256 a1) = LiquidityMath.getAmountsForLiquidity(sqrtP_n, tl_SqrtP, tu_SqrtP, l);
                // emit AmountsInside(a0, a1);
                uint256 sum = _wethToDai(wethPrice, a0) + a1;
                // emit Confirm(sum);
                if( sum >= target && amount2Spend > sum ) {
                    fl = l;
                    break;
                } else if(sum > target){
                    difference = sum - target;
                    require(addUp == 1 ? uint256(-diff) > difference : diff.toUint256() > difference, "add");    // TBDeleted
                    if(addUp == 1){
                        amount = difference >= 10e18 ? amount + difference/2 : amount + difference;
                    } else {
                        amount = difference >= 10e18 ? amount - difference/2 : amount - difference;
                    }
                } else if(sum < target){
                    difference = target - sum;
                    require(addUp == 1 ? uint256(-diff) > difference : diff.toUint256() > difference, "add");    // TBDeleted
                    if(addUp == 1){
                        amount = difference >= 10e18 ? amount + difference/2 : amount + difference;
                    } else {
                        amount = difference >= 10e18 ? amount - difference/2 : amount - difference;
                    }
                }
                limit++;
            }
        }
        return fl;
    }

    function _first(uint256 target, uint256 wethPrice) internal returns(int256 diff, uint8 flag){
        (uint256 a0, uint256 a1) = LiquidityMath.getAmountsForLiquidity(sqrtP_n, tl_SqrtP, tu_SqrtP, LiquidityMath.getLiquidityForAmount0(sqrtP_n, tu_SqrtP, _daiToWeth(wethPrice, target)));
        uint256 sum0 = _wethToDai(wethPrice, a0) + a1;
        (a0, a1) = LiquidityMath.getAmountsForLiquidity(sqrtP_n, tl_SqrtP, tu_SqrtP, LiquidityMath.getLiquidityForAmount1(tl_SqrtP, sqrtP_n, target));
        uint256 sum1 = _wethToDai(wethPrice, a0) + a1;

        int256 diff0 = SafeCast.toInt256(sum0) - SafeCast.toInt256(target);
        int256 diff1 = SafeCast.toInt256(sum1) - SafeCast.toInt256(target);
        emit Emission46(diff0, 0);
        emit Emission46(diff1, 1);
        if (abs(diff0) < abs(diff1)) {
            return (diff0, 0);
        } else if (abs(diff0) > abs(diff1)) {
            return (diff1, 1);
        } else {
            return (diff1, 1);
        }
    }

    function abs(int256 x) internal pure returns (int256) {
        return x < 0 ? -x : x;
    }

    function LMS() internal returns(uint128){
        uint256 amount2Spend = 350e18;
        // CACHE:
        uint256 totalAmount = amount2Spend;
        uint256 target = amount2Spend - amount2Spend.mulDiv(3, 100);    // 339.5 on mint
        uint256 wethPrice = price;
        // Small value:
        uint256 sumFourPercent = target / 25;   // 14
        uint256 sumOnePercent = target / 100;
        // Starting values:
        uint256 _a0 = _daiToWeth(wethPrice, target);                    // 200 dai worth in WETH at the current "price". 
        uint256 _a1 = totalAmount;                                      //Irrelevant since here WETH is favoured.      
        uint256 diff;
        // Stop the loop:
        uint8 limit;
        uint128 liquidity;

        emit PriceLimit(wethPrice, target);
        
        while(limit != 9){
            uint128 _L = LiquidityMath.getLiquidityForAmount0(sqrtP_n, tu_SqrtP, _a0);
            (uint256 a0, uint256 a1) = LiquidityMath.getAmountsForLiquidity(sqrtP_n, tl_SqrtP, tu_SqrtP, _L);
            uint256 value = _wethToDai(wethPrice, a0);
            uint256 sum = value + a1;
            
            // Checking if ratios satisfy to break:
            if(sum >= target && totalAmount > sum){
                _a0 = a0;
                liquidity = _L;
                break;
            } else if(sum > target){        // Spread exceeds budget:
                diff = sum - target;
                _a1 = a1;                   // Irrelevant
                _a0 = diff > sumFourPercent ? _a0 - (_daiToWeth(wethPrice, diff) / 2) : _a0 - _daiToWeth(wethPrice, diff);
            } else if(sum < target){
                diff = target - sum;
                _a1 = _a1 + diff;           
                _a0 = diff > sumOnePercent ? _a0 + (_daiToWeth(wethPrice, diff) / 2) : _a0 + _daiToWeth(wethPrice, diff);
            }
            limit++;
            emit IterationAmounts(_a0, _a1, sum, diff);
            }
            return liquidity;
    }


    event PriceLimit(uint256, uint256);
    event IterationAmounts(uint256, uint256, uint256, uint256);
    function lowerMedianLiquidity() internal returns(uint128) {
        uint256 amount2Spend = 350e18;
        // CACHE:
        uint256 totalAmount = amount2Spend;
        uint256 target = amount2Spend - amount2Spend.mulDiv(3, 100);    // 339.5 on mint
        uint256 wethPrice = price;
        // Small value:
        uint256 sumFourPercent = target / 25;   // 14
        uint256 sumOnePercent = target / 100;
        // Starting values:
        uint256 _a0 = _daiToWeth(wethPrice, target);                    // 200 dai worth in WETH at the current "price". 
        uint256 _a1 = totalAmount;                                      //Irrelevant since here WETH is favoured.      
        uint256 diff;
        // Stop the loop:
        uint8 limit;

        emit PriceLimit(wethPrice, target);
        
        while(limit != 9){
            uint128 _L = LiquidityMath.getLiquidityForAmounts(sqrtP_n, tl_SqrtP, tu_SqrtP, _a0, _a1);
            (uint256 a0, uint256 a1) = LiquidityMath.getAmountsForLiquidity(sqrtP_n, tl_SqrtP, tu_SqrtP, _L);
            uint256 value = _wethToDai(wethPrice, a0);
            uint256 sum = value + a1;
            
            // Checking if ratios satisfy to break:
            if(sum >= target && totalAmount > sum){
                _a0 = a0;
                _a1 = a1;
                break;
            } else if(sum > target){        // Spread exceeds budget:
                diff = sum - target;
                _a1 = a1;                   // Irrelevant
                _a0 = diff > sumFourPercent ? _a0 - (_daiToWeth(wethPrice, diff) / 2) : _a0 - _daiToWeth(wethPrice, diff);
            } else if(sum < target){
                diff = target - sum;
                _a1 = _a1 + diff;           
                _a0 = diff > sumOnePercent ? _a0 + (_daiToWeth(wethPrice, diff) / 2) : _a0 + _daiToWeth(wethPrice, diff);
            }
            limit++;
            emit IterationAmounts(_a0, _a1, sum, diff);
            }
            return (LiquidityMath.getLiquidityForAmounts(sqrtP_n, tl_SqrtP, tu_SqrtP, _a0, _a1));
    }

    function upperMedianLiquidity() internal returns(uint128){
        uint256 amount2Spend = 350e18;
        // CACHE:
        uint256 totalAmount = amount2Spend;                             // 200e18
        uint256 target = amount2Spend - amount2Spend.mulDiv(3, 100);    // 194e18
        uint256 wethPrice = price;
        // Small value:
        uint256 sumOnePercent = target / 100;
        // Starting values:
        uint256 _a0 = 1e18;         //Irrelevant since here xSKIRK is favoured.
        uint256 _a1 = target;                                           // 194e18 on first iteration.
        uint256 diff;
        // Stop the loop:
        uint8 limit;

        emit PriceLimit(wethPrice, target);

        // Starting loop:
        while(limit != 9){
            uint128 _L = LiquidityMath.getLiquidityForAmounts(sqrtP_n, tl_SqrtP, tu_SqrtP, _a0, _a1);
            (uint256 a0, uint256 a1) = LiquidityMath.getAmountsForLiquidity(sqrtP_n, tl_SqrtP, tu_SqrtP, _L);
            uint256 value = _wethToDai(wethPrice, a0);
            uint256 sum = value + a1;

            // Checking if ratios satisfy to break:
            if(sum >= target && totalAmount > sum){
                _a0 = a0;
                _a1 = a1;
                break;
            } else if(sum > target){        // Spread exceeds budget:
                // Check by how much this L overpays:
                diff = sum - target;

                _a0 = a0;                   // Again irrelevant
                // Large diff: reduces xSkirk amount by half the difference.
                // Low diff  : reduces xSkirk by exactly said difference.
                _a1 = diff > sumOnePercent ? a1 - (diff/2) : _a1 - diff;

            } else if(sum < target){        // Spread is bellow min deposit
                // Checks by how much this L is missing target.
                diff = target - sum;
                _a0 = a0;                   // u know
                _a1 = _a1 + diff;           // Here we just add the difference regardless.
            }
            // emit LowerM(_price, a0, a1, _a0, _a1, diff, sum);
            limit++;
            emit IterationAmounts(_a0, _a1, sum, diff);
        }
        return(LiquidityMath.getLiquidityForAmounts(sqrtP_n, tl_SqrtP, tu_SqrtP, _a0, _a1));
    }


    function _getSum(uint256 price2Pay, uint128 liquidity) internal returns(uint256){
        (uint256 a0, uint256 a1) = LiquidityMath.getAmountsForLiquidity(sqrtP_n, tl_SqrtP, tu_SqrtP, liquidity);
        return _wethToDai(price2Pay, a0) + a1;
    }

    function _getAmounts(uint128 liquidity) internal returns(uint256 a0, uint256 a1){
        (a0, a1) = LiquidityMath.getAmountsForLiquidity(sqrtP_n, tl_SqrtP, tu_SqrtP, liquidity);
    }
}