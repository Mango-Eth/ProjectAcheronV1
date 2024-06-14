// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Vm} from "forge-std/Vm.sol";
import {Test, console} from "forge-std/Test.sol";

// Interfaces & OZ:
import {INonfungiblePositionManager} from "MangoHat/mangoUtils/Uni-Foundry/interfaces/INonfungiblePositionManager.sol";
import {IUniswapV3Pool} from "MangoHat/mangoUtils/Uni-Foundry/interfaces/IUniswapV3Pool.sol";
import {IUniswapV3Factory} from "MangoHat/mangoUtils/Uni-Foundry/interfaces/IUniswapV3Factory.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

// Math:
import {ABDKMath64x64} from "MangoHat/mangoUtils/Uni-Math/ABDKMath64x64.sol";

// Foundry fork:
import {UniswapV3Factory} from "MangoHat/mangoUtils/Uni-Foundry/UniswapV3Factory.sol";
import {MangoSwapRouter} from "MangoHat/mangoUtils/Uni-Foundry/MangoSwapRouter.sol";
import {UniversalAggregator} from "MangoHat/Aggregators/UniversalAggregator.sol"; 
import {MockERC20} from "MangoHat/mangoUtils/MockERC20.sol";
import {Acheron} from "MangoHat/ProjectAcheron/Acheron/Acheron.sol";
import {xSkirk} from "MangoHat/ProjectAcheron/xSkirk/xSkirk.sol";
import {xSkirkDeployerFoundry} from "MangoHat/ProjectAcheron/xSkirk/xSkirkDeployerFoundry.sol";
import {AcheronDeployer} from "MangoHat/ProjectAcheron/Acheron/AcheronDeployer.sol";
import {DeterministicToken} from "MangoHat/ProjectAcheron/TestnetTokens/DeterministicToken.sol";
import {SkirkMainAggregatorFoundry} from "MangoHat/ProjectAcheron/MainAggregator/SkirkMainAggregatorFoundry.sol";
import {CurveMock} from "MangoHat/ProjectAcheron/Curve/CurveMock.sol";
import {PotionGreen} from "MangoHat/ProjectAcheron/PotionFoundry/PotionGreen.sol";
import {PotionBlue} from "MangoHat/ProjectAcheron/PotionFoundry/PotionBlue.sol";
import {PotionPurple} from "MangoHat/ProjectAcheron/PotionFoundry/PotionPurple.sol";

// MAINNET STUFF:
import {Acheron_Oracle} from "MangoHat/ProjectAcheron/Acheron_Mainnet/Acheron_Oracle.sol";
import {xSkirkDeployerMainnet} from "MangoHat/ProjectAcheron/xSkirk/xSkirkDeployerMainnet.sol";
import {AcheronDeployerMainnet} from "MangoHat/ProjectAcheron/Acheron_Mainnet/AcheronDeployerMainnet.sol";
import {Acheron_Core} from "MangoHat/ProjectAcheron/Acheron_Mainnet/Acheron_Core.sol";
import {xSkirk_Core} from "MangoHat/ProjectAcheron/xSkirk/xSkirk_Core.sol";
import {SkirkMainAggregator} from "MangoHat/ProjectAcheron/MainAggregator/SkirkMainAggregator.sol";
import {Potion_Blue} from "MangoHat/ProjectAcheron/Potion/Potion_Blue.sol";

contract Instances is Test {

    Vm.Wallet public alice;
    Vm.Wallet public bob;
    Vm.Wallet public rob;
    Vm.Wallet public admin;

    UniswapV3Factory UniswapFactory;
    UniswapV3Factory SkirkFactory;

    UniversalAggregator universalAggregator;

    MangoSwapRouter mangoSwapRouter;

    // Deployer:
    AcheronDeployer acheronDeployer;
    xSkirkDeployerFoundry skirkDeployer;
    DeterministicToken tokenDeployer;
    SkirkMainAggregatorFoundry mainAggregator;
    CurveMock crv;

    Acheron acheron;
    xSkirk xSKIRK;
    PotionGreen potionGreen;
    PotionBlue potionBlue;
    PotionPurple potionPurple;

    MockERC20 dai;
    MockERC20 wbtc;
    MockERC20 usdc;
    MockERC20 weth;

    ///// Mainnet stuff: /////////

    // Acheron_Oracle oracle;

    // Skirk & Acheron deployers:
    xSkirkDeployerMainnet m_xSkirkDeployer;
    AcheronDeployerMainnet m_acheronDeployer;
    Acheron_Core m_acheron;
    xSkirk_Core m_xSkirk;
    SkirkMainAggregator prog;

    UniswapV3Factory m_uniswapV3Factory;
    IERC20 m_weth;

    Potion_Blue blue;

}
