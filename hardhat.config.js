require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",
  networks: {
    hardhat:{
      forking: {
        url: process.env.ETHEREUM_MAINNET_RPC_URL,
      },
      chainId: 1,
    },
  }
};
