// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require('hardhat');

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  // erc20 contract
  // DemoAllocations

  const Demo = await hre.ethers.getContractFactory('Demo');
  const demo = await Demo.deploy('Demo', 'DMO');

  const DemoAllocations = await hre.ethers.getContractFactory(
    'DemoAllocations'
  );
  const demoAllocations = await DemoAllocations.deploy();

  await demo.deployed();
  await demoAllocations.deployed();

  console.log('Demo deployed to:', demo.address);
  console.log('DemoAllocations deployed to:', demoAllocations.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
