// SPDX-License-Identifier: Built by Mango
pragma solidity ^0.8.20;

import "../Instances.sol";

contract Setup is Instances {

    address internal pool_dai_usdc;
    address internal pool_weth_xSkirk;
    address internal pool_dai_weth;
    address internal pool_dai_weth_3000;
    address internal pool_wbtc_dai;
    uint256 internal q96 = 79228162514264337593543950336;

    // Mainnet instances:
    address internal pool_weth_xSkirk_mainnet;

    function setUp() public virtual {

        admin = vm.createWallet("admin");
        alice = vm.createWallet("alice");
        bob = vm.createWallet("bob");
        rob = vm.createWallet("rob");

        tokenDeployer = new DeterministicToken();
        (string memory str0, string memory str1, string memory str2) = _sortAddresses(tokenDeployer.address3("0"),tokenDeployer.address3("1"),tokenDeployer.address3("2"));

        tokenDeployer.deploy(str0, str1, str2);

        dai = MockERC20(tokenDeployer.address3(str0));
        usdc = MockERC20(tokenDeployer.address3(str1));
        weth = MockERC20(tokenDeployer.address3(str2));

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

        // Creating weth/dai pool:
        pool_dai_weth_3000 = UniswapFactory.createPool(
            address(dai),
            address(weth),
            3000
        );  // 1427447747021118165691127445
        IUniswapV3Pool(UniswapFactory.getPool(address(dai), address(weth), 3000)).initialize(1427447747021118165691127445); //  1/3100

        vm.startPrank(admin.addr);
        acheronDeployer = new AcheronDeployer();
        skirkDeployer = new xSkirkDeployerFoundry();
        vm.stopPrank();

        bytes32 skirkSalt;

        for(uint i; i < 100; i++){
            bytes32 salt = keccak256(abi.encodePacked(i));
            address r = skirkDeployer.address3(salt);
            if(r > address(weth)){
                skirkSalt = salt;
                break;
            }
        }

        // string memory skirkSalt = "By the wings of eternity and the breath of ages, To all creation, heed my plea";
        string memory acheronSalt = "Still the sands of time and grant me passage, Through the currents of eternity.";

        address xSkirkAddress = skirkDeployer.address3(skirkSalt);
        address AcheronAddress = acheronDeployer.address3(acheronSalt);

        xSKIRK = xSkirk(xSkirkAddress);
        acheron = Acheron(AcheronAddress);

        crv = new CurveMock(address(dai), address(usdc));

        mainAggregator = new SkirkMainAggregatorFoundry(
            address(crv),
            address(dai),
            address(usdc),
            pool_dai_usdc,
            xSkirkAddress
        );

        pool_weth_xSkirk = UniswapFactory.createPool(
            address(weth),
            address(xSkirkAddress),
            500
        );
        vm.stopPrank();

        IUniswapV3Pool(UniswapFactory.getPool(address(weth), address(xSkirkAddress), 500)).initialize(4411237397794263893240602165248); // 3100/1

        universalAggregator = new UniversalAggregator(address(UniswapFactory));
        mangoSwapRouter = new MangoSwapRouter(address(UniswapFactory), address(0x88));

        vm.startPrank(admin.addr);
        acheronDeployer.deploy(
            AcheronDeployer.Params({
                _xSkirkWeth: pool_weth_xSkirk,
                _xSkirk: xSkirkAddress,
                _dai: address(dai),
                _weth: address(weth),
                _skirkAggregator: address(mainAggregator),
                _dai_weth: pool_dai_weth_3000,
                _uniFactory: address(UniswapFactory)
        }),
        acheronSalt
        );

        skirkDeployer.deploy(
            skirkSalt,
            xSkirkDeployerFoundry.Params({
                _projectAcheron: address(acheron),
                _dai: address(dai),
                _owner: address(mainAggregator)
            })
        );

        vm.stopPrank();

        acheron.initialize();

        // Deploying all potions:
        potionGreen = new PotionGreen(address(mainAggregator), address(xSKIRK), address(crv), address(dai), address(usdc), pool_dai_usdc, address(acheron));
        potionBlue = new PotionBlue(address(mainAggregator), address(xSKIRK), address(crv), address(dai), address(usdc), pool_dai_usdc, address(acheron));
        potionPurple = new PotionPurple(address(mainAggregator), address(xSKIRK), address(crv), address(dai), address(usdc), pool_dai_usdc, address(acheron));

        potionGreen.initialize();
        potionBlue.initialize();
        potionPurple.initialize();

        // /*
        // Deployed contracts thus far:
        // { DAI, USDC, WBTC, Uni-Factory, Uni-Pool(dai/usdc), Uni-Pool(dai/weth), Skirk-Pool(weth/xSkirk), 
        //     SkirkSwapFactory, UniswapFactory, universalAggregator, mangoSwapRouter, acheronDeployer, xSkirk, Acheron, }
        // */

        // ////////////////// MAINNET StUFF : //////////

        // // Deploying Skirk Deployer:
        // m_xSkirkDeployer = new xSkirkDeployerMainnet();

        // // Acheron Deployer:
        // m_acheronDeployer = new AcheronDeployerMainnet();

        // string memory xSkirkSalt_Mainnet = "By the silent whisper of infinity, I bid all moments to pause in reverent stillness....";

        // string memory AcheronSalt_Mainnet= "By the power vested in me by the cosmos, let time's relentless tide be stilled.";

        // address xSkirkAddress_mainnet = m_xSkirkDeployer.address3(xSkirkSalt_Mainnet);
        // address Acheronaddress_Mainnet = m_acheronDeployer.address3(AcheronSalt_Mainnet);

        // // console.log("Acheron address:", Acheronaddress_Mainnet);    
        // // console.log("xSkirk address :", xSkirkAddress_mainnet); // SKIRK MUST BE LARGER THAN WETH C02.

        // // Eth mainnet uni factory: 
        // m_uniswapV3Factory = UniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
        // m_weth = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

        // address m_weth_xSkirk_pool = m_uniswapV3Factory.createPool(address(m_weth), xSkirkAddress_mainnet, 500);

        // pool_weth_xSkirk_mainnet = m_weth_xSkirk_pool;

        // // Initializing pool at 3700:
        // IUniswapV3Pool(m_weth_xSkirk_pool).initialize(4819260982861451157002617094144);

        // // Deploy Acheron:
        // m_acheronDeployer.deploy(
        //     AcheronSalt_Mainnet,
        //     AcheronDeployerMainnet.Params({
        //     WETH_SKIRK_POOL: m_weth_xSkirk_pool,
        //     xSkirk: xSkirkAddress_mainnet
        // }));

        // // Deploying xSkirk:
        // m_xSkirkDeployer.deploy(
        //     xSkirkSalt_Mainnet,
        //     Acheronaddress_Mainnet
        // );

        // // Setting instances for tests:
        // m_xSkirk = xSkirk_Core(xSkirkAddress_mainnet);
        // m_acheron = Acheron_Core(Acheronaddress_Mainnet);

        // vm.startPrank(alice.addr);
        // prog = new SkirkMainAggregator();
        // prog.init();
        // vm.stopPrank();

        // // Deploying potion:
        // blue = new Potion_Blue();
        // blue.initialize();

        // // // Initializing Acheorn:
        // // m_acheron.initialize();
    }

    function testLogs() public view {
        console.log(address(dai));
        console.log(address(usdc));
        console.log(address(weth));
        require(address(dai) < address(usdc) && address(usdc) < address(weth), "Addresses wrong");
        require(address(weth) < address(xSKIRK), "Pool wrong");
    }

    /*
    forge test --fork-url=https://eth.llamarpc.com --match-test testFoo -vvvv
    forge test --fork-url=https://ethereum-rpc.publicnode.com --match-test testFoo -vvvv
    */
    // event Bytes32Hash(bytes32 full, bytes32 conc);
    // function testFoo() public {
    //     // Testnig pws:
    //     string memory p1 = "StarFish";
    //     string memory p2 = "Crush";
    //     bytes32 conc = keccak256(abi.encodePacked(p1, p2));
    //     emit Bytes32Hash(conc, conc);
    //     string memory c = "0x36b1e525e47fe8760d7853cfea42779285878e192e3341927d38409255b28090";
    //     bytes32 pw = keccak256(abi.encodePacked(alice.addr, c));
    //     emit Bytes32Hash(pw, conc);
    // }
    // Current
    // 0x05b70b37a67c340b1f8466102db07c0606fb1c1d547379908cfb307761679f39   (full)
    // 0x0c97058570d9670f438104f393c2581e872f34e35ecb500df0d1d61fe07b6435   (pw)

    // New:     ( full)
    // 0xaf0f11046e416c58c0e1359fa0affb08aee7742c1c9329a9b680683013b23e4a   (full)
    // 0x36b1e525e47fe8760d7853cfea42779285878e192e3341927d38409255b28090   (pw)

    function _sortAddresses(address add0, address add1, address add2) internal pure returns (string memory smallestString, string memory mediumString, string memory largestString) {
    // Send strings "0", "1", and "2" to address3() and get the corresponding addresses
    address addr0 = add0;
    address addr1 = add1;
    address addr2 = add2;

    // Initialize an array to store the addresses
    address[3] memory addresses = [addr0, addr1, addr2];
    string[3] memory strings = ["0", "1", "2"];
    
    // Bubble sort the addresses and keep track of the corresponding strings
    for (uint i = 0; i < addresses.length; i++) {
        for (uint j = i + 1; j < addresses.length; j++) {
            if (addresses[i] > addresses[j]) {
                // Swap addresses
                address tempAddr = addresses[i];
                addresses[i] = addresses[j];
                addresses[j] = tempAddr;
                
                // Swap corresponding strings
                string memory tempStr = strings[i];
                strings[i] = strings[j];
                strings[j] = tempStr;
            }
        }
    }

    // After sorting, addresses[0] is the smallest, addresses[1] is medium, and addresses[2] is the largest
    smallestString = strings[0];
    mediumString = strings[1];
    largestString = strings[2];
}

function _uintToString(uint256 v) internal pure returns (string memory) {
    if (v == 0) {
        return "0";
    }
    uint256 digits;
    uint256 temp = v;
    while (temp != 0) {
        digits++;
        temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    uint256 index = digits - 1;
    temp = v;
    while (temp != 0) {
        buffer[index--] = bytes1(uint8(48 + temp % 10));
        temp /= 10;
    }
    return string(buffer);
}

}