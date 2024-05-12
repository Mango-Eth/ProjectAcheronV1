// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Vm} from "forge-std/Vm.sol";
import {Test, console} from "forge-std/Test.sol";

// Uni v3 interfaces:
import {INonfungiblePositionManager} from "MangoHat/mangoUtils/Uni-Foundry/interfaces/INonfungiblePositionManager.sol";
import {IUniswapV3Pool} from "MangoHat/mangoUtils/Uni-Foundry/interfaces/IUniswapV3Pool.sol";
import {IUniswapV3Factory} from "MangoHat/mangoUtils/Uni-Foundry/interfaces/IUniswapV3Factory.sol";

import {UniswapV3Factory} from "MangoHat/mangoUtils/Uni-Foundry/UniswapV3Factory.sol";

import {MangoSwapRouter} from "MangoHat/mangoUtils/Uni-Foundry/MangoSwapRouter.sol";
import {UniversalAggregator} from "MangoHat/Aggregators/UniversalAggregator.sol"; 
import {MockERC20} from "MangoHat/mangoUtils/MockERC20.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

// DAPPS
import {Acheron} from "MangoHat/ProjectAcheron/Acheron/Acheron.sol";
import {xSkirk} from "MangoHat/ProjectAcheron/xSkirk/xSkirk.sol";

// Math
import {ABDKMath64x64} from "MangoHat/mangoUtils/Uni-Math/ABDKMath64x64.sol";

// Deployers:
import {AcheronDeployer} from "MangoHat/ProjectAcheron/Acheron/AcheronDeployer.sol";

contract Instances is Test {

    Vm.Wallet public alice;
    Vm.Wallet public bob;
    Vm.Wallet public rob;
    Vm.Wallet public admin;

    // INonfungiblePositionManager positionManager;
    // IUniswapV3Pool pool1;
    // IUniswapV3Pool pool2;
    // IUniswapV3Pool pool3;
    // IUniswapV3Factory factory;

    UniswapV3Factory UniswapFactory;
    UniswapV3Factory SkirkFactory;

    UniversalAggregator universalAggregator;

    MangoSwapRouter mangoSwapRouter;

    // IERC20 dai;
    // IERC20 usdc;

    // First gen testing:
    Acheron acheron;

    xSkirk xSKIRK;

    // Deployer:
    AcheronDeployer acheronDeployer;

    MockERC20 dai;
    MockERC20 wbtc;
    MockERC20 usdc;
    MockERC20 weth;
}
