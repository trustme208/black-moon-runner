async function main() {
  const hre = require("hardhat");
  const ethers = hre.ethers;
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with:", deployer.address);

  const BMN = await ethers.getContractFactory("BMNToken");
  const initialSupply = ethers.utils.parseUnits("1000000", 18);
  const bmn = await BMN.deploy(initialSupply);
  await bmn.deployed();
  console.log("BMNToken:", bmn.address);

  const Profile = await ethers.getContractFactory("ProfileRegistry");
  const profile = await Profile.deploy();
  await profile.deployed();
  console.log("ProfileRegistry:", profile.address);

  const Pool = await ethers.getContractFactory("WithdrawalPool");
  const pool = await Pool.deploy(bmn.address);
  await pool.deployed();
  console.log("WithdrawalPool:", pool.address);

  const tx = await bmn.transfer(pool.address, ethers.utils.parseUnits("50000", 18));
  await tx.wait();
  console.log("Funded pool with 50,000 BMN");

  console.log("Done.");
}

main().catch((e)=>{ console.error(e); process.exit(1); });
