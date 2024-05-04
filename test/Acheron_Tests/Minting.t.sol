// SPDX-License-Identifier: Built by Mango
pragma solidity ^0.8.20;

import "../Methods.sol";

contract Minting is Methods {

    /*
    * Initial testing with same price algorithm.
    * Minting + aggregating same sqrtPrice between (wbtc/dai), (wbtc/xSKIRK)
    */
    function testMintWithSamePriceAlgorithm() public {
        // _mintSkirk(100e18, alice.addr);
        // console.log(dai.balanceOf(alice.addr));
        // console.log(xSKIRK.balanceOf(alice.addr));
        // console.log(xSKIRK.getSkirkForDai(100e18));

        // _mintAcheron(bob.addr);
        // _mintSkirk(200e18, bob.addr);
        // vm.startPrank(bob.addr);
        // // uint256 daiAmount = 200e18;
        // // dai.mint(daiAmount);
        // // dai.approve(address(xSKIRK), daiAmount);
        // // uint256 skirkReceived = xSKIRK.exactIn(daiAmount);

        // uint256 skirkToDai = xSKIRK.getSkirkForDai(100e18);
        // uint256 daiToSkirk = xSKIRK.daiToSkirk(111111111111111111111);
        // // console.log(skirkReceived);
        // // console.log(shouldReceive);

        // xSKIRK.approve(address(xSKIRK), 2**256-1);
        // // Burning 100 skirk:
        // xSKIRK.burn(100e18);
        // console.log("After burning", dai.balanceOf(bob.addr));

        // xSKIRK.getBounty(100e18);
        // console.log("After bounty", dai.balanceOf(bob.addr) - 100e18);

        // console.log("bounty amount", xSKIRK.calculateBountyAmount(100e18));
        // console.log("100 skirk to dai", skirkToDai);

        // vm.stopPrank();

        _mintSkirk(200e18, bob.addr);
        vm.startPrank(bob.addr);

        console.log("Should be 0:", dai.balanceOf(bob.addr));
        xSKIRK.approve(address(xSKIRK), 200e18);
        xSKIRK.burn(128218559999996369791);
        uint256 daiOut = dai.balanceOf(bob.addr);
        console.log("USED   :", 128218559999996369791);
        console.log("DAI OUT:", daiOut);
        vm.stopPrank();
    }

    /*
    * Minting Acheron:
    */
    function testMintAcheronWithAggregationAttempt() public {
        _mintAcheron(bob.addr); // Works when wbtc/dai & wbtc/xskirk have the same price.
    }

    /*
    * Minting after price recalibration: (SHOULD FAIL)
    * WORKED!
    */
    function testMintAfterPriceArbitrage() public {

        _balanceSkirkWbtcPool();
        // Checking prices of both pools first:
        (uint160 sqrtP,,,,,,) = IUniswapV3Pool(pool_wbtc_dai).slot0();
        console.log("(WBTC/DAI)", _getPrice(sqrtP, 8, 18));

        (sqrtP,,,,,,) = IUniswapV3Pool(pool_wbtc_xSkirk).slot0();
        console.log("(WBTC/xSKIRK)", _getPrice(sqrtP, 8, 18));

        _mintAcheron(bob.addr);
    }

    /*
    * Fuzzing minting in all price ranges:
    */
    function testMintingAboveRanges() public {

        // (uint160 sqrtP,,,,,,) = IUniswapV3Pool(pool_wbtc_dai).slot0();
        // console.log("old     :", _getPrice(sqrtP, 8, 18));

        // _shiftWbtcSpotPrice(_getSqrP(67000, 8, 18));

        // (sqrtP,,,,,,) = IUniswapV3Pool(pool_wbtc_dai).slot0();
        // console.log("updated :", _getPrice(sqrtP, 8, 18));

        uint256 startingPrice = 64_000;
        for(uint256 i; i < 1210; i++){
            uint256 priceIndex = startingPrice + (100 * i);
            uint160 sqrtPrice = _getSqrP(priceIndex, 8, 18);
            _shiftWbtcSpotPrice(sqrtPrice);
            _balanceSkirkWbtcPool();
            _mintAcheron(bob.addr);
            console.log("Worked at price:", priceIndex, IUniswapV3Pool(pool_wbtc_xSkirk).liquidity());        // WORKED WTF
        }
    }

    /*
    * The above test, but reducint the price every time.
    */
    function testMintingAcheronInAllPriceRangesLowerPrices() public {
        uint256 startingPrice = 64_000;
        uint256 bankBalance;
        for(uint256 i; i < 525; i++){
            uint256 priceIndex = startingPrice - (100 * i);
            uint160 sqrtPrice = _getSqrP(priceIndex, 8, 18);
            _shiftWbtcSpotPrice(sqrtPrice);
            _balanceSkirkWbtcPool();
            _mintAcheron(bob.addr);
            console.log("Worked at price:", priceIndex, "L:", IUniswapV3Pool(pool_wbtc_xSkirk).liquidity());        // WORKED WTF
            require(bankBalance + 99e18 < xSKIRK.balanceOf(address(0x7777777777)));
            bankBalance = xSKIRK.balanceOf(address(0x7777777777));
        }
    }

    /*
    * Single mint tests at specific price ranges:
    */
    function testMintAtSpecificSpotPrice() public {
        uint256 spotPrice = 11800;
        uint160 sqrtPrice = _getSqrP(spotPrice, 8, 18);
        _shiftWbtcSpotPrice(sqrtPrice);
            _balanceSkirkWbtcPool();
            _mintAcheron(bob.addr);
    }

    function testReadRealQuick() public view{
        console.log(pool_wbtc_dai);
    }





}