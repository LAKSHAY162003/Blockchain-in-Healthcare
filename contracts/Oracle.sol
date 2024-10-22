// SPDX-License-Identifier: MIT
pragma solidity ^0.5.7;

interface IOracle {
    function requestIPFSHash(string calldata _data) external returns (bytes32 requestId);
    function getIPFSHash(bytes32 _requestId) external view returns (string memory);
    function sendDataToAPI(string calldata _apiUrl, string calldata _data) external returns (bytes32 requestId);
}

contract Oracle is IOracle {
    mapping(bytes32 => string) public ipfsHashes;

    function requestIPFSHash(string calldata _data) external returns (bytes32 requestId) {
        requestId = keccak256(abi.encodePacked(_data, block.timestamp));
        ipfsHashes[requestId] = "IPFS_HASH";  // Simulating an IPFS hash response
    }

    function getIPFSHash(bytes32 _requestId) external view returns (string memory) {
        return ipfsHashes[_requestId];
    }

    function sendDataToAPI(string calldata _apiUrl, string calldata _data) external returns (bytes32 requestId) {
        requestId = keccak256(abi.encodePacked(_apiUrl, _data, block.timestamp));
        return requestId;
    }
}
