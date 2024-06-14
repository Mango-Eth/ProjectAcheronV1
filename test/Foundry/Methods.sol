// SPDX-License-Identifier: Built by Mango
pragma solidity ^0.8.20;

import {ISwapRouter} from "MangoHat/mangoUtils/Uni-Foundry/interfaces/ISwapRouter.sol";
import {LiquidityMath} from "MangoHat/mangoUtils/Uni-Math/LiquidityMath.sol";
import {TickMath} from "MangoHat/mangoUtils/Uni-Math/TickMath.sol";
import {FullMath} from "MangoHat/mangoUtils/Uni-Math/FullMath.sol";

import "./Setup.sol";

contract Methods is Setup {

    using FullMath for uint256;
    using TickMath for int24;
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using ABDKMath64x64 for uint256;
    using ABDKMath64x64 for int128;

    function setUp() public override virtual {
        super.setUp();

        int24 lowerTick = -276527;
        int24 upperTick = -276122;
        (uint256 a0, uint256 a1) = _depositLiquidity(
            pool_dai_usdc,
            1_000_000e18,
            1_000_000e6,
            admin.addr,
            lowerTick,         // ~1
            upperTick          // ~1
        );
        // console.log("DAI USDC:", a0/1e18, a1/1e6);

        lowerTick = -105800;      // 500 - 40k
        upperTick = -62000;     // fee:500 must be divisable by 200 
        (a0, a1) = _depositLiquidity(
            pool_dai_weth,
            8_000_000e18,
            2754e18,
            admin.addr,
            lowerTick,         
            upperTick        
        );
        // console.log("DAI WETH 500:", a0/1e18, a1/1e18);

        lowerTick = -105960;      // 500 - 40k
        upperTick = -61980;     // fee:3000 must be divisable by 60 
        (a0, a1) = _depositLiquidity(
            pool_dai_weth_3000,
            8_000_000e18,
            2754e18,
            admin.addr,
            lowerTick,        
            upperTick          
        );
        // console.log("DAI WETH 3000:", a0/1e18, a1/1e18);

        /*
        This contract provides liquidity to (DAI_USDC, DAI_WETH, DAI_WETH)
        DAI USDC:           666_447     1_000_000               Price: 1
        DAI WETH 500:       7_860_711   2754                    Price: 3100
        DAI WETH 3000:      7_874_520   2754
        */
    }

    /*
    * The given exchangeRate passed, must be in base 18.
    * The given decimals must represent the expected decimal discrepancy if there is any.
    * Returns a fixed point sqrtPrice value for the given exchange rate.
    */
    function _getQ96(uint256 erInBase18, uint256 d0, uint256 d1) internal view returns(uint160){
        if(d0 == d1){
            // Regular sqrtPrice.
            return _x96(erInBase18);
        }else {
            uint8 dir = d1 > d0 ? 1 : 0;
            uint256 sf = dir == 1 ? 10**(d1 - d0) : 10**(d0 - d1);
            uint256 scaledExchangeRate = dir == 1 ? erInBase18 * sf : erInBase18 / sf;
            return _x96(scaledExchangeRate);
        }
    }

    /*
    * Can be directly used over _getQ96() if the decimals are equal.
    * Returns a fixed point sqrtPrice value for the given exchange rate.
    */
    function _x96(uint256 er) internal view returns(uint160){
        // Since _getQ96 requires the ratio to be in base 18 in case d1 < d0, we rescale by the root of said base.
        return SafeCast.toUint160(q96.mulDiv(sqrtu(er), sqrtu(1e18)));
    }

    /*
    * Turns a sqrtPrice value back into its exchangeRate in base 18. 
    * Reversed ER's need to be divided by 1e36 to get its counter part.
    */
    function _getErInBase18(uint160 sqrtPrice, uint256 d0, uint256 d1) internal pure returns(uint256 price){
        uint8 flag = d1 < d0 ? 0 : 1;
        if(flag == 0){
            uint256 numerator1 =uint256(sqrtPrice) *uint256(sqrtPrice);  
            uint256 numerator2 = 1e18 * 10**(d0-d1); 
            price = FullMath.mulDiv(numerator1, numerator2, 1 << 192);
        } else {
            uint256 numerator1 =uint256(sqrtPrice) *uint256(sqrtPrice);  
            uint256 numerator2 = 1e18 / 10**(d1 -d0);                // Lowering 1e18 base by decimal difference.
            uint256 _price = FullMath.mulDiv(numerator1, numerator2, 1 << 192);
            price = _price;
        }
    } 


    /*
    * Earning fees on v3 pool by doing swaps.
    */
    function _earnFees(address pool) internal {
        (uint160 sqrtP_n,,,,,,) = IUniswapV3Pool(pool).slot0();
        _arbitragePool(pool, TickMath.MAX_SQRT_RATIO - 1);
        _arbitragePool(pool, sqrtP_n);
    }
    
    /*
    * Inverts a given sqrtPrice value passed into its correct ER in base 18.
    * Basically: 1e36 / _getErInBase18();
    */
    function _getInverseQ96(uint160 sqrtP, uint256 d0, uint256 d1) internal view returns(uint160){
        uint256 erInBase18 = _getErInBase18(sqrtP, d0, d1);         // RAW ER so 6400e18
        uint256 inverse = 1e36 / erInBase18;                        // .0000156250000000000 Raw inverse ER in base 1e18
        if(d0 == d1){
            uint256 _q96_ = q96.mulDiv(sqrtu(inverse), sqrtu(1e18));
            return SafeCast.toUint160(_q96_);
        }
        // Inversing decimals:
        inverse = d0 > d1 ? inverse * 10**(d0 - d1) : inverse / 10**(d1 - d0);  // Shifting to match correct decimal exchange
        uint256 _q96 = q96.mulDiv(sqrtu(inverse), sqrtu(1e18));
        return SafeCast.toUint160(_q96);
    }

    /*
    * Mints all 3 potions to a given address
    */
    function _mintPotions(address to) internal {
        uint256 skirkRequired = 3000e18;
        _mintSkirk(skirkRequired, to);
        vm.startPrank(to);
        xSKIRK.approve(address(potionGreen), 2**256-1);
        xSKIRK.approve(address(potionBlue), 2**256-1);
        xSKIRK.approve(address(potionPurple), 2**256-1);
        potionGreen.mint();
        potionBlue.mint();
        potionPurple.mint();
        vm.stopPrank();
    }

    /*
    * Mint specified amount of tokens and provide allowance of said range as well.
    * Needs to be wrapped by prank.
    */
    function _mintApprove(
        MockERC20 tkn,
        address allowTo,
        uint256 amount
    ) internal {
        tkn.mint(amount);
        tkn.approve(allowTo, amount);
    }

    /*
    * Mints an acheron
    */
    function _mintAcheron(
        address to
    ) internal returns(uint256 id){
        uint256 skirkRequired = 1000e18;
        _mintSkirk(skirkRequired, to);
        vm.startPrank(to);
        xSKIRK.approve(address(acheron), skirkRequired);

        id = acheron.mint(false);
        vm.stopPrank();
    }

    ///@notice Returns DAI exchangeRate for a given wethAmount.
    function _wethToDai(uint256 _wethPrice, uint256 _wethAmount) internal pure returns (uint256 daiER) {
        daiER = (_wethPrice * _wethAmount) / 1e18;
    }

    ///@notice Returns WETH exchangeRate for a given daiAmount.
    function _daiToWeth(uint256 _wethPrice, uint256 _daiAmount) internal pure returns(uint256){
        return (_daiAmount * 1e18) / _wethPrice;
    }

    /*
    * Mints asked amount of xSkirk to designated address
    */
    function _mintSkirk(
        uint256 amountExpected,
        address to
    ) internal returns(uint256){
        vm.startPrank(to);
        uint256 amountToMint = xSKIRK.getSkirkForDai(amountExpected);
        dai.mint(amountToMint);
        dai.approve(address(xSKIRK), amountToMint);
        uint256 result = xSKIRK.exactSkirkOut(amountExpected);
        vm.stopPrank();
        return result;
    }

    /*   @Mango
    * Arbitrages any given v3 pool back to a desired price.
    * Contract inheriting Methods, needs to overrite swapCallback for this to work. 
    */                                      
    function _arbitragePool(
        address pool,
        uint160 sqrtPriceLimit
    ) internal returns(uint256 used, uint8 tknIn){
        (uint160 sqrtP_n,,,,,,) = IUniswapV3Pool(pool).slot0();
        tknIn = sqrtPriceLimit > sqrtP_n ? 1 : 0;    // 1: token1In, 0: token0In
        uint256 swapAmount = 2**96;
        (int256 a0, int256 a1) = IUniswapV3Pool(pool).swap(
            address(0x3333),
            tknIn == 0 ? true : false,
            -swapAmount.toInt256(),
            sqrtPriceLimit,
            ""
        );
        used = tknIn == 0 ? uint256(-a1) : uint256(-a0);
    }

    /*
    * Arbitrages DAI/WETH(500), DAI/WETH(3000)
    */
    function _arbPoolsWETH(uint256 rawErIn18) internal {
        uint256 wethPrice = 1e36/rawErIn18;
        (uint160 sqrtP,,,,,,) = IUniswapV3Pool(pool_dai_weth_3000).slot0();
        uint256 spotEr = _getErInBase18(sqrtP, 18, 18); 
        uint8 dir = spotEr > wethPrice ? 1 : 0; // 1: goes up, 0: goes down.
        uint256 difference = dir == 1 ? spotEr - wethPrice : wethPrice - spotEr;

        if(difference > 0){
        _arbitragePool(pool_dai_weth_3000, _getQ96(wethPrice, 18, 18));
        _arbitragePool(pool_dai_weth, _getQ96(wethPrice, 18, 18));
        }
    }

    /*
    * Arbitrages DAI/WETH(500), DAI/WETH(3000), WETH/SKIRK
    */
    function _arbPools(uint256 rawErIn18) internal {
        uint256 wethPrice = 1e36/rawErIn18;
        uint256 wethSkirk = rawErIn18 - rawErIn18.mulDiv(10, 100);
        (uint160 sqrtP,,,,,,) = IUniswapV3Pool(pool_dai_weth_3000).slot0();
        uint256 spotEr = _getErInBase18(sqrtP, 18, 18); 
        uint8 dir = spotEr > wethPrice ? 1 : 0; // 1: goes up, 0: goes down.
        uint256 difference = dir == 1 ? spotEr - wethPrice : wethPrice - spotEr;

        if(difference > 0){
        _arbitragePool(pool_dai_weth_3000, _getQ96(wethPrice, 18, 18));
        _arbitragePool(pool_dai_weth, _getQ96(wethPrice, 18, 18));
        _arbitragePool(pool_weth_xSkirk, _getQ96(wethSkirk, 18, 18));
        }
    }
    /*
    349824999999999999999
    211 + 0.088638649665945184

    259396361458842661 1000000000000000000

    350420821941981512 + 146374187952578167
    349 + 0.1
    */

    /*
    * Tick to sqrtPrice.
    */
    function _tickToQ96(int24 tick) internal pure returns(uint160){
        return TickMath.getSqrtRatioAtTick(tick);
    }
    /*
    * SqrtPrice to tick.
    */
    function _sqrtPriceToTick(uint160 sqrtP) internal pure returns(int24){
        return TickMath.getTickAtSqrtRatio(sqrtP);
    }












    //              waste lands 
    ///////////////////////////////////////////////////////////////

    function _shiftDAI_WETH_POOL(uint160 targetPrice) internal {
        (uint160 sqrtP,,,,,,) = IUniswapV3Pool(pool_dai_weth).slot0();
        uint8 dir = targetPrice > sqrtP ? 2 : 1;

        IUniswapV3Pool(pool_dai_weth).swap(
            address(0xdead),
            dir == 2 ? false : true,
            2**96,
            targetPrice,
            ""
        );
    }

    /*
    * Arbitrage function for xSKIRK/WBTC pool in respect to WBTC/DAI price.
    */
    function _balanceWeth_xSkirk_Pool() internal {
        uint248 target;
        uint8 dir;
        (target, dir) = __getAmountsToArb();
        if(dir != 3){
        uint160 limit = _getQ96(uint256(target), 18, 18);

        IUniswapV3Pool(pool_weth_xSkirk).swap(
            address(0xdead),
            dir == 1 ? true : false,
            2**96,  // Overswap by non realistic amount to reach limit
            limit,
            ""
        );
        }
    }

    function __getAmountsToArb() internal view returns(uint248, uint8){
        (uint160 sqrtP,,,,,,) = IUniswapV3Pool(pool_dai_weth).slot0();
        uint160 inversedQ96 = _getInverseQ96(sqrtP, 18, 18);    // So 3000/1 
        uint256 exchangeRate = _getErInBase18(inversedQ96, 18, 18); // In base 1e18
        (sqrtP,,,,,,) = IUniswapV3Pool(pool_weth_xSkirk).slot0();
        uint256 syntheticWethSkirkPrice = _getErInBase18(sqrtP, 18, 18);    // IN base 1e18
        // DAI/WETH price - 0.1%
        uint256 targetRange = exchangeRate - (exchangeRate / 10);
        // Creating grid
        uint256 limit = targetRange / 100;  // allowing 1% discrepancy
        if(targetRange + limit > syntheticWethSkirkPrice && targetRange - limit < syntheticWethSkirkPrice) {
            return(0, 3);
        } else {
            // 1: Meaning (weth/skirk) pool needs to reduce its price, 2: ... Increase it
            uint8 dir = targetRange < syntheticWethSkirkPrice ? 1 : 2;
            // uint256 difference = dir == 1 ? syntheticWbtcPriceInbase18 - targetRange : targetRange - syntheticWbtcPriceInbase18;
            return(SafeCast.toUint248(targetRange), dir);
        }
    }

    /*
    * Deposits LP into a v3 pool
    */
    event Amount(uint256);
    function _depositLiquidity(
        address pool,
        uint256 amount0,
        uint256 amount1,
        address caller,
        int24 tl,
        int24 tu
    ) internal returns(uint256 _a0, uint256 _a1){
        vm.startPrank(caller);
        (uint160 sqrtP,,,,,,) = IUniswapV3Pool(pool).slot0();
        // Getting L:
        uint128 L = LiquidityMath.getLiquidityForAmounts(
            sqrtP,
            tl.getSqrtRatioAtTick(),
            tu.getSqrtRatioAtTick(),
            amount0,
            amount1
        );

        // Actual amounts:
        uint256 a0;
        uint256 a1;

        (a0, a1) = LiquidityMath.getAmountsForLiquidity(
            sqrtP,
            tl.getSqrtRatioAtTick(),
            tu.getSqrtRatioAtTick(),
            L
        );
    
        //Minting approving:
        MockERC20(IUniswapV3Pool(pool).token0()).mint(a0 + 1);
        MockERC20(IUniswapV3Pool(pool).token1()).mint(a1 + 1);

        MockERC20(IUniswapV3Pool(pool).token0()).approve(address(universalAggregator), a0 + 1);
        MockERC20(IUniswapV3Pool(pool).token1()).approve(address(universalAggregator), a1 + 1);

        (_a0, _a1) = universalAggregator.mintWithParams(
            IUniswapV3Pool(pool).token0(),
            IUniswapV3Pool(pool).token1(),
            IUniswapV3Pool(pool).fee(),
            tl, 
            tu,
            L
        );
        vm.stopPrank();
    }

    /*
    * Swaps using exactIn()
    * Does not need prior approval, nor having enough balance.
    */
    function _swapSpecificTokenIn(
        address pool,
        address tokenIn,
        uint256 amountIn,
        address caller
    ) internal returns(uint256){
        vm.startPrank(caller);

        // Since we are only swapping this fix amount in, we can already mint & approve said sum.
        MockERC20(tokenIn).mint(amountIn);
        MockERC20(tokenIn).approve(address(mangoSwapRouter), amountIn);

        uint8 b;
        uint256 amountSpent;
        if(IUniswapV3Pool(pool).token0() == tokenIn) b = 1;

        // Slippage protection pending.
        // Get SqrtP, bool of token being swapped, ratio/1 or 1/ratio depending on direction.
        // exactAmountOut * decimal / sqrtP of opposite token, then add 4%.

        (uint160 sqrtP,,,,,,) = IUniswapV3Pool(pool).slot0();
        uint256 decimal0 = uint256(MockERC20(IUniswapV3Pool(pool).token0()).decimals());
        uint256 decimal1 = uint256(MockERC20(IUniswapV3Pool(pool).token1()).decimals());

        // TokenIn is t0, therefore the price would be in terms of t0, using sqrtP directly:
        uint256 valueInOppositeToken;
        if(b == 1){
            // Meaning wbtc in, yields 64k e18. Therefore 1 t0 = sqrP.
            uint256 priceInBaseDeciaml1 = _getPrice(sqrtP, decimal0, decimal1);
            valueInOppositeToken = _calculateAmount(priceInBaseDeciaml1, amountIn, decimal1);
        } else {
            // Meaning dai in, yields 1/64k e8. Therefore 1 t1 = 1/sqrP.
            uint256 priceInBaseDeciaml0 = _getPrice(sqrtP, decimal0, decimal1);
            valueInOppositeToken = _calculateAmount(priceInBaseDeciaml0, amountIn, decimal0);
        }
        amountSpent = valueInOppositeToken - (valueInOppositeToken / 25);

        uint256 amountOut = mangoSwapRouter.exactInputSingle(ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: b == 1 ? IUniswapV3Pool(pool).token1() : IUniswapV3Pool(pool).token0(),
            fee: IUniswapV3Pool(pool).fee(),
            recipient: caller,
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: amountSpent,
            sqrtPriceLimitX96: 0
        }));
        vm.stopPrank();
        return amountOut;
    }

    /*
    * Swaps using exactIn()
    * Needs approval & having enough balance to cover for "amountIn".
    */
    function _swapSpecificTokenIn_(
        address pool,
        address tokenIn,
        uint256 amountIn,
        address caller
    ) internal returns(uint256){
        vm.startPrank(caller);
        uint8 b;
        if(IUniswapV3Pool(pool).token0() == tokenIn) b = 1;

        uint256 amountOut = mangoSwapRouter.exactInputSingle(ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: b == 1 ? IUniswapV3Pool(pool).token1() : IUniswapV3Pool(pool).token0(),
            fee: IUniswapV3Pool(pool).fee(),
            recipient: caller,
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: amountIn - ((amountIn * 4) / 100),
            sqrtPriceLimitX96: 0
        }));
        vm.stopPrank();
        return amountOut;
    }

    // /*
    // * Swaps using exactOutput()
    // * Does not need prior approval, nor having enough balance.
    // */
    // function _swapForSpecificTokenOut(
    //     address _pool,
    //     address tokenExpectedOut,
    //     uint256 exactAmountOut,
    //     address caller
    // ) internal returns(uint256){
    //     vm.startPrank(caller);

    //     uint8 b;
    //     address tokenIn;
    //     address tokenOut;
    //     uint256 amountOut;
    //     address user;
    //     uint256 amountSpent;
    //     if(IUniswapV3Pool(_pool).token0() == tokenExpectedOut) b = 1;
    //     (tokenIn, tokenOut, amountOut, user) = b == 1 ? (IUniswapV3Pool(_pool).token1(), tokenExpectedOut, exactAmountOut, caller) : (IUniswapV3Pool(_pool).token0(), tokenExpectedOut, exactAmountOut, caller);

    //     // Slippage protection pending.
    //     // Get SqrtP, bool of token being swapped, ratio/1 or 1/ratio depending on direction.
    //     // exactAmountOut * decimal / sqrtP of opposite token, then add 4%.

    //     (uint160 sqrtP,,,,,,) = IUniswapV3Pool(_pool).slot0();
    //     uint256 decimal0;
    //     uint256 decimal1;

    //     {
    //     address pool = _pool;
    //     (decimal0, decimal1) = b == 1 ? (MockERC20(tokenOut).decimals(), MockERC20(tokenIn).decimals()) : (MockERC20(tokenIn).decimals(), MockERC20(tokenOut).decimals());

    //     // TokenIn is t0, therefore the price would be in terms of t0, using sqrtP directly:
    //     uint256 valueInOppositeToken;
    //     if(b == 1){
    //         // Meaning wbtc in, yields 64k e18. Therefore 1 t0 = sqrP.
    //         uint256 priceInBaseDeciaml1 = _getPrice(sqrtP, decimal0, decimal1);
    //         valueInOppositeToken = _calculateValue(priceInBaseDeciaml1, amountOut, decimal0);
    //         emit Amount(priceInBaseDeciaml1);
    //         emit Amount(valueInOppositeToken);
    //     } else {
    //         // Meaning dai in, yields 1/64k e8. Therefore 1 t1 = 1/sqrP.
    //         uint256 priceInBaseDeciaml1 = _getPrice(_invertSqrtP(sqrtP, decimal0, decimal1), decimal1, decimal0);
    //         valueInOppositeToken = _calculateAmount(priceInBaseDeciaml1, amountOut, decimal0);
    //     }
        
    //     uint256 valueWithSplippageProtection = valueInOppositeToken + (valueInOppositeToken / 10);
    //     _mintApprove(MockERC20(tokenIn), address(mangoSwapRouter), valueWithSplippageProtection);
    //     // MockERC20(tokenIn).mint(valueWithSplippageProtection);
    //     // MockERC20(tokenIn).approve(address(mangoSwapRouter), valueWithSplippageProtection);
        
    //     amountSpent = mangoSwapRouter.exactOutputSingle(ISwapRouter.ExactOutputSingleParams({
    //         tokenIn: tokenIn,
    //         tokenOut: tokenOut,
    //         fee: IUniswapV3Pool(pool).fee(),
    //         recipient: user,
    //         deadline: block.timestamp,
    //         amountOut: amountOut,
    //         amountInMaximum: valueWithSplippageProtection,
    //         sqrtPriceLimitX96: 0
    //     }));
    //     _burn(MockERC20(tokenIn), valueWithSplippageProtection - amountSpent);
    //     vm.stopPrank();
    //     return amountSpent;
    //     }
    // }




    //////////////////////////////////////////////////////////////////////
    //                       Derived                                    //
    //////////////////////////////////////////////////////////////////////

    function _getOpposingExchangeRate(
        uint256 decimalTarget,
        uint256 decimalOpposite,
        uint160 sqrtP 
    ) internal pure returns(uint256){

    }
    
    /*
    * Sends tokens to dead address.
    * Requires prior pranking of user to call function on.
    */
    function _burn(
        MockERC20 tkn,
        uint256 amount
    ) internal {
        tkn.transfer(address(0xdead), amount);
    }

    /*
    * Returns the price ratio of a given q96.
    * Returns the price in base n decimals, from token1.
    * Always returns price in 18 decimals. (Even with both decimals under 18)
    */
    function _getPrice(uint160 sqrtRatioX96, uint dec0, uint dec1) internal pure returns (uint256 price){
        uint256 dec = dec1<=dec0 ? (18-dec1)+dec0 :dec0;
        uint256 numerator1 =uint256(sqrtRatioX96) *uint256(sqrtRatioX96);  
        uint256 numerator2 =10**dec; 
        price = FullMath.mulDiv(numerator1, numerator2, 1 << 192);
    }

    /*
    * Returns sqrtPrice of a given ratio.
    */
    function _getSqrP(uint256 exchangeRate, uint256 d0, uint256 d1) internal pure returns(uint160 sqrtPrice){
        if(d0 != d1){
            uint256 adjustedPrice = d1 > d0 ? exchangeRate * ( 10 ** (d1 - d0)) : exchangeRate * ( 10 ** (d0 - d1));
            // Turning into fixedPoint 64 to use the squareRoot function:
            sqrtPrice = SafeCast.toUint160(sqrtu(adjustedPrice) * (2**96));
        } else {
            sqrtPrice = SafeCast.toUint160(sqrtu(exchangeRate)* (2**96));
        }   
    }

    // function _getExchangeRate(uint160 sqrtP, uint256 d0, uint256 d1) internal pure returns(uint256){
    //     return (uint256(sqrtP).mulDiv(uint256(sqrtP), (2**192)));
    // }

    /*
    * DEFINITE FUNCTION TO GET Q96 SQRTPRICE.
    * Requires: ER to be in 1e18 base, to represent floats.
    */

    /*
    * Turns float to respective q96 fixed point numbers square root.
    * The float must already be scaled by token0's decimals.
    * DAI/WETH: (1/3000) * 1e18. ~33e13
    */
    // function _floatToSqrtPrice(uint256 float, uint256 d0, uint256 d1) internal returns(uint160 result){
    //         if(d0 == d1){
    //         uint256 unScaledResult = sqrtu(float) * (2**96);
    //         result = SafeCast.toUint160(unScaledResult / sqrtu(10 ** d0));
    //         }else {
    //             uint256 scaled = _scaleDecimals(float, d0, d1);
    //             uint256 res = q96.mulDiv(sqrtu(scaled), sqrtu(1e18 * (10**d0)));
    //             result = SafeCast.toUint160(res);
    //         }
    // }

    // function _scaleDecimals(uint256 rawER, uint256 d0, uint256 d1) internal returns(uint256 result){
    //     uint256 base = 1e18;                                // Base will be 1e18.
    //     uint256 decimalsFactor = d1 > d0 ? base * 10**(d1 - d0) : base / 10**(d0 - d1);
    //     result = rawER * decimalsFactor;
    // }

    // function _inverseAgain(uint160 q96, uint256 d0, uint256 d1) internal returns(uint256){
    //     uint256 tokenAInDecimalB = _getPrice(q96, d0, d1);
    //     uint256 baseInOppositeDecimal = 10**d1;             // 1e8
    //     return baseInOppositeDecimal.mulDiv((10**d0), tokenAInDecimalB);
    //     // return baseInOppositeDecimal / tokenAInDecimalB;    // 1e8 / 1560
    // }

    // function _getSqrtPriceDecimal0(uint256 er_decimal0, uint256 d0) internal returns(uint160){
    //     return SafeCast.toUint160(q96.mulDiv(sqrtu(er_decimal0), (sqrtu(10**d0))));
    // }



    // /*
    // * Returns sqrPrice for decimal point price.
    // * Rerquires the exchangeRate to already account for both deciamls.
    // */
    // function _getSqrtP_Decimal(uint256 exchangeRateInDecimal0) internal pure returns(uint160 sqrtPrice){
    //     sqrtPrice = SafeCast.toUint160(sqrtu(exchangeRateInDecimal0) * (2**96));
    // }

    // function _getSqrtP_Decimal_TBD(uint256 er) internal pure returns(uint160 sqrtPrice){
    //     sqrtPrice = SafeCast.toUint160((sqrtu(er) * (2**96)/(10**9)));
    // }

    // function getSquareRootPriceX96(uint256 exchangeRate, uint8 token0Decimals, uint8 token1Decimals) public pure returns (uint160) {
    //     uint256 token0Multiplier = 10 ** token0Decimals;
    //     uint256 token1Multiplier = 10 ** token1Decimals;
    
    //     uint256 priceRatio = (exchangeRate * token1Multiplier) / token0Multiplier;
    //     uint160 squareRootPriceX96 = SafeCast.toUint160(sqrtu(priceRatio << 96));
    
    //     return squareRootPriceX96;
    // }

    // /*
    // * Returns 1 dividey by the given q96 exchange rate.
    // * Wont return a uint256, since decimal points cant be represented there.
    // * Returns the inverse ratio in fixed point q96.
    // */
    // function _invertSqrtP(uint160 sqrtP, uint256 dec0, uint256 dec1) internal pure returns(uint160 inverseSqrtP){
    //     // We get the sqrtPrice target, without any decimals:
    //     uint256 rawPrice = _getPrice(sqrtP, dec0, dec1) / (10 ** 18);

    //     if(dec0 != dec1){
        
    //     rawPrice = dec1 > dec0 ? rawPrice * (10 ** (dec1 - dec0)) : rawPrice * (10 ** (dec0 - dec1));

    //     int128 num = 1 << 64;
    //     int128 den = rawPrice.fromUInt();
    //     inverseSqrtP = _sqrP(num.div(den));
    //     } else {
    //     int128 num = 1 << 64;
    //     int128 den = rawPrice.fromUInt();
    //     inverseSqrtP = _sqrP(num.div(den));
    //     }
    // }
    

    /*
    * Modular function to calculate price in terms of the passed decimals & invert the sqrtP to either
        - 1/sqrtP -> in terms of t1.
        - sqrtP/1 -> in terms of t0.

        ** Could potentially, have the passed in price already be in the opposite base. **
        @Mango
    */
    function _calculateAmount(uint256 _price, uint256 _oppositeAmountRequired, uint256 _decimalOut) internal pure returns(uint256){
        // I might have to factor the amount out times the opposite decimal, while the delta * current decimal.
        return (_oppositeAmountRequired * (10 ** _decimalOut)) / _price;
    }

    /*
    * Inverse from above.
    * Also requires that the price in, already be in the opposite decimal.
    ** Over- Underflows requires TBD. **
    */
    function _calculateValue(uint256 _price, uint256 _amountOfTokenOut, uint256 _decimalOut) internal pure returns (uint256) {
        uint256 prod = _price * _amountOfTokenOut;
        return prod / (10 ** _decimalOut);
    }   


    //////////////////////////////////////////////////////////////////////
    //                              Miscellaneous                       //
    //////////////////////////////////////////////////////////////////////

    function sqrtu (uint256 x) internal pure returns (uint128) {
        unchecked {
          if (x == 0) return 0;
          else {
            uint256 xx = x;
            uint256 r = 1;
            if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
            if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
            if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
            if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
            if (xx >= 0x100) { xx >>= 8; r <<= 4; }
            if (xx >= 0x10) { xx >>= 4; r <<= 2; }
            if (xx >= 0x8) { r <<= 1; }
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1; // Seven iterations should be enough
            uint256 r1 = x / r;
            return uint128 (r < r1 ? r : r1);
          }
        }
      }

    // // function _sqrtP_to_Price(uint160 sqrtPrice) internal view returns(uint256 price){
    // // return (uint(sqrtPrice) * (uint(sqrtPrice)) * (1e8)) >> (96 * 2);
    // // }

    // function __q96(uint128 fR) internal pure returns (uint160 fn) {
    
    //     // Scale `fR` to match the decimals of `token0`
    //     uint256 scaledFR = uint256(fR) * (10 ** 10); // Scale `fR` by 10^10 to match the 18 decimals of `token0`
    
    //     // Calculate square root price
    //     int128 num = uint256(scaledFR).fromUInt();
    //     fn = _sqrP(num);
    // }
    
    // // function _q96(uint128 fR) internal pure returns(uint160 fn){
    // //     int128 num;     // token1
    // //     int128 den;     // token0
    // //     uint256 ppm = 1_000_000;

    // //         num = 1 << 64;
    // //         den = uint256(fR).fromUInt().div(ppm.fromUInt());
    // //         fn = _sqrP(ABDKMath64x64.div(num, den));

    // //         // num = uint256(fR).fromUInt().div(ppm.fromUInt());
    // //         // den = 1 << 64;
    // //         // fn = _sqrP(ABDKMath64x64.div(num, den));
    // // }

    // function _sqrP(int128 price) internal pure returns(uint160){
    //     return
    //         uint160(
    //             int160(
    //                 ABDKMath64x64.sqrt(int128(price)) <<
    //                     (32)
    //             )
    //         );
    // }

    // /// Whales: ///
    // address USDC_m = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    // address DAI_m = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    // address WETH_m = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    // address DAI_Whale_m = 0x517F9dD285e75b599234F7221227339478d0FcC8; // v2 pool maker/dai
    // address WETH_Wahle_m = 0xF04a5cC80B1E94C69B48f5ee68a08CD2F09A7c3E; // 500_000 e18 weth !
    // address UDSC_Whale_m = 0x4B16c5dE96EB2117bBE5fd171E4d203624B014aa;
    // address DAI_USDC_POOL_m = 0x5777d92f208679DB4b9778590Fa3CAB3aC9e2168;

    // /// Layered method: Mainnet:
    // function _mintxSkirk(
    //     address user,
    //     uint256 amount
    // ) internal{
    //     vm.startPrank(DAI_Whale_m);
    //     IERC20(DAI_m).approve(address(m_xSkirk), 2**256 -1);
    //     m_xSkirk.exactSkirkOut(amount);
    //     m_xSkirk.transfer(user, amount);
    //     vm.stopPrank();
    // }

    // function _deadMintApprove(
    //     MockERC20 tkn,
    //     uint256 amount
    // ) internal {
    //     vm.startPrank(address(0xdead));
    //     _mintApprove(tkn, address(this), amount);
    //     vm.stopPrank();
    // }

    // function _deadApprove(
    //     MockERC20 token,
    //     uint256 amount
    // ) internal {
    //     vm.startPrank(address(0xdead));
    //     token.approve(address(this), amount);
    //     vm.stopPrank();
    // }

    event BadRouting(uint256);
    function uniswapV3MintCallback(
        uint256 ,
        uint256 ,
        bytes calldata
    ) public virtual {
        emit BadRouting(123);
        // // No security checks, since this is meant as a test.
        // address token0 = IUniswapV3Pool(msg.sender).token0();
        // address token1 = IUniswapV3Pool(msg.sender).token1();

        // if(token0 == address(xSKIRK) && amount0Owed > 0){            
        //     uint256 daiRequired = xSKIRK.getSkirkForDai(amount0Owed);
        //     _deadMintApprove(dai, daiRequired);
        //     vm.startPrank(address(0xdead));
        //     dai.approve(address(xSKIRK), 2**256-1);
        //     xSKIRK.exactSkirkOut(amount0Owed);
        //     vm.stopPrank();
        // }

        // if(token1 == address(xSKIRK) && amount1Owed > 0){
        //     uint256 daiRequired = xSKIRK.getSkirkForDai(amount1Owed);
        //     _deadMintApprove(dai, daiRequired);
        //     vm.startPrank(address(0xdead));
        //     dai.approve(address(xSKIRK), 2**256-1);
        //     xSKIRK.exactSkirkOut(amount1Owed);
        //     xSKIRK.approve(address(this), 2**256-1);
        //     vm.stopPrank();
        // }

        // if (amount0Owed > 0){
        //     if(token0 != address(xSKIRK)){
        //         _deadMintApprove(MockERC20(token0), amount0Owed);       
        //         IERC20(token0).safeTransferFrom(address(0xdead), msg.sender, amount0Owed);   
        //     } else {
        //         IERC20(token0).safeTransferFrom(address(0xdead), msg.sender, amount0Owed);
        //     }
        // }
        // if (amount1Owed > 0){
        //     if(token1 != address(xSKIRK)){
        //         emit MangoUint256(token1, amount1Owed);
        //         _deadMintApprove(MockERC20(token1), amount1Owed);
        //         IERC20(token1).safeTransferFrom(address(0xdead), msg.sender, amount1Owed);
        //     } else {
        //         IERC20(token1).safeTransferFrom(address(0xdead), msg.sender, amount1Owed);
        //     }
        // }
    }

    // function emitStuff() public {
    //     emit MangoUint256(address(0x99), 123);
    // }

    // event Foo(uint256);
    function uniswapV3SwapCallback(
        int256 ,
        int256 ,
        bytes calldata
    ) public virtual {
        emit BadRouting(123);
    //     uint256 amount0Owed = _amount0Owed > 0 ? SafeCast.toUint256(_amount0Owed) : 0;
    //     uint256 amount1Owed = _amount1Owed > 0 ? SafeCast.toUint256(_amount1Owed) : 0;
    //     // No security checks, since this is meant as a test.
    //     address token0 = IUniswapV3Pool(msg.sender).token0();
    //     address token1 = IUniswapV3Pool(msg.sender).token1();

    //     if(token0 == address(xSKIRK) && amount0Owed > 0){
    //         uint256 daiRequired = xSKIRK.getSkirkForDai(amount0Owed);
    //         _deadMintApprove(dai, daiRequired);
    //         vm.startPrank(address(0xdead));
    //         dai.approve(address(xSKIRK), 2**256-1);
    //         xSKIRK.exactSkirkOut(amount0Owed);
    //         vm.stopPrank();
    //     }
        
    //     if(token1 == address(xSKIRK) && amount1Owed > 0){
    //         uint256 daiRequired = xSKIRK.getSkirkForDai(amount1Owed);
    //         _deadMintApprove(dai, daiRequired);
    //         vm.startPrank(address(0xdead));
    //         dai.approve(address(xSKIRK), 2**256-1);
    //         xSKIRK.exactSkirkOut(amount1Owed);
    //         vm.stopPrank();
    //     }

    //     if (amount0Owed > 0){
    //         if(token0 != address(xSKIRK)){
    //             _deadMintApprove(MockERC20(token0), amount0Owed);
    //             IERC20(token0).safeTransferFrom((address(0xdead)),msg.sender, amount0Owed);
    //         } else {
    //             _deadApprove(MockERC20(address(xSKIRK)), amount0Owed);
    //             IERC20(token0).safeTransferFrom(address(0xdead), msg.sender, amount0Owed);
    //         }
    //     }
    //     if (amount1Owed > 0){
    //         if(token1 != address(xSKIRK)){
    //             emit MangoUint256(token1, amount1Owed);
    //             _deadMintApprove(MockERC20(token1), amount1Owed);
    //             IERC20(token1).safeTransferFrom(address(0xdead), msg.sender, amount1Owed);
    //         } else {
    //             _deadApprove(MockERC20(address(xSKIRK)), amount1Owed);
    //             IERC20(token1).safeTransferFrom(address(0xdead), msg.sender, amount1Owed);
    //         }
    //     }
    }

    //     /*
    // * Shift main price of wbtc/dai. 
    // */
    // function _shiftWbtcSpotPrice(
    //     uint160 targetPrice
    // ) internal {
    //     (uint160 sqrtP,,,,,,) = IUniswapV3Pool(pool_wbtc_dai).slot0();
    //     uint8 dir = targetPrice > sqrtP ? 2 : 1;

    //     IUniswapV3Pool(pool_wbtc_dai).swap(
    //         address(0xdead),
    //         dir == 1 ? true : false,
    //         2**96,  // Overswap by non realistic amount to reach limit
    //         targetPrice,
    //         ""
    //     );
    // }

    // event MangoMango(uint256);
    // function _inverse(uint160 sqrtP, uint256 d0, uint256 d1) internal view returns(uint160 _finalPrice){
    //     uint256 sqrtPrice = uint256(sqrtP);
    //     uint256 base = sqrtPrice * sqrtPrice / (2**192);
    //     if(base == 0){
    //         uint256 factor = q96 / sqrtPrice;
    //         _finalPrice = uint160(q96 * factor);
    //     } else {
    //         if(d0 == d1 && base > 0){
    //             _finalPrice = _getSqrP(q96 / base, 18, 18);
    //         } else if(d0 != d1 && base <= (10**d1)){
    //             if(base == (10**d1)){
    //                 return _getSqrP(base, 18, 18);
    //             }else {
    //                 uint256 _q96 = (q96 * (10**d0));
    //                 uint256 factor = _q96 / sqrtPrice;
    //                 _finalPrice = uint160(_q96 * factor);   // TBD FIX
    //             }
    //         }
    //     }
    //     /*
    //     1 in q96        = 79228162514264337593543950336
    //     1/3000 in q96   = 1418775660712374678828290181
    //     */
    // }
}