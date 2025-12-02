import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with:", deployer.address);

  const BMN = await ethers.getContractFactory("BMNToken");
  const initialSupply = ethers.parseUnits("1000000", 18);
  const bmn = await BMN.deploy(initialSupply);
  await bmn.waitForDeployment();
  console.log("BMNToken:", await bmn.getAddress());

  const Profile = await ethers.getContractFactory("ProfileRegistry");
  const profile = await Profile.deploy();
  await profile.waitForDeployment();
  console.log("ProfileRegistry:", await profile.getAddress());

  const Pool = await ethers.getContractFactory("WithdrawalPool");
  const pool = await Pool.deploy(await bmn.getAddress());
  await pool.waitForDeployment();
  console.log("WithdrawalPool:", await pool.getAddress());

  const tx = await bmn.transfer(await pool.getAddress(), ethers.parseUnits("50000", 18));
  await tx.wait();
  console.log("Funded pool with 50,000 BMN");

  console.log("Done.");
}

main().catch(e=>{ console.error(e); process.exit(1); });
