// This is a script for deploying your contracts. You can adapt it to deploy
// yours, or create new ones.

const { ethers } = require("hardhat");
const path = require("path");

async function main() {
  // This is just a convenience check
  if (network.name === "hardhat") {
    console.warn(
      "You are trying to deploy a contract to the Hardhat Network, which" +
        "gets automatically created and destroyed every time. Use the Hardhat" +
        " option '--network localhost'"
    );
  }

  // ethers is available in the global scope
  const [deployer] = await ethers.getSigners();
  console.log(
    "Deploying the contracts with the account:",
    await deployer.getAddress()
  );

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const Token = await ethers.getContractFactory("Token");

  const token = await Token.deploy();
  await token.deployed();

  console.log("Token address:", token.address);

  const Reserve = await ethers.getContractFactory("Reserve");

  const reserve = await Reserve.deploy(
    token.address,
    process.env.CONNECTOR_WEIGHT,
    process.env.BASE_Y
  );
  await reserve.deployed();

  console.log("Reserve address:", reserve.address);

  const TimelockController = await ethers.getContractAt("TimelockController");

  const timelock = GovernorTimelockControl.deploy(
    process.env.MIN_DELAY,
    process.env.PROPOSERS,
    process.env.EXECUTORS
  );
  await timelock.deployed();

  console.log("Timelock address:", timelock.address);

  const BondingGovernor = await ethers.getContractFactory("BondingGovernor");

  const governor = await BondingGovernor.deploy(
    token.address,
    timelock.address
  );
  await governor.deployed();

  console.log("Governor address:", governor.address);

  // We also save the contract's artifacts and address in the frontend directory
  saveFrontendFiles(token);
}

function saveFrontendFiles(token) {
  const fs = require("fs");

  const deploymentsDir = path.join(__dirname, "deployments");

  if (!fs.existsSync(deploymentsDir)) {
    fs.mkdirSync(deploymentsDir);
  }

  fs.writeFileSync(
    path.join(deploymentsDir, "deployments.json"),
    JSON.stringify({ 
      Token: token.address,
      Reserve: reserve.address,
      Timelock: timelock.address,
      Governor: governor.address
    }, undefined, 2)
  );

  const TokenArtifact = artifacts.readArtifactSync("Token");

  fs.writeFileSync(
    path.join(deploymentsDir, "Token.json"),
    JSON.stringify(TokenArtifact, null, 2)
  );

  const ReserveArtifact = artifacts.readArtifactSync("Reserve");

  fs.writeFileSync(
    path.join(deploymentsDir, "Reserve.json"),
    JSON.stringify(ReserveArtifact, null, 2)
  );

  const TimelockArtifact = artifacts.readArtifactSync("Timelock");

  fs.writeFileSync(
    path.join(deploymentsDir, "Timelock.json"),
    JSON.stringify(TimelockArtifact, null, 2)
  );

  const GovernorArtifact = artifacts.readArtifactSync("Governor");

  fs.writeFileSync(
    path.join(deploymentsDir, "Governor.json"),
    JSON.stringify(GovernorArtifact, null, 2)
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
