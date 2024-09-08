// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Token.sol";
import "hardhat/console.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";

contract TokenFactory {
    struct memeToken {
        string name;
        string symbol;
        string description;
        string imageUrl;
        uint fundingRaised;
        address tokenAddress;
        address creatorAddress;
    }

    address[] public memeTokenAddresses;

    uint constant DECIMALS = 10 ** 18;
    uint constant MAX_SUPPLY = 1000000 * DECIMALS;
    uint constant INITIAL_SUPPLY = (20 * MAX_SUPPLY) / 100; // 20% of the total supply

    uint constant TOKEN_CREATION_FEE = 0.001 ether;

    uint constant MEMECOIN_FUNDING_GOAL = 24 ether;

    address constant UNISWAP_V2_FACTORY_ADDRESS =
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    address constant UNISWAP_V2_ROUTER_ADDRESS =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    uint256 public constant INITIAL_PRICE = 30000000000000; // Initial price in wei (P0), 3.00 * 10^13
    uint256 public constant K = 8 * 10 ** 15; // Growth rate (k), scaled to avoid precision loss (0.01 * 10^18)

    mapping(address => memeToken) addressToMemeToken;

    function createMemeToken(
        string memory name,
        string memory symbol,
        string memory description,
        string memory imageUrl
    ) public payable returns (address) {
        require(msg.value >= TOKEN_CREATION_FEE, "Not enough ETH sent"); // Check if the user has sent enough ETH to create the token

        // create the meme token
        Token memeTokenContract = new Token(name, symbol, INITIAL_SUPPLY);
        address memeTokenAddress = address(memeTokenContract);
        memeTokenAddresses.push(memeTokenAddress);
        addressToMemeToken[memeTokenAddress] = memeToken(
            name,
            symbol,
            description,
            imageUrl,
            0,
            memeTokenAddress,
            msg.sender
        );
        console.log("Meme token contract address:", memeTokenAddress);

        return memeTokenAddress;
    }

    function buyMemeToken(
        address memeTokenAddress,
        uint purchaseQuantity
    ) public payable returns (uint) {
        require(
            addressToMemeToken[memeTokenAddress].tokenAddress != address(0),
            "Token does not exist"
        );
        console.log("Token exists");
        memeToken storage listedMemeToken = addressToMemeToken[
            memeTokenAddress
        ];

        require(
            listedMemeToken.fundingRaised <= MEMECOIN_FUNDING_GOAL,
            "Funding goal has already been reached"
        );

        Token tokenCt = Token(memeTokenAddress);

        uint currentSupply = tokenCt.totalSupply();
        uint availableSupply = MAX_SUPPLY - currentSupply;

        uint availableSupplyScaled = availableSupply / DECIMALS;
        uint purchaseQuantityScaled = purchaseQuantity * DECIMALS;
        require(purchaseQuantity <= availableSupplyScaled, "Not enough supply");

        //calculate the cost of the purchase [purchaseQuantity] tokens
        uint currentSupplyScaled = (currentSupply - INITIAL_SUPPLY) / DECIMALS;
        uint requiredEth = calculateCost(currentSupplyScaled, purchaseQuantity);

        // require(msg.value >= requiredEth, "Not enough ETH sent");

        console.log("Required ETH for purchase is:", requiredEth);

        require(msg.value >= requiredEth, "Not enough ETH sent");

        listedMemeToken.fundingRaised += msg.value;

        tokenCt.mint(purchaseQuantityScaled, msg.sender);

        console.log("Minted", purchaseQuantityScaled, "tokens");
        console.log("Balance of user is", tokenCt.balanceOf(msg.sender));

        if (listedMemeToken.fundingRaised >= MEMECOIN_FUNDING_GOAL) {
            // create the liquidity pool on Uniswap
            address pool = _createLiquidityPool(memeTokenAddress);
            console.log("Liquidity pool created at", pool);

            // provide liquidity to the pool
            uint ethAmount = listedMemeToken.fundingRaised;
            uint liquidity = _provideLiquidity(
                memeTokenAddress,
                INITIAL_SUPPLY,
                ethAmount
            );
            console.log("Liquidity provided to the pool", liquidity);

            // burn the lp token that represents the user's share of the pool
            burnLPToken(pool, liquidity);
        }

        return requiredEth;
    }

    function calculateCost(
        uint256 currentSupply,
        uint256 tokensToBuy
    ) public pure returns (uint256) {
        uint256 exponent1 = (K * (currentSupply + tokensToBuy)) / 10 ** 18;
        uint256 exponent2 = (K * currentSupply) / 10 ** 18;

        uint256 exp1 = exp(exponent1);
        uint256 exp2 = exp(exponent2);

        uint256 cost = (INITIAL_PRICE * 10 ** 18 * (exp1 - exp2)) / K;
        return cost;
    }

    function exp(uint256 x) internal pure returns (uint256) {
        uint256 sum = 10 ** 18;
        uint256 term = 10 ** 18;
        uint256 xPower = x;

        for (uint256 i = 1; i <= 20; i++) {
            term = (term * xPower) / (i * 10 ** 18);
            sum += term;

            if (term < 1) break;
        }
        return sum;
    }

    function _createLiquidityPool(
        address memeTokenAddress
    ) internal returns (address) {
        IUniswapV2Factory uniswapV2Factory = IUniswapV2Factory(
            UNISWAP_V2_FACTORY_ADDRESS
        );
        IUniswapV2Router01 uniswapV2Router = IUniswapV2Router01(
            UNISWAP_V2_ROUTER_ADDRESS
        );

        address pair = uniswapV2Factory.createPair(
            memeTokenAddress,
            uniswapV2Router.WETH()
        );

        return pair;
    }

    function _provideLiquidity(
        address memeTokenAddress,
        uint tokenAmount,
        uint ethAmount
    ) internal returns (uint) {
        Token tokenCt = Token(memeTokenAddress);
        tokenCt.approve(UNISWAP_V2_ROUTER_ADDRESS, tokenAmount);
        IUniswapV2Router01 uniswapV2Router = IUniswapV2Router01(
            UNISWAP_V2_ROUTER_ADDRESS
        );
        (uint amountToken, uint amountETH, uint liquidity) = uniswapV2Router
            .addLiquidityETH{value: ethAmount}(
            memeTokenAddress,
            tokenAmount,
            tokenAmount,
            ethAmount,
            address(this),
            block.timestamp
        );
        return liquidity;
    }

    function burnLPToken(address pool, uint liquidity) internal returns (uint) {
        IUniswapV2Pair pair = IUniswapV2Pair(pool);
        pair.transfer(address(0), liquidity);
        console.log("LP token burned: ", liquidity);
        return 1;
    }

    function getAllMemeTokens() public view returns (memeToken[] memory) {
        memeToken[] memory allMemeTokens = new memeToken[](
            memeTokenAddresses.length
        );
        for (uint i = 0; i < memeTokenAddresses.length; i++) {
            allMemeTokens[i] = addressToMemeToken[memeTokenAddresses[i]];
        }
        return allMemeTokens;
    }
}
