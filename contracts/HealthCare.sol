// SPDX-License-Identifier: MIT
pragma solidity ^0.5.7;

interface IOracle {
    function requestIPFSHash(string calldata _data) external returns (bytes32 requestId);
    function getIPFSHash(bytes32 _requestId) external view returns (string memory);
}

contract HealthcareAutomationWithIPFS {

    struct MedicalData {
        uint timestamp;
        string deviceId;
        string ipfsHash;
    }

    address public owner;
    IOracle public oracle;
    mapping(uint => MedicalData) public medicalRecords;
    uint public recordCount = 0;
    uint public thresholdValue = 100;
    mapping(bytes32 => uint) public requestIdToIndex;

    event DataStored(uint timestamp, string deviceId, string ipfsHash);
    event ThresholdExceeded(string deviceId, uint value, uint timestamp);
    event DataProcessed(uint256 normalizedOxygenSaturation, uint256 normalizedRespiratoryRate, uint256 normalizedTemperature);

    constructor(address _oracle) {
        owner = msg.sender;
        oracle = IOracle(_oracle);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can perform this action.");
        _;
    }

    function setThresholdValue(uint _thresholdValue) public onlyOwner {
        thresholdValue = _thresholdValue;
    }

    // Struct to hold cleaned and normalized sensor data
    struct ProcessedMedicalData {
        uint256 oxygenSaturation;
        uint256 respiratoryRate;
        uint256 temperature;
    }

    // Function to process and normalize the medical data
    function processMedicalData(uint256 oxygenSaturation, uint256 respiratoryRate, uint256 temperature) internal pure returns (ProcessedMedicalData memory) {
        // Data cleaning - check ranges
        require(oxygenSaturation > 0 && oxygenSaturation <= 100, "Invalid oxygen saturation value");
        require(respiratoryRate > 0, "Invalid respiratory rate value");
        require(temperature > 0 && temperature < 45, "Invalid temperature value");

        // Data filtering - Remove values outside medical norms
        if (oxygenSaturation < 80 || oxygenSaturation > 100) {
            oxygenSaturation = 0; // Mark as invalid
        }
        if (respiratoryRate < 12 || respiratoryRate > 25) {
            respiratoryRate = 0; // Mark as invalid
        }
        if (temperature < 36 || temperature > 40) {
            temperature = 0; // Mark as invalid
        }

        // Normalization: scaling to range of 0 - 1 (in integers, scaling by 10000 for precision)
        uint256 normalizedOxygenSaturation = 0;
        uint256 normalizedRespiratoryRate = 0;
        uint256 normalizedTemperature = 0;

        if (oxygenSaturation > 0) {
            normalizedOxygenSaturation = (oxygenSaturation - 80) * 10000 / (100 - 80); // Normalized between 80-100
        }
        if (respiratoryRate > 0) {
            normalizedRespiratoryRate = (respiratoryRate - 12) * 10000 / (25 - 12); // Normalized between 12-25
        }
        if (temperature > 0) {
            normalizedTemperature = (temperature - 36) * 10000 / (40 - 36); // Normalized between 36-40
        }

        // Emit event with normalized data
        emit DataProcessed(normalizedOxygenSaturation, normalizedRespiratoryRate, normalizedTemperature);

        return ProcessedMedicalData(normalizedOxygenSaturation, normalizedRespiratoryRate, normalizedTemperature);
    }

    function storeMedicalData(string memory _deviceId, uint256 oxygenSaturation, uint256 respiratoryRate, uint256 temperature) public {
        // Process and normalize the medical data
        ProcessedMedicalData memory processedData = processMedicalData(oxygenSaturation, respiratoryRate, temperature);

        // Prepare data for IPFS storage
        string memory dataString = string(abi.encodePacked(
            _deviceId, ",",
            uint2str(processedData.oxygenSaturation), ",",
            uint2str(processedData.respiratoryRate), ",",
            uint2str(processedData.temperature)
        ));
        
        bytes32 requestId = oracle.requestIPFSHash(dataString);
        requestIdToIndex[requestId] = recordCount;

        emit DataStored(block.timestamp, _deviceId, "Requesting IPFS Hash");

        // Check if any of the normalized values exceed the threshold
        if (processedData.oxygenSaturation > thresholdValue || processedData.respiratoryRate > thresholdValue || processedData.temperature > thresholdValue) {
            emit ThresholdExceeded(_deviceId, thresholdValue, block.timestamp);
        }

        recordCount++;
    }

    function fulfillIPFSHash(bytes32 _requestId, string memory _ipfsHash) public {
        require(msg.sender == address(oracle), "Only Oracle can call this function");
        uint index = requestIdToIndex[_requestId];
        medicalRecords[index] = MedicalData(block.timestamp, "", _ipfsHash);
        
        emit DataStored(block.timestamp, "", _ipfsHash);
    }

    function getMedicalData(uint _index) public view returns (uint, string memory, string memory) {
        MedicalData memory data = medicalRecords[_index];
        return (data.timestamp, data.deviceId, data.ipfsHash);
    }

    function getRecordCount() public view returns (uint) {
        return recordCount;
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        return string(bstr);
    }
}
