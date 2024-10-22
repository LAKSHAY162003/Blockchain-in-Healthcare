const Oracle = artifacts.require("./Oracle.sol");
const HealthcareAutomationWithIPFS = artifacts.require("./HealthcareAutomationWithIPFS.sol");

module.exports = async function(deployer) {
    // Deploy the Oracle contract first
    await deployer.deploy(Oracle);
    const oracleInstance = await Oracle.deployed(); // Get the deployed instance
    console.log("This is address : "+oracleInstance.address)
    // Now deploy the HealthcareAutomationWithIPFS contract with the address of the Oracle
    await deployer.deploy(HealthcareAutomationWithIPFS, oracleInstance.address);
};
