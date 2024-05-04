// SPDX-License-Identifier: Built by Mango
pragma solidity ^0.8.20;

import "./Instances.sol";

contract Setup is Instances {

    address internal pool_dai_usdc;
    address internal pool_wbtc_dai;
    address internal pool_wbtc_xSkirk;

    function setUp() public virtual {

        admin = vm.createWallet("admin");
        alice = vm.createWallet("alice");
        bob = vm.createWallet("bob");
        rob = vm.createWallet("rob");

        // ERC20 Tokens:
        dai = new MockERC20("DAI", "DAI", 18);
        wbtc =  new MockERC20("WBTC", "WBTC", 8);
        usdc = new MockERC20("USDC", "USDC", 6);
        while(address(dai) > address(usdc) && address(dai) > address(wbtc)){
            usdc = new MockERC20("USDC", "USDC", 6);
            dai = new MockERC20("DAI", "DAI", 18);
        }

        vm.startPrank(admin.addr);
        factory = new UniswapV3Factory();
        factory.enableFeeAmount(100, 1);
        pool_dai_usdc = factory.createPool(
            address(dai),
            address(usdc),
            100
        );

        acheronDeployer = new AcheronDeployer();
        string memory skirkSalt = "By the wings of eternity and the breath of ages, To all creation, heed my plea";
        string memory acheronSalt = "Still the sands of time and grant me passage, Through the currents of eternity.";

        address xSkirkAddress = acheronDeployer.address3(skirkSalt);
        address AcheronAddress = acheronDeployer.address3(acheronSalt);

        xSKIRK = xSkirk(xSkirkAddress);
        acheron = Acheron(AcheronAddress);

        // console.log("WBTC  :", address(wbtc));
        // console.log("xSKIRK: ", xSkirkAddress);
        vm.stopPrank();

        // WBTC/DAI pool:
        pool_wbtc_dai = factory.createPool(address(wbtc), address(dai), 3000);
        IUniswapV3Pool(factory.getPool(address(wbtc), address(dai), 3000)).initialize(2004331587000383584631039759405285376); // 64k

        // IUniswapV3Pool(factory.getPool(address(wbtc), address(dai), 3000)).initialize(1892823712081295383306828407087962153); // 57k


        // WBTC/xSKIRK pool:
        pool_wbtc_xSkirk = factory.createPool(address(wbtc), address(xSkirkAddress), 3000);    
        IUniswapV3Pool(factory.getPool(address(wbtc), address(xSkirkAddress), 3000)).initialize(2004331587000383584631039759405285376); // 64k
        // Starting at 64k is a intentional mistake, to incentivice corrections on its way :)

        universalAggregator = new UniversalAggregator(address(factory));
        mangoSwapRouter = new MangoSwapRouter(address(factory), address(0x88));

        vm.startPrank(admin.addr);
        acheronDeployer.deploy(
            skirkSalt,
            acheronSalt,
            AcheronDeployer.Params({
            core_pool: factory.getPool(address(wbtc), address(xSkirkAddress), 3000),    // WBTC/xSKIRK
            factory: address(factory),
            wbtc: address(wbtc),
            dai: address(dai),
            skirk_aggregator: address(0x7777777777)
        }));
        vm.stopPrank();

        acheron.initialize();

        /*
        Deployed contracts thus far:
        { DAI, USDC, WBTC, Uni-Factory, Uni-Pool(WBTC/DAI), Uni-Pool(WBTC/xSKIRK), 
            universalAggregator, mangoSwapRouter, acheronDeployer, xSkirk, Acheron, }
        */
    }

    function testFoo() public {

    }

    
}