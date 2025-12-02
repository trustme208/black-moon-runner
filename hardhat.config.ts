import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-ethers";
import * as dotenv from "dotenv";
dotenv.config();

const { DEPLOYER_PRIVATE_KEY, RPC_TESTNET, RPC_MAINNET } = process.env;

const config: HardhatUserConfig = {
  solidity: "0.8.19",
  networks: {
    cronosTestnet: {
      url: RPC_TESTNET || "https://evm-t3.cronos.org",
      chainId: 338,
      accounts: DEPLOYER_PRIVATE_KEY ? [DEPLOYER_PRIVATE_KEY] : []
    },
    cronosMainnet: {
      url: RPC_MAINNET || "https://evm.cronos.org",
      chainId: 25,
      accounts: DEPLOYER_PRIVATE_KEY ? [DEPLOYER_PRIVATE_KEY] : []
    }
  }
};

export default config;
