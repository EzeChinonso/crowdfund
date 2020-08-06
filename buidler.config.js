usePlugin("@nomiclabs/buidler-waffle")
usePlugin("@nomiclabs/buidler-ethers")
task("accounts", "Prints the list of accounts", async () => {
    const accounts = await ethers.getSigners();
  
    for (const account of accounts) {
      console.log(await account.getAddress());
    }
  });

module.exports = {
    solc: {
        version: "0.6.8"
    },
    networks: {
        buidlerevm: {
          gas: 12000000,
          blockGasLimit: 0x1fffffffffffff,
          allowUnlimitedContractSize: true,
          timeout: 1800000
        }
      }
};
