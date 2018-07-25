Table of contents
=================

<!--ts-->
   * [Installation](https://github.com/VerimatrixGen1/VeriteemComplianceLedger/wiki#installation)
   * [Overview](https://github.com/VerimatrixGen1/VeriteemComplianceLedger/wiki#overview)
   * [System Contracts](https://github.com/VerimatrixGen1/VeriteemComplianceLedger/wiki#system-contracts)
   * * [ZigBee Device Compliance](https://github.com/VerimatrixGen1/VeriteemComplianceLedger/wiki/ZigBee-Device-Compliance)
   * * [Model Info](https://github.com/VerimatrixGen1/VeriteemComplianceLedger/wiki/Model-Info)
   * * [Device Security](https://github.com/VerimatrixGen1/VeriteemComplianceLedger/wiki/Device-Security)
   * * [MetaData](https://github.com/VerimatrixGen1/VeriteemComplianceLedger/wiki/MetaData)
   * [File Description](https://github.com/VerimatrixGen1/VeriteemComplianceLedger/wiki/File-Description)
  <!--te-->

# Installation
Veriteem Compliance Ledger is an application which runs on top of Veriteem.  Currently, only Linux Ubuntu 16.04LTS is supported.  However, the Veriteem is deployed and accessed with Python3, and thus Windows and MacOS may be supported in the near future.

Installing Veriteem Compliance Ledger is a two step process:
```
pip3 install veriteemcomplianceledger
VeriteemConfig.py
```
* Click here for instructions on [installing pip3](https://github.com/VerimatrixGen1/Veriteem/wiki/Detailed-Installation-and-Troubleshooting#installing-pip3)

The first time VeriteemConfig is run it will install additional programs and configure your private data.

# Operation
## Command line interface
The Veriteem Compliance Ledger may be accessed through the Veriteem command line interface:
```
VeriteemCL.py
```

VeriteemCL.py will load the contract interfaces for: ZigBee, ModelInfo, DeviceSecurity, and MetaData.  The default access rights for an account is Public Reader.  In order to submit transactions, the Compliance Ledger Guardian needs to add the user's account to their Contributor's list.  Email veriteemguardian010@gmail.com for access information.

## Stopping Node
Veriteem runs in the background, and thus exiting the command line interface will not halt the node's operation.  In order to halt the node, from any location type:
```
VeriteemConfig.py -s
```

## Restart Node
The Veriteem node will automatically start at the end of the installation process.  However, the default installation will not automatically start after a reboot.  From any location, type the following command to restart Veriteem:
```
VeriteemConfig.py -r
```

# Validation
Once a Veriteem Compliance Ledger node has been installed, the user should perform the following basic checks that their node is connected to the ledger, and is in sync with the network.

## Verify BlockNumber
* Retreive Block Number from [Veriteem Dashboard](http://www.veriteem.complianceblockchain.org/Veriteem/Dashboard/NetworkMap)
* Launch Veriteem Compliance Ledger command line interface
```
VeriteemCL.py
```
* Verify Block Number is equal to the current network block number.
```
eth.blockNumber
```
* Verify there is at least 1 peer
```
admin.peers.length
```

If the block number and peer length does not met the expected values, then the node is not fully connected to the Veriteem Network.  Click here for a [Veriteem Troubleshooting guide](https://github.com/VerimatrixGen1/Veriteem/wiki/Detailed-Installation-and-Troubleshooting)

## Verify ZigBee Contract
* Launch Veriteem Compliance Ledger command line interface
```
VeriteemCL.py
```
* Define a full specified family string (Cert type, Company Name, Model, HwVer, FwVer
```
ZNMHF = '{"Cert":"ZigBee3","Name":"Acme","Model":"Boomerang","HwVer":"1.0","FwVer":"1.0"}'
```
* Read Family Tree
```
ZigBee.ReadFamily(ZNMHF)
```
* Family Tree Expected results
```
["0x425fd133b04814563267cec46e360ef33a106f28", true, 0, "0x425fd133b04814563267cec46e360ef33a106f28"]
```
* Read compliance record
```
ZigBee.Read(ZigBee.CalcComplianceId(ZNMHF))
```
* Compliance record expected results
```
["0xca2a2c28e971321d196fe1ff187afce136f0dc73", "0xa8f77fc608378ed9961d71ac34fe23279a7c21e1", "0/0/0", "{\"Name\":\"Acme\",\"Model\":\"Boomerang\",\"HwVer\":\"1.0\",\"FwVer\":\"1.0\",\"Sku\":\"1111\",\"ApplicationType\":\"ZigBee 3.0\",\"ApplicationTypeVer\":\"1.0\",\"TechCategory\":\"ZigBee 3.0\",\"TechSubCategories\":[\"Temperature Sensor (Home)\"],\"ParentFuncCategories\":[\"Energy Efficiency\"],\"FuncSubCategories\":[\"Thermometer\",\"Temperature Sensor (Home)\",\"Simple Sensor\",\"Sensor\",\"Energy Efficiency\"],\"CertId\":\"ZIG1111\",\"CertDate\":\"1/1/2018\"}", true, "0x0000000000000000000000000000000000000000"]
```

If the compliance ledger validation fails, verify the Veriteem operation, and then look [here](https://github.com/VerimatrixGen1/VeriteemComplianceLedger/wiki/Detailed-Installation-and-Troubleshooting) for a Compliance Ledger Troubleshooting guide.

# Overview
The Veriteem Compliance Ledger provides application specific access to Distributed Ledgers running over the Veriteem Distributed Ledger Technology (DLT).  Veriteem  ***TBD add link*** in turn is an Ethereum Fork which provides a publicly readable ledger with multiple levels of write access with Proof of Authority consensus.  The ledger is managed by a group of Ledger Guardians, who provide the transaction processing, Proof of Authority consensus, and management of Smart Contracts running on the ledger.

The Veriteem Compliance Ledger framework is used to provide device information from manufacturers and compliance organizations to network and ecosystem operators.  The information includes compliance status, firmware update links, operating instructions, and expected network behavior.  This information is provided in a machine readable interface for use by onboarding/installer tools, gateways, and backend systems.

The access control to the ledger is managed within the Veriteem Distributed Ledger Technology.  Please refer to the Veriteem Access Control section for more information about how this is managed for the ledger applications that make up the Veriteem Compliance Ledger.

https://github.com/VerimatrixGen1/Veriteem/wiki#access-control

[[https://github.com/VerimatrixGen1/VeriteemComplianceLedger/blob/master/Wiki/Images/UseCases.png]]

# System Contracts
The Compliance Ledger contains a set of contracts which are written by compliance organizations, and contracts which are written by the device manufacturer.

[[https://github.com/VerimatrixGen1/VeriteemComplianceLedger/blob/master/Wiki/Images/Veriteem%20Compliance%20Ledger.png]]

Device data is indexed by either a ComplianceID, which is derived from data provided by a the device, or ModelID, which is randomly generated by the manufacturer.  Each compliance organization's contract provides a means to convert data provided by the device to a ComplianceID, which is then used to read the ModelID from the compliance record.  The ModelID may then be used to read manufacturer supplied data, or read other compliance organization's records as they may apply to the device.

