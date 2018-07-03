var mnemonic = "grass wedding super kidney answer farm sphere brush rhythm subject file elevator";
var HDWalletProvider = require("truffle-hdwallet-provider");

module.exports = {
  networks: {
    development: {
        host: "127.0.0.1",
        port: 7545,
        network_id: "*" // Match any network id
    },
    ropsten: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "https://ropsten.infura.io/NObCJjyiq2gnLbdZCXB2")
      },
      network_id: 3,
      //gas: 2712388
      gas: 3000000
      //,gasPrice: 100000000000
    } 
    // local_ropsten: {
    //   host: "localhost",
    //   port: 8545,
    //   network_id: "3"
    //   gas: 4712388,
    //   gasPrice: 100000000000
    //   from: XXXXX
    // }  
  } 
};

