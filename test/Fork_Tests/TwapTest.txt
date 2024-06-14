// SPDX-License-Identifier: Built by Mango
pragma solidity ^0.8.20;

import {FullMath} from "MangoHat/mangoUtils/Uni-Math/FullMath.sol";
import {TickMath} from "MangoHat/mangoUtils/Uni-Math/TickMath.sol";
import {IUniswapV3Pool} from "MangoHat/mangoUtils/Uni-Foundry/interfaces/IUniswapV3Pool.sol";

import "../Methods.sol";

contract TwapTest is Methods {

    using TickMath for int24;
    using FullMath for uint256;

    /*
    Read Twap From WBTC/USDC
    forge test --fork-url=https://1rpc.io/eth --match-test testReadWBTC_USDC_TWAP -vvv
    */
    function testReadWBTC_USDC_TWAP() public view {

        // uint8 RESOLUTION = 96;
        // uint256 Q96 = 0x1000000000000000000000000;

        // address pool = 0x99ac8cA7087fA4A2A1FB6357269965A2014ABc35;

        // uint256 twapInterval = 1800;

        // uint32[] memory secondsAgo = new uint32[](2);
		// secondsAgo[0] = uint32(twapInterval); // from (before)
		// secondsAgo[1] = 0;

        // (int56[] memory tickCumulatives, ) = IUniswapV3Pool(pool).observe(secondsAgo);

		// int24 tick = int24((tickCumulatives[1] - tickCumulatives[0]) / int56(uint56(twapInterval)));
		// uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick( tick );
		// // uint256 p = FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, Q96 );
        // uint256 dec = 8;
        // uint256 numerator1 =uint256(sqrtPriceX96) *uint256(sqrtPriceX96);  
        // uint256 numerator2 =10**dec; 
        // uint256 price = FullMath.mulDiv(numerator1, numerator2, 1 << 192);
        // uint256 adjustmentFactor = 10 ** 12;
        // uint256 result = price * adjustmentFactor;
        // console.log(result);
        
        console.log(_getWbtcPrice());
    }

    address internal immutable TWAP_POOL = 0x99ac8cA7087fA4A2A1FB6357269965A2014ABc35;

    function _getWbtcPrice() internal view returns(uint256){
        uint256 maxTime = 1800;
        uint32[] memory time = new uint32[](2);
        time[0] = uint32(maxTime);
        time[1] = 0;
        (int56[] memory ticks,) = IUniswapV3Pool(TWAP_POOL).observe(time);
        int24 spotTick = int24((ticks[1] - ticks[0]) / int56(uint56(maxTime)));
        uint160 sqrtP = spotTick.getSqrtRatioAtTick();
        uint256 factor = uint256(sqrtP) * uint256(sqrtP);
        // reverting root,  wbtcDecimal, q96
        return (factor.mulDiv(10**8, 1 << 192)) * 10 **12;
    }




}