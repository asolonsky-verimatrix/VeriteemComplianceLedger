loadScript("ZigBeeComplianceAddress.js")
loadScript("ZigBeeCompliance.js")
var ZigBeeContract = web3.eth.contract(JSON.parse(ZigBeeOutput.contracts["ZigBeeCompliance.sol:ZigBeeCompliance"].abi));
var ZigBee = eth.contract(ZigBeeContract.abi).at(ZigBeeAddress);

loadScript("ModelInfoAddress.js")
loadScript("ModelInfo.js")
var ModelInfoContract = web3.eth.contract(JSON.parse(ModelInfoOutput.contracts["ModelInfo.sol:ModelInfo"].abi));
var ModelInfo = eth.contract(ModelInfoContract.abi).at(ModelInfoAddress);

loadScript("DeviceSecurityAddress.js")
loadScript("DeviceSecurity.js")
var DeviceSecurityContract = web3.eth.contract(JSON.parse(DeviceSecurityOutput.contracts["DeviceSecurity.sol:DeviceSecurity"].abi));
var DeviceSecurity = eth.contract(DeviceSecurityContract.abi).at(DeviceSecurityAddress);

