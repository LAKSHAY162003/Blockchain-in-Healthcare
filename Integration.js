const mqtt = require('mqtt');
const { create } = require('ipfs-http-client');
const Web3 = require('web3');
const fs = require('fs');

// Connect to MQTT broker
const mqttClient = mqtt.connect('mqtt://broker.hivemq.com'); // Replace with your broker

// Connect to IPFS (Infura)
const ipfs = create('https://ipfs.infura.io:5001/api/v0');

// Connect to Ethereum (Infura)
const web3 = new Web3('https://mainnet.infura.io/v3/YOUR_INFURA_PROJECT_ID');

// Smart contract details
const contractABI = JSON.parse(fs.readFileSync('HealthcareAutomationWithIPFS_ABI.json')); // ABI of the smart contract
const contractAddress = 'YOUR_CONTRACT_ADDRESS';
const healthcareContract = new web3.eth.Contract(contractABI, contractAddress);

// Chainlink Oracle details
const oracleAddress = 'CHAINLINK_ORACLE_ADDRESS';
const oracleABI = JSON.parse(fs.readFileSync('IPFSOracle_ABI.json')); // ABI of the Chainlink Oracle contract
const oracleContract = new web3.eth.Contract(oracleABI, oracleAddress);

const account = 'YOUR_ETHEREUM_ADDRESS';

mqttClient.on('connect', () => {
    mqttClient.subscribe('medical/iot/data', (err) => {
        if (!err) {
            console.log('Subscribed to MQTT topic');
        }
    });
});

mqttClient.on('message', async (topic, message) => {
    console.log(Received message: ${message.toString()});
    const data = JSON.parse(message.toString());

    // Process data
    const processedData = processMedicalData(data);

    // Upload data to IPFS
    const ipfsHash = await uploadToIPFS(processedData);

    // Store IPFS hash on blockchain
    await storeIpfsHashOnBlockchain(data.deviceId, ipfsHash);
});

function processMedicalData(data) {
    // Implement your data processing logic here
    return data; // Example: Return the processed data
}

async function uploadToIPFS(data) {
    try {
        const result = await ipfs.add(JSON.stringify(data));
        console.log('Uploaded to IPFS:', result.path);
        return result.path;
    } catch (error) {
        console.error('IPFS upload error:', error);
    }
}

async function storeIpfsHashOnBlockchain(deviceId, ipfsHash) {
    try {
        const tx = await healthcareContract.methods.storeMedicalData(deviceId, ipfsHash).send({ from: account });
        console.log('Stored IPFS hash on blockchain');
    } catch (error) {
        console.error('Blockchain transaction error:', error);
    }
}
