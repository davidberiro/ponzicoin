// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile 
  // manually to make sure everything is compiled
  await hre.run('compile');

  // We get the contract to deploy
  const PriceFormulaFactory = await hre.ethers.getContractFactory("PriceFormula");
  const PonziTokenFactory = await hre.ethers.getContractFactory("PonziToken");
  const PonziMinterFactory = await hre.ethers.getContractFactory("PonziMinter");
  const priceFormula = await PriceFormulaFactory.deploy();
  await priceFormula.deployed();
  console.log("Price Formula deployed to:", priceFormula.address);
  const ponziToken = await PonziTokenFactory.deploy();
  await ponziToken.deployed();
  console.log("Ponzi Token deployed to:", ponziToken.address);
  const ponziMinter = await PonziMinterFactory.deploy(
    ponziToken.address,
    priceFormula.address,
    '900',
    '1000000687',
    '1000000000'
  );
  await ponziMinter.deployed();
  await ponziToken.transferOwnership(ponziMinter.address);

  console.log("Ponzi Minter deployed to:", ponziMinter.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
