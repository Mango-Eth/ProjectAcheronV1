// SPDX-License-Identifier: Built by Mango
pragma solidity ^0.8.20;

import "./Instances.sol";

contract Setup is Instances {

    address internal pool_dai_usdc;
    address internal pool_weth_xSkirk;
    address internal pool_dai_weth;
    address internal pool_wbtc_dai;
    uint256 internal q96 = 79228162514264337593543950336;

    function setUp() public virtual {

        admin = vm.createWallet("admin");
        alice = vm.createWallet("alice");
        bob = vm.createWallet("bob");
        rob = vm.createWallet("rob");

        // ERC20 Tokens:
        dai = new MockERC20("DAI", "DAI", 18);
        wbtc =  new MockERC20("WBTC", "WBTC", 8);
        usdc = new MockERC20("USDC", "USDC", 6);
        weth = new MockERC20("WETH", "WETH", 18);
        while(address(dai) > address(usdc) && address(dai) < address(weth)){
            usdc = new MockERC20("USDC", "USDC", 6);
            dai = new MockERC20("DAI", "DAI", 18);
        }

        vm.startPrank(admin.addr);
        UniswapFactory = new UniswapV3Factory();
        UniswapFactory.enableFeeAmount(100, 1);

        // Creating dai/usdc pool:
        pool_dai_usdc = UniswapFactory.createPool(
            address(dai),
            address(usdc),
            100
        );// 79228268913569923476614
        IUniswapV3Pool(UniswapFactory.getPool(address(dai), address(usdc), 100)).initialize(79228268913569923476614); // 1$

        // Creating weth/dai pool:
        pool_dai_weth = UniswapFactory.createPool(
            address(dai),
            address(weth),
            500
        );  // 1427447747021118165691127445
        IUniswapV3Pool(UniswapFactory.getPool(address(dai), address(weth), 500)).initialize(1427447747021118165691127445); //  1/3100

        acheronDeployer = new AcheronDeployer();
        string memory skirkSalt = "By the wings of eternity and the breath of ages, To all creation, heed my plea";
        string memory acheronSalt = "Still the sands of time and grant me passage, Through the currents of eternity.";

        address xSkirkAddress = acheronDeployer.address3(skirkSalt);
        address AcheronAddress = acheronDeployer.address3(acheronSalt);

        xSKIRK = xSkirk(xSkirkAddress);
        acheron = Acheron(AcheronAddress);

        // Creating the SkirkSwapFactory contract, deploying & initalizing the pool.
        SkirkFactory = new UniswapV3Factory();
        SkirkFactory.enableFeeAmount(100, 1);
        pool_weth_xSkirk = SkirkFactory.createPool(
            address(weth),
            address(xSkirkAddress),
            500
        );
        vm.stopPrank();

        IUniswapV3Pool(SkirkFactory.getPool(address(weth), address(xSkirkAddress), 500)).initialize(4411237397794263893240602165248); // 3100/1

        universalAggregator = new UniversalAggregator(address(UniswapFactory));
        mangoSwapRouter = new MangoSwapRouter(address(UniswapFactory), address(0x88));

        vm.startPrank(admin.addr);
        acheronDeployer.deploy(
            skirkSalt,
            acheronSalt,
            AcheronDeployer.Params({
                DAI_WETH_POOL: pool_dai_weth,
                WETH_SKIRK_POOL: pool_weth_xSkirk,
                dai: address(dai),
                weth: address(weth),
                SkirkFactory: address(SkirkFactory),
                UniFactory: address(UniswapFactory),
                SkirkAggregator: address(0xaaaaaaa)
        }));
        vm.stopPrank();

        acheron.initialize();

        /*
        Deployed contracts thus far:
        { DAI, USDC, WBTC, Uni-Factory, Uni-Pool(dai/usdc), Uni-Pool(dai/weth), Skirk-Pool(weth/xSkirk), 
            SkirkSwapFactory, UniswapFactory, universalAggregator, mangoSwapRouter, acheronDeployer, xSkirk, Acheron, }
        */
    }

    function testFoo() public {

    }

    
}