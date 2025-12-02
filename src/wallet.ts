import { ethers } from "ethers";
import WalletConnectProvider from "@walletconnect/web3-provider";

export const TARGET_NETWORK = {
  chainId: 338,
  hexChainId: "0x152",
  rpc: "https://evm-t3.cronos.org",
  name: "Cronos Testnet"
};

let provider: ethers.providers.Web3Provider | null = null;
let wcProvider: any = null;

export async function connectWithMetaMask() {
  const win = window as any;
  if (!win.ethereum) throw new Error("MetaMask not found");
  try {
    await win.ethereum.request({
      method: "wallet_switchEthereumChain",
      params: [{ chainId: TARGET_NETWORK.hexChainId }]
    });
  } catch (err:any) {
    if (err.code === 4902) {
      await win.ethereum.request({
        method: "wallet_addEthereumChain",
        params: [{
          chainId: TARGET_NETWORK.hexChainId,
          chainName: TARGET_NETWORK.name,
          rpcUrls: [TARGET_NETWORK.rpc],
          nativeCurrency: { name: "TCRO", symbol: "TCRO", decimals: 18 }
        }]
      });
    }
  }
  provider = new ethers.providers.Web3Provider(win.ethereum);
  await provider.send("eth_requestAccounts", []);
  const signer = provider.getSigner();
  const address = await signer.getAddress();
  return { address, signer, provider };
}

export async function connectWithWalletConnect() {
  wcProvider = new WalletConnectProvider({
    rpc: { [TARGET_NETWORK.chainId]: TARGET_NETWORK.rpc },
    chainId: TARGET_NETWORK.chainId,
    qrcode: true
  });
  await wcProvider.enable();
  provider = new ethers.providers.Web3Provider(wcProvider);
  const signer = provider.getSigner();
  const address = await signer.getAddress();
  return { address, signer, provider };
}

export function getProvider() { return provider; }

export async function disconnectWallet() {
  try { if (wcProvider && wcProvider.disconnect) await wcProvider.disconnect(); } catch(e){/*ignore*/ }
  provider = null; wcProvider = null;
}
