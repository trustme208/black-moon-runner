require("dotenv").config();
require("@nomiclabs/hardhat-ethers");

module.exports = {
  solidity: "0.8.19",
  networks: {
    cronosTestnet: {
      url: process.env.RPC_TESTNET || "https://evm-t3.cronos.org",
      chainId: 338,
      accounts: process.env.DEPLOYER_PRIVATE_KEY ? [process.env.DEPLOYER_PRIVATE_KEY] : []
    },
    cronosMainnet: {
      url: process.env.RPC_MAINNET || "https://evm.cronos.org",
      chainId: 25,
      accounts: process.env.DEPLOYER_PRIVATE_KEY ? [process.env.DEPLOYER_PRIVATE_KEY] : []
    }
  }
};
