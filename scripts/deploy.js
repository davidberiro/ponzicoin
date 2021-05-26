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
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with account:" , deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // We get the contract to deploy
  const PriceFormulaFactory = await hre.ethers.getContractFactory("PriceFormula");
  const PonziTokenFactory = await hre.ethers.getContractFactory("PonziToken");
  const PonziMinterFactory = await hre.ethers.getContractFactory("PonziMinter");
  const priceFormula = await PriceFormulaFactory.deploy();
  await priceFormula.deployed();
  console.log("Price Formula deployed to:", priceFormula.address);
  const ponziToken = await PonziTokenFactory.deploy(
    deployer.address, //TODO: this address in ponzipool
    deployer.address
  );
  await ponziToken.deployed();
  console.log("Ponzi Token deployed to:", ponziToken.address);
  const ponziMinter = await PonziMinterFactory.deploy(
    ponziToken.address,
    priceFormula.address,
    '900000',
    //'1000000687',
    '0',
    '1000000000'
  );
  await ponziMinter.deployed();
  await deployer.sendTransaction({
    to: ponziMinter.address,
    value: ethers.utils.parseEther("0.0001")
  });
  //console.log(ponziToken.functions.mint)
  await ponziToken.functions.mint(deployer.address, '1000000000000000000');
  console.log("Ponzi Minter deployed to:", ponziMinter.address);
  await ponziToken.transferOwnership(ponziMinter.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
