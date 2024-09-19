const HDWalletProvider = require('truffle-hdwallet-provider');
const INFURA_API_KEY = "https://sepolia.infura.io/v3/0c66b6596fa24857a581c9397f870206";

const mnemonic = "when various mask cool practice version spot mobile point ball space apology";

module.exports = {
  
   solc: {
    optimizer:{
      enabled: true,
      runs: 200
    }
   },

  networks: {
   

    development: {
      //Ganache
      host: "127.0.0.1",     // Localhost (default: none)
      port: 3000,            // Standard Ethereum port (default: none)
      network_id: "*",       // Any network (default: none)
    },
    
    sepolia: {
      provider: () => new HDWalletProvider(mnemonic, INFURA_API_KEY),
      network_id: "11155111",
      gas: 4465030,
      timeout:800,
      timeoutBlocks: 200,  // Timeout settings for transactions
    },

  },

  mocha: {
    timeout: 100000
  },

  compilers: {
    solc: {
      version: "0.5.16", 
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
      }
    }
  }
}