require("@nomiclabs/hardhat-waffle");
require('@nomiclabs/hardhat-ethers');

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.6.12",
  networks: {
    ropsten: {
      url: 'https://eth-ropsten.alchemyapi.io/v2/Tw7KaBSz1TdIBG4OnHCZjEPldR3aefYa',
      accounts: ['0xd3f79d3d523161fa1f66fc2d27f987220e66f5d67d81f3f7cdeb4921db1358e8']
      // 0x22B7F2e7d362f1a8085c3495692453a5D2117183
    }
  },
  settings: {
    optimizer: {
      enabled: true,
      runs: 200
    }
  }
};

