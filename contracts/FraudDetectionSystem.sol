// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

    function storeMedicalData(string memory _deviceId, uint _rawValue) public {
        uint processedValue = processData(_rawValue);
        string memory dataString = string(abi.encodePacked(_deviceId, ",", uint2str(processedValue)));
        
        bytes32 requestId = oracle.requestIPFSHash(dataString);
        requestIdToIndex[requestId] = recordCount;

        emit DataStored(block.timestamp, _deviceId, "Requesting IPFS Hash");

        if (processedValue > thresholdValue) {
            emit ThresholdExceeded(_deviceId, processedValue, block.timestamp);
        }
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

    function processData(uint _value) internal pure returns (uint) {
        // Implement your data cleaning, filtering, and aggregation logic here
        return _value;
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
