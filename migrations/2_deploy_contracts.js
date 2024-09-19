const FraudDetectionSystem = artifacts.require("./FraudDetectionSystem.sol");
module.exports = function(deployer) {
    deployer.deploy(FraudDetectionSystem);
};