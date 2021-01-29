pragma solidity >=0.5.17 <0.8.0;

contract Configurable {
    mapping (bytes32 => uint) internal config;

    mapping (bytes32 => string) internal configString;

    mapping (bytes32 => address) internal configAddress;

    function getConfig(bytes32 key) public view returns (uint) {
        return config[key];
    }
    function getConfig(bytes32 key, uint index) public view returns (uint) {
        return config[bytes32(uint(key) ^ index)];
    }
    function getConfig(bytes32 key, address addr) public view returns (uint) {
        return config[bytes32(uint(key) ^ uint(addr))];
    }

    function setConfig(bytes32 key, uint value) internal {
        if(config[key] != value)
            config[key] = value;
    }
    function setConfig(bytes32 key, uint index, uint value) internal {
        setConfig(bytes32(uint(key) ^ index), value);
    }
    function setConfig(bytes32 key, address addr, uint value) internal {
        setConfig(bytes32(uint(key) ^ uint(addr)), value);
    }

    function getConfigString(bytes32 key) public view returns (string memory) {
        return configString[key];
    }
    function getConfigString(bytes32 key, uint index) public view returns (string memory) {
        return configString[bytes32(uint(key) ^ index)];
    }
    function setConfigString(bytes32 key, string memory value) internal {
        configString[key] = value;
    }
    function setConfigString(bytes32 key, uint index, string memory value) internal {
        setConfigString(bytes32(uint(key) ^ index), value);
    }

    function getConfigAddress(bytes32 key) public view returns (address) {
        return configAddress[key];
    }

    function getConfigAddress(bytes32 key, uint index) public view returns (address) {
        return configAddress[bytes32(uint(key) ^ index)];
    }

    function getConfigAddress(bytes32 key, address addrIndex) public view returns (address) {
        return configAddress[bytes32(uint(key) ^ uint256(addrIndex))];
    }

    function setConfigAddress(bytes32 key, address addr) internal {
        configAddress[key] = addr;
    }

    function setConfigAddress(bytes32 key, uint index, address addr) internal {
        setConfigAddress(bytes32(uint(key) ^ index), addr);
    }

    function setConfigAddress(bytes32 key, address addrIndex, address addr) internal {
        setConfigAddress(bytes32(uint(key) ^ uint256(addrIndex)), addr);
    }
}