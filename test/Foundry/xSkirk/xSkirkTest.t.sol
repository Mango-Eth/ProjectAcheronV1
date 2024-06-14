// SPDX-License-Identifier: Built by Mango
pragma solidity ^0.8.20;

import "../Methods.sol";

contract xSkirkTest is Methods {

    uint256 surplus;

    function setUp() public override {
        super.setUp();
        _mintAcheron(alice.addr);
        surplus = xSKIRK.getTotalDebt();
        vm.startPrank(alice.addr);
        if(xSKIRK.balanceOf(alice.addr) > 0){
            xSKIRK.transfer(address(0x98928392), xSKIRK.balanceOf(alice.addr));
        }
        vm.stopPrank();
    }
    
    /*
    * Fuzzing
    * Invariant testing
    */

    /*
    * Invariant functions checks
    */
    function testSkirkInvariantsBasic(uint256 val) public {
        uint256 amount = val % 1e35;
        if(amount < 1e14){
            amount = amount + 1e14;
        }
    
        uint256 skirkInvOut = xSKIRK.daiToSkirk(amount);
        uint256 daiInvOut = xSKIRK.previewBounty(amount);

        dai.mint(amount);
        dai.approve(address(xSKIRK), amount);
        uint256 result = xSKIRK.exactIn(amount);
        require(result == skirkInvOut, "SK0");

        _mintSkirk(amount, alice.addr);
        _mintAcheron(alice.addr);

        vm.startPrank(alice.addr);
        uint256 b = dai.balanceOf(alice.addr);
        xSKIRK.approve(address(xSKIRK), amount);
        xSKIRK.getBounty(amount, 777);
        uint256 aftr = dai.balanceOf(alice.addr);
        uint256 amountOut = aftr - b;
        // console.log("Brn:", amountOut);
        // console.log("prv:", daiInvOut);
        require(daiInvOut == amountOut, "ABC");
        vm.stopPrank();
    }

    /*
    * Fuzz, scrambel calls test
    */
    function testFuzzingMultipleCalls() public {
        for(uint256 i; i< 100_000; i++){
            uint256 salt = uint256(bytes32(keccak256(abi.encodePacked(i + 464646))));
            uint256 selector = salt % 4;
            uint256 rng = salt % 1e35;

            if(selector == 0){
                __exactSkirkOut(rng);
                require(__invariant(), "a1");
            } else if(selector == 1){
                __exactIn(rng);
                require(__invariant(), "a2");
            } else if(selector == 2){
                __getBounty(rng);
                require(__invariant(), "a3");
            } else if(selector == 3){
                __burn(rng);
                require(__invariant(), "a4");
            }
        }
    }

    /*
    * D-Bunking burn(0)
    */
    function testBurnZeroDebunk() public {

        __exactSkirkOut(217382913782923);
        vm.startPrank(alice.addr);
        xSKIRK.approve(address(xSKIRK), 2**256-1);
        vm.expectRevert();
        xSKIRK.burn(1);
        vm.stopPrank();
        bool n = __invariant();
        console.log(n);
    }




    ////////////////////////////////////////////////////////////////////////////
    //                                      methods:    
    ////////////////////////////////////////////////////////////////////////////

    //                      xSkirk                          daiUsed.
    function __exactSkirkOut(uint256 rng) internal returns(uint256){
        vm.startPrank(alice.addr);
        uint256 amountNeeded = xSKIRK.getSkirkForDai(rng);
        dai.mint(amountNeeded);
        dai.approve(address(xSKIRK), amountNeeded);
        uint256 x = xSKIRK.exactSkirkOut(rng);
        vm.stopPrank();
        return x;
    }

    //                  DAI                         xSkirk
    function __exactIn(uint256 rng) internal returns(uint256){
        vm.startPrank(alice.addr);
        dai.mint(rng);
        dai.approve(address(xSKIRK), rng);
        uint256 r = xSKIRK.exactIn(rng);
        vm.stopPrank();
        return r;
    }  

    //                      xSkirk
    function __getBounty(uint256 rng) internal returns(uint256){
        uint256 aliceSkirkBalance = xSKIRK.balanceOf(alice.addr);
        if(aliceSkirkBalance < rng){
            uint256 diff = rng - aliceSkirkBalance;
            uint256 daiNeeded = xSKIRK.getSkirkForDai(diff);
            vm.startPrank(alice.addr);
            dai.mint(daiNeeded);
            dai.approve(address(xSKIRK), daiNeeded);
            xSKIRK.exactSkirkOut(diff);
            vm.stopPrank();
        }
        vm.startPrank(alice.addr);
        uint256 before = dai.balanceOf(alice.addr);
        xSKIRK.getBounty(rng, 777);
        vm.roll(block.number + 7001);
        uint256 aftr = dai.balanceOf(alice.addr);
        return aftr - before;
    }

    function __burn(uint256 rng) internal returns(uint256){
        uint256 aliceSkirkBalance = xSKIRK.balanceOf(alice.addr);
        if(aliceSkirkBalance < rng){
            uint256 diff = rng - aliceSkirkBalance;
            uint256 daiNeeded = xSKIRK.getSkirkForDai(diff);
            vm.startPrank(alice.addr);
            dai.mint(daiNeeded);
            dai.approve(address(xSKIRK), daiNeeded);
            xSKIRK.exactSkirkOut(diff);
            vm.stopPrank();
        }
        vm.startPrank(alice.addr);
        uint256 before = dai.balanceOf(alice.addr);
        xSKIRK.burn(rng);
        uint256 aftr = dai.balanceOf(alice.addr);
        return aftr - before;
    }

    function __invariant() internal view returns(bool){
        uint256 aliceSkirkBalance = xSKIRK.balanceOf(alice.addr);
        uint256 totalAmount = xSKIRK.getTotalDebt();
        return ((totalAmount - surplus) == aliceSkirkBalance);
    }
}