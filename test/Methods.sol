// SPDX-License-Identifier: Built by Mango
pragma solidity ^0.8.20;

import {ISwapRouter} from "MangoHat/mangoUtils/Uni-Foundry/interfaces/ISwapRouter.sol";
import {LiquidityMath} from "MangoHat/mangoUtils/Uni-Math/LiquidityMath.sol";
import {TickMath} from "MangoHat/mangoUtils/Uni-Math/TickMath.sol";
import {FullMath} from "MangoHat/mangoUtils/Uni-Math/FullMath.sol";

import "./Setup.sol";

contract Methods is Setup {

    using TickMath for int24;
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using ABDKMath64x64 for uint256;
    using ABDKMath64x64 for int128;

    function setUp() public override virtual {
        super.setUp();
        /*
        * WBTC/DAI pool, depositing 4 wbtc + 210k DAI in 20k-300k range & 2 wbtc + x DAI in 10k - 250k range.
        * WBTC/xSKIRK pool 1e8, 64k.
        * WBTC/xSKIRK pool, will gradually get deposits.
        */  
        _depositLiquidity(
            pool_wbtc_dai,
            4e8,
            64_000e18 * 4,
            admin.addr,
            329280,         // ~20k
            356340          // ~300k
        );
        _depositLiquidity(
            pool_wbtc_dai,
            4e8,
            64_000e18 * 4,
            admin.addr,
            322320,         // ~10k
            354540          // ~250k
        );

        (uint160 sqrtP,,,,,,) = IUniswapV3Pool(pool_wbtc_xSkirk).slot0();
        int24 tl = 322320;
        int24 tu = 354540;
        uint128 liquidity = LiquidityMath.getLiquidityForAmounts(sqrtP, tl.getSqrtRatioAtTick(), tu.getSqrtRatioAtTick(), 1e3, 2e18);
        IUniswapV3Pool(pool_wbtc_xSkirk).mint(
            alice.addr,
            322320,
            354540,
            liquidity,
            ""
        );

        vm.startPrank(admin.addr);
        wbtc.transfer(address(0xdead), wbtc.balanceOf(admin.addr));
        dai.transfer(address(0xdead), dai.balanceOf(admin.addr));
        vm.stopPrank();
    }
    
    //////////////////////////////////////////////////////////////////////
    //                        CORE - kinda                              //
    //////////////////////////////////////////////////////////////////////

    /*
    * Mints an acheron
    */
    function _mintAcheron(
        address to
    ) internal returns(uint256 id){
        uint256 skirkRequired = acheron.acheronPrice();
        _mintSkirk(skirkRequired, to);
        vm.startPrank(to);
        xSKIRK.approve(address(acheron), skirkRequired);

        id = acheron.mint();
        vm.stopPrank();
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

    /*
    * Shift main price of wbtc/dai. 
    */
    function _shiftWbtcSpotPrice(
        uint160 targetPrice
    ) internal {
        (uint160 sqrtP,,,,,,) = IUniswapV3Pool(pool_wbtc_dai).slot0();
        uint8 dir = targetPrice > sqrtP ? 2 : 1;

        IUniswapV3Pool(pool_wbtc_dai).swap(
            address(0xdead),
            dir == 1 ? true : false,
            2**96,  // Overswap by non realistic amount to reach limit
            targetPrice,
            ""
        );
    }

    /*
    * Arbitrage function for xSKIRK/WBTC pool in respect to WBTC/DAI price.
    */
    function _balanceSkirkWbtcPool() internal {
        uint248 target;
        uint8 dir;
        (target, dir) = __getAmountsToArb();
        if(dir != 3){
        uint160 limit = _getSqrP(uint256(target) / (10 ** 18), 8, 18);

        IUniswapV3Pool(pool_wbtc_xSkirk).swap(
            address(0xdead),
            dir == 1 ? true : false,
            2**96,  // Overswap by non realistic amount to reach limit
            limit,
            ""
        );
        }
    }

    function __getAmountsToArb() internal view returns(uint248, uint8){
        (uint160 sqrtP,,,,,,) = IUniswapV3Pool(pool_wbtc_dai).slot0();
        uint256 wbtcPriceInBase18 = _getPrice(sqrtP, 8, 18);
        (sqrtP,,,,,,) = IUniswapV3Pool(pool_wbtc_xSkirk).slot0();
        uint256 syntheticWbtcPriceInbase18 = _getPrice(sqrtP, 8, 18);
        uint256 targetRange = wbtcPriceInBase18 - (wbtcPriceInBase18 / 10);
        uint256 limit = targetRange / 100;  // allowing 1% discrepancy
        if(targetRange + limit > syntheticWbtcPriceInbase18 && targetRange - limit < syntheticWbtcPriceInbase18) {
            return(0, 3);
        } else {
            // 1: Meaning (wbtc/skirk) pool needs to reduce its price, 2: ... Increase it
            uint8 dir = targetRange < syntheticWbtcPriceInbase18 ? 1 : 2;
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

    /*
    * Swaps using exactOutput()
    * Does not need prior approval, nor having enough balance.
    */
    function _swapForSpecificTokenOut(
        address _pool,
        address tokenExpectedOut,
        uint256 exactAmountOut,
        address caller
    ) internal returns(uint256){
        vm.startPrank(caller);

        uint8 b;
        address tokenIn;
        address tokenOut;
        uint256 amountOut;
        address user;
        uint256 amountSpent;
        if(IUniswapV3Pool(_pool).token0() == tokenExpectedOut) b = 1;
        (tokenIn, tokenOut, amountOut, user) = b == 1 ? (IUniswapV3Pool(_pool).token1(), tokenExpectedOut, exactAmountOut, caller) : (IUniswapV3Pool(_pool).token0(), tokenExpectedOut, exactAmountOut, caller);

        // Slippage protection pending.
        // Get SqrtP, bool of token being swapped, ratio/1 or 1/ratio depending on direction.
        // exactAmountOut * decimal / sqrtP of opposite token, then add 4%.

        (uint160 sqrtP,,,,,,) = IUniswapV3Pool(_pool).slot0();
        uint256 decimal0;
        uint256 decimal1;

        {
        address pool = _pool;
        (decimal0, decimal1) = b == 1 ? (MockERC20(tokenOut).decimals(), MockERC20(tokenIn).decimals()) : (MockERC20(tokenIn).decimals(), MockERC20(tokenOut).decimals());

        // TokenIn is t0, therefore the price would be in terms of t0, using sqrtP directly:
        uint256 valueInOppositeToken;
        if(b == 1){
            // Meaning wbtc in, yields 64k e18. Therefore 1 t0 = sqrP.
            uint256 priceInBaseDeciaml1 = _getPrice(sqrtP, decimal0, decimal1);
            valueInOppositeToken = _calculateValue(priceInBaseDeciaml1, amountOut, decimal0);
            emit Amount(priceInBaseDeciaml1);
            emit Amount(valueInOppositeToken);
        } else {
            // Meaning dai in, yields 1/64k e8. Therefore 1 t1 = 1/sqrP.
            uint256 priceInBaseDeciaml1 = _getPrice(_invertSqrtP(sqrtP, decimal0, decimal1), decimal1, decimal0);
            valueInOppositeToken = _calculateAmount(priceInBaseDeciaml1, amountOut, decimal0);
        }
        
        uint256 valueWithSplippageProtection = valueInOppositeToken + (valueInOppositeToken / 10);
        _mintApprove(MockERC20(tokenIn), address(mangoSwapRouter), valueWithSplippageProtection);
        // MockERC20(tokenIn).mint(valueWithSplippageProtection);
        // MockERC20(tokenIn).approve(address(mangoSwapRouter), valueWithSplippageProtection);
        
        amountSpent = mangoSwapRouter.exactOutputSingle(ISwapRouter.ExactOutputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: IUniswapV3Pool(pool).fee(),
            recipient: user,
            deadline: block.timestamp,
            amountOut: amountOut,
            amountInMaximum: valueWithSplippageProtection,
            sqrtPriceLimitX96: 0
        }));
        _burn(MockERC20(tokenIn), valueWithSplippageProtection - amountSpent);
        vm.stopPrank();
        return amountSpent;
        }
    }




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

    /*
    * Returns 1 dividey by the given q96 exchange rate.
    * Wont return a uint256, since decimal points cant be represented there.
    * Returns the inverse ratio in fixed point q96.
    */
    function _invertSqrtP(uint160 sqrtP, uint256 dec0, uint256 dec1) internal pure returns(uint160 inverseSqrtP){
        // We get the sqrtPrice target, without any decimals:
        uint256 rawPrice = _getPrice(sqrtP, dec0, dec1) / (10 ** 18);

        if(dec0 != dec1){
        
        rawPrice = dec1 > dec0 ? rawPrice * (10 ** (dec1 - dec0)) : rawPrice * (10 ** (dec0 - dec1));

        int128 num = 1 << 64;
        int128 den = rawPrice.fromUInt();
        inverseSqrtP = _sqrP(num.div(den));
        } else {
        int128 num = 1 << 64;
        int128 den = rawPrice.fromUInt();
        inverseSqrtP = _sqrP(num.div(den));
        }
    }
    

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

    // function _sqrtP_to_Price(uint160 sqrtPrice) internal view returns(uint256 price){
    // return (uint(sqrtPrice) * (uint(sqrtPrice)) * (1e8)) >> (96 * 2);
    // }

    function _q96(uint128 fR) internal pure returns (uint160 fn) {
    
        // Scale `fR` to match the decimals of `token0`
        uint256 scaledFR = uint256(fR) * (10 ** 10); // Scale `fR` by 10^10 to match the 18 decimals of `token0`
    
        // Calculate square root price
        int128 num = uint256(scaledFR).fromUInt();
        fn = _sqrP(num);
    }
    
    // function _q96(uint128 fR) internal pure returns(uint160 fn){
    //     int128 num;     // token1
    //     int128 den;     // token0
    //     uint256 ppm = 1_000_000;

    //         num = 1 << 64;
    //         den = uint256(fR).fromUInt().div(ppm.fromUInt());
    //         fn = _sqrP(ABDKMath64x64.div(num, den));

    //         // num = uint256(fR).fromUInt().div(ppm.fromUInt());
    //         // den = 1 << 64;
    //         // fn = _sqrP(ABDKMath64x64.div(num, den));
    // }

    function _sqrP(int128 price) internal pure returns(uint160){
        return
            uint160(
                int160(
                    ABDKMath64x64.sqrt(int128(price)) <<
                        (32)
                )
            );
    }

    function _deadMintApprove(
        MockERC20 tkn,
        uint256 amount
    ) internal {
        vm.startPrank(address(0xdead));
        _mintApprove(tkn, address(this), amount);
        vm.stopPrank();
    }

    event MangoUint256(address, uint256);
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata
    ) public {
        // No security checks, since this is meant as a test.
        address token0 = IUniswapV3Pool(msg.sender).token0();
        address token1 = IUniswapV3Pool(msg.sender).token1();

        if(token0 == address(xSKIRK) && amount0Owed > 0){            
            uint256 daiRequired = xSKIRK.getSkirkForDai(amount0Owed);
            _deadMintApprove(dai, daiRequired);
            vm.startPrank(address(0xdead));
            dai.approve(address(xSKIRK), 2**256-1);
            xSKIRK.exactSkirkOut(amount0Owed);
            vm.stopPrank();
        }

        if(token1 == address(xSKIRK) && amount1Owed > 0){
            uint256 daiRequired = xSKIRK.getSkirkForDai(amount1Owed);
            _deadMintApprove(dai, daiRequired);
            vm.startPrank(address(0xdead));
            dai.approve(address(xSKIRK), 2**256-1);
            xSKIRK.exactSkirkOut(amount1Owed);
            xSKIRK.approve(address(this), 2**256-1);
            vm.stopPrank();
        }

        if (amount0Owed > 0){
            if(token0 != address(xSKIRK)){
                _deadMintApprove(MockERC20(token0), amount0Owed);       
                IERC20(token0).safeTransferFrom(address(0xdead), msg.sender, amount0Owed);   
            } else {
                IERC20(token0).safeTransferFrom(address(0xdead), msg.sender, amount0Owed);
            }
        }
        if (amount1Owed > 0){
            if(token1 != address(xSKIRK)){
                emit MangoUint256(token1, amount1Owed);
                _deadMintApprove(MockERC20(token1), amount1Owed);
                IERC20(token1).safeTransferFrom(address(0xdead), msg.sender, amount1Owed);
            } else {
                IERC20(token1).safeTransferFrom(address(0xdead), msg.sender, amount1Owed);
            }
        }
    }

    function emitStuff() public {
        emit MangoUint256(address(0x99), 123);
    }

    function uniswapV3SwapCallback(
        int256 _amount0Owed,
        int256 _amount1Owed,
        bytes calldata
    ) public {
        uint256 amount0Owed = _amount0Owed > 0 ? SafeCast.toUint256(_amount0Owed) : 0;
        uint256 amount1Owed = _amount1Owed > 0 ? SafeCast.toUint256(_amount1Owed) : 0;
        // No security checks, since this is meant as a test.
        address token0 = IUniswapV3Pool(msg.sender).token0();
        address token1 = IUniswapV3Pool(msg.sender).token1();

        if(token0 == address(xSKIRK) && amount0Owed > 0){
            uint256 daiRequired = xSKIRK.getSkirkForDai(amount0Owed);
            _deadMintApprove(dai, daiRequired);
            vm.startPrank(address(0xdead));
            dai.approve(address(xSKIRK), 2**256-1);
            xSKIRK.exactSkirkOut(amount0Owed);
            vm.stopPrank();
        }

        if(token1 == address(xSKIRK) && amount1Owed > 0){
            uint256 daiRequired = xSKIRK.getSkirkForDai(amount1Owed);
            _deadMintApprove(dai, daiRequired);
            vm.startPrank(address(0xdead));
            dai.approve(address(xSKIRK), 2**256-1);
            xSKIRK.exactSkirkOut(amount1Owed);
            vm.stopPrank();
        }

        if (amount0Owed > 0){
            if(token0 != address(xSKIRK)){
                _deadMintApprove(MockERC20(token0), amount0Owed);
                IERC20(token0).safeTransferFrom((address(0xdead)),msg.sender, amount0Owed);
            } else {
                IERC20(token0).safeTransferFrom(address(0xdead), msg.sender, amount0Owed);
            }
        }
        if (amount1Owed > 0){
            if(token1 != address(xSKIRK)){
                emit MangoUint256(token1, amount1Owed);
                _deadMintApprove(MockERC20(token1), amount1Owed);
                IERC20(token1).safeTransferFrom(address(0xdead), msg.sender, amount1Owed);
            } else {
                IERC20(token1).safeTransferFrom(address(0xdead), msg.sender, amount1Owed);
            }
        }
    }
}