import sys
import os
import shutil
import argparse
import time
import datetime
import random
import json
import web3 
from web3 import Web3, HTTPProvider, IPCProvider
from web3.middleware import geth_poa_middleware
from web3.contract import ConciseContract
import veriteem
import vtegrityservices as vtsvc

class ReaderVerify():
  
  myConfig = None
 
  def __init__(self, path):

      installerror = "There is an error with the installation.  Please reinstall with the following commands\n  pip3 install veriteemcomplianceledger\n  VeriteemConfig.py -r "

      try:
         self.myConfig = veriteem.Config(None)
      except:
         Ex = ValueError()
         Ex.strerror = installerror
         raise Ex

      try:
         self.myConfig.LoadConfig()
      except:
         Ex = ValueError()
         Ex.strerror = installerror
         raise Ex

  def Verify(self) :

      GethData = self.myConfig.GETHDATA + "/geth.ipc"
      w3 = Web3(IPCProvider(GethData))
      w3.middleware_stack.inject(geth_poa_middleware,layer=0)

      block = w3.eth.getBlock("latest")
      try:
         blockNumber = block['number'] 
         if blockNumber > 3 :
            print("Block number(" + str(blockNumber) + ") looks good, compliance ledger is running") 
         else :
            print("Block number(" + str(blockNumber) + ") is too low, looks like compliance ledger is not connecting to proper chain") 
            print("Check the configuration of " + self.myConfig.CONFIGPATH + "/genesis.json")
            print("The chainId value should be 18534400 to connect to the correct compliance ledger")
      except:
            print("The compliance ledger is not running")
            print("Try starting the node to access the compliance ledger with the following command")
            print("  VeriteemConfig.py -r")
            return False
     
      peers = w3.admin.peers
      try:
         numpeers = len(peers)
         if numpeers > 0 :
            print("Sucessfully connected to peers - found " + str(numpeers))
         else:
            print("Peer count is 0, so not connected to compliance ledger ")
            print("Check the value of BOOTNODE in " + self.myConfig.CONFIGPATH + "/Config.json")
            print('It should match: "BOOTNODE":"enode://734407da303ea60fc3919f1a9f3ac4a3e9d2f9b3aebafb9593f17953f90aadcbef6b974c692f3444e9d33faef24ee3fd95966c3e6acf2eb7b454143574a81a09@35.155.182.110:60304"')
            print("Make this modification and restart the node with the following commands")
            print("   VeriteemConfig.py -s")
            print("   VeriteemConfig.py -r")
            return False
      except:
         print("Cannot access compliance ledger")
         print("Make sure the compliance ledger is running with the following command")
         print("   VeriteemConfig.py -r")
         return False

      #
      # Get an instance of the ZigBeeCompliance contract
      #
      contract = vtsvc.Contract(None, w3, "ZigBeeCompliance", "ZigBeeCompliance.sol:ZigBeeCompliance")
      ZigCompliance = contract.ConciseContract

      ZNMHF = '{"Cert":"ZigBee3","Name":"Acme","Model":"Boomerang","HwVer":"1.0","FwVer":"1.0"}'

      # 
      # Read the family record
      #
      response = ZigCompliance.ReadFamily(ZNMHF)
      expect = "['0x425fd133b04814563267cec46e360ef33a106f28', True, 0, '0x425fd133b04814563267cec46e360ef33a106f28']"
      failed = False
      if response[0] != '0x425FD133B04814563267CEc46e360eF33A106F28' :
         failed = True
      if response[3] != '0x425FD133B04814563267CEc46e360eF33A106F28' :
         failed = True
      if response[1] != True :
         failed = True
      if response[2] != 0 :
         failed = True
      if failed == True :
         print("Response Mismatch. ")
         print("    Expected " + expect)
         print("    Read     " + str(response))
         return False

      print("Read of FamilyTree Record Passes")
      # 
      # Read the family record
      #

      response = ZigCompliance.Read(ZigCompliance.CalcComplianceId(ZNMHF))

      expect = "['0xca2a2c28E971321D196FE1fF187aFce136F0dC73', '0xa8f77fc608378ED9961D71aC34fe23279a7c21e1', '0/0/0', '{" + '"Name":"Acme","Model":"Boomerang","HwVer":"1.0","FwVer":"1.0","Sku":"1111","ApplicationType":"ZigBee 3.0","ApplicationTypeVer":"1.0","TechCategory":"ZigBee 3.0","TechSubCategories":["Temperature Sensor (Home)"],"ParentFuncCategories":["Energy Efficiency"],"FuncSubCategories":["Thermometer","Temperature Sensor (Home)","Simple Sensor","Sensor","Energy Efficiency"],"CertId":"ZIG1111","CertDate":"1/1/2018"}' + "', True, None]"

      if str(response) != expect :
         print("ZigBeeCompliance read fails")
         print("Expect -> ", expect)
         print("Read -> ", str(response))
         return False
 
      print("ZigBee Compliance record read passes")

      contract = vtsvc.Contract(None, w3, "ModelInfo", "ModelInfo.sol:ModelInfo")
      ModelInfo = contract.ConciseContract

      BoomerangModelId = w3.toChecksumAddress("0xa8f77fc608378ed9961d71ac34fe23279a7c21e1")
      BoomerangData = '[\'{"Name":"Acme","Model":"Boomerang","HwVer":"1.0","CompanyURI":"www.acme.com","MfgCert":"-----BEGIN CERTIFICATE-----MIIDSjCCAjKgAwIBAgIQRK+wgNajJ7qJMDmGLvhAazANBgkqhkiG9w0BAQUFADA/MSQwIgYDVQQKExtEaWdpdGFsIFNpZ25hdHVyZSBUcnVzdCBDby4xFzAVBgNVBAMTDkRTVCBSb290IENBIFgzMB4XDTAwMDkzMDIxMTIxOVoXDTIxMDkzMDE0MDExNVowPzEkMCIGA1UEChMbRGlnaXRhbCBTaWduYXR1cmUgVHJ1c3QgQ28uMRcwFQYDVQQDEw5EU1QgUm9vdCBDQSBYMzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAN+v6ZdQCINXtMxiZfaQguzH0yxrMMpb7NnDfcdAwRgUi+DoM3ZJKuM/IUmTrE4Orz5Iy2Xu/NMhD2XSKtkyj4zl93ewEnu1lcCJo6m67XMuegwGMoOifooUMM0RoOEqOLl5CjH9UL2AZd+3UWODyOKIYepLYYHsUmu5ouJLGiifSKOeDNoJjj4XLh7dIN9bxiqKqy69cK3FCxolkHRyxXtqqzTWMIn/5WgTe1QLyNau7Fqckh49ZLOMxt+/yUFw7BZy1SbsOFU5Q9D8/RhcQPGX69Wam40dutolucbY38EVAjqr2m7xPi71XAicPNaDaeQQmxkqtilX4+U9m5/wAl0CAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMCAQYwHQYDVR0OBBYEFMSnsaR7LHH62+FLkHX/xBVghYkQMA0GCSqGSIb3DQEBBQUAA4IBAQCjGiybFwBcqR7uKGY3Or+Dxz9LwwmglSBd49lZRNI+DT69ikugdB/OEIKcdBodfpga3csTS7MgROSR6cz8faXbauX+5v3gTt23ADq1cEmv8uXrAvHRAosZy5Q6XkjEGB5YGV8eAlrwDPGxrancWYaLbumR9YbK+rlmM6pZW87ipxZzR8srzJmwN0jP41ZL9c8PDHIyh8bwRLtTcm1D9SZImlJnt1ir/md2cXjbDaJWFBM5JDGFoqgCWjBH4d1QB7wCCZAA62RjYJsWvIjJEubSfZGL+T0yjWW06XyxV3bqxbYoOb8VZRzI9neWagqNdwvYkQsEjgfbKbYK7p2CNTUQ-----END CERTIFICATE-----"}\', 2]'

      result = ModelInfo.Read(BoomerangModelId) 
      if str(result) != BoomerangData : 
         print("BoomerangModelId data does not match")
         print("Expect-> ", BoomerangData)
         print("Read-> ",   str(result))
         return False

      print("ModelInfo Boomerang record read passes")
      StickModelId = w3.toChecksumAddress("0x1c40f2b79a07db80b8ae01aea1027a578f67e432")
      StickData = '[\'{"Name":"Acme","Model":"Stick","HwVer":"1.0","CompanyURI":"www.acme.com","MfgCert":"-----BEGIN CERTIFICATE-----MIIDSjCCAjKgAwIBAgIQRK+wgNajJ7qJMDmGLvhAazANBgkqhkiG9w0BAQUFADA/MSQwIgYDVQQKExtEaWdpdGFsIFNpZ25hdHVyZSBUcnVzdCBDby4xFzAVBgNVBAMTDkRTVCBSb290IENBIFgzMB4XDTAwMDkzMDIxMTIxOVoXDTIxMDkzMDE0MDExNVowPzEkMCIGA1UEChMbRGlnaXRhbCBTaWduYXR1cmUgVHJ1c3QgQ28uMRcwFQYDVQQDEw5EU1QgUm9vdCBDQSBYMzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAN+v6ZdQCINXtMxiZfaQguzH0yxrMMpb7NnDfcdAwRgUi+DoM3ZJKuM/IUmTrE4Orz5Iy2Xu/NMhD2XSKtkyj4zl93ewEnu1lcCJo6m67XMuegwGMoOifooUMM0RoOEqOLl5CjH9UL2AZd+3UWODyOKIYepLYYHsUmu5ouJLGiifSKOeDNoJjj4XLh7dIN9bxiqKqy69cK3FCxolkHRyxXtqqzTWMIn/5WgTe1QLyNau7Fqckh49ZLOMxt+/yUFw7BZy1SbsOFU5Q9D8/RhcQPGX69Wam40dutolucbY38EVAjqr2m7xPi71XAicPNaDaeQQmxkqtilX4+U9m5/wAl0CAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMCAQYwHQYDVR0OBBYEFMSnsaR7LHH62+FLkHX/xBVghYkQMA0GCSqGSIb3DQEBBQUAA4IBAQCjGiybFwBcqR7uKGY3Or+Dxz9LwwmglSBd49lZRNI+DT69ikugdB/OEIKcdBodfpga3csTS7MgROSR6cz8faXbauX+5v3gTt23ADq1cEmv8uXrAvHRAosZy5Q6XkjEGB5YGV8eAlrwDPGxrancWYaLbumR9YbK+rlmM6pZW87ipxZzR8srzJmwN0jP41ZL9c8PDHIyh8bwRLtTcm1D9SZImlJnt1ir/md2cXjbDaJWFBM5JDGFoqgCWjBH4d1QB7wCCZAA62RjYJsWvIjJEubSfZGL+T0yjWW06XyxV3bqxbYoOb8VZRzI9neWagqNdwvYkQsEjgfbKbYK7p2CNTUQ-----END CERTIFICATE-----"}\', 0]'

      result = ModelInfo.Read(StickModelId) 
      if str(result) != StickData : 
         print("StickID data does not match")
         print("Expect-> ", StickData)
         print("Read-> ",   str(result))
         return False

      print("ModelInfo StickData record read passes")
      PaintModelId = w3.toChecksumAddress("0xdf4431350d9c950e259327debe8751cedbef2c41")
      PaintData = '[\'{"Name":"Acme","Model":"Paint","HwVer":"1.0","CompanyURI":"www.acme.com","MfgCert":"-----BEGIN CERTIFICATE-----MIIDSjCCAjKgAwIBAgIQRK+wgNajJ7qJMDmGLvhAazANBgkqhkiG9w0BAQUFADA/MSQwIgYDVQQKExtEaWdpdGFsIFNpZ25hdHVyZSBUcnVzdCBDby4xFzAVBgNVBAMTDkRTVCBSb290IENBIFgzMB4XDTAwMDkzMDIxMTIxOVoXDTIxMDkzMDE0MDExNVowPzEkMCIGA1UEChMbRGlnaXRhbCBTaWduYXR1cmUgVHJ1c3QgQ28uMRcwFQYDVQQDEw5EU1QgUm9vdCBDQSBYMzCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAN+v6ZdQCINXtMxiZfaQguzH0yxrMMpb7NnDfcdAwRgUi+DoM3ZJKuM/IUmTrE4Orz5Iy2Xu/NMhD2XSKtkyj4zl93ewEnu1lcCJo6m67XMuegwGMoOifooUMM0RoOEqOLl5CjH9UL2AZd+3UWODyOKIYepLYYHsUmu5ouJLGiifSKOeDNoJjj4XLh7dIN9bxiqKqy69cK3FCxolkHRyxXtqqzTWMIn/5WgTe1QLyNau7Fqckh49ZLOMxt+/yUFw7BZy1SbsOFU5Q9D8/RhcQPGX69Wam40dutolucbY38EVAjqr2m7xPi71XAicPNaDaeQQmxkqtilX4+U9m5/wAl0CAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMCAQYwHQYDVR0OBBYEFMSnsaR7LHH62+FLkHX/xBVghYkQMA0GCSqGSIb3DQEBBQUAA4IBAQCjGiybFwBcqR7uKGY3Or+Dxz9LwwmglSBd49lZRNI+DT69ikugdB/OEIKcdBodfpga3csTS7MgROSR6cz8faXbauX+5v3gTt23ADq1cEmv8uXrAvHRAosZy5Q6XkjEGB5YGV8eAlrwDPGxrancWYaLbumR9YbK+rlmM6pZW87ipxZzR8srzJmwN0jP41ZL9c8PDHIyh8bwRLtTcm1D9SZImlJnt1ir/md2cXjbDaJWFBM5JDGFoqgCWjBH4d1QB7wCCZAA62RjYJsWvIjJEubSfZGL+T0yjWW06XyxV3bqxbYoOb8VZRzI9neWagqNdwvYkQsEjgfbKbYK7p2CNTUQ-----END CERTIFICATE-----"}\', 0]'

      result = ModelInfo.Read(PaintModelId) 
      if str(result) != PaintData : 
         print("PaintData data does not match")
         print("Expect-> ", PaintData)
         print("Read-> ",   str(result))
         return False
      print("ModelInfo PaintData record read passes")


      contract = vtsvc.Contract(None, w3, "DeviceSecurity", "DeviceSecurity.sol:DeviceSecurity")
      DeviceSecurity = contract.ConciseContract

   
      SecurityDescription1 = '[\'{"ietf-mud:mud": {"mud-version": 1,"mud-url": "https://bms.example.com/.well-known/mud/lightbulb2001","last-update": "2018-01-24T16:08:58+01:00","cache-validity": 48,"is-supported": true,"systemSecurity": "The BMS Example Lightbulb","from-device-policy": {"access-lists": {"access-list": [{"name": "mud-61898-v6fr"}]}},"to-device-policy": {"access-lists": {"access-list": [{"name": "mud-61898-v6to"}]}}},"ietf-access-control-list:access-lists": {"acl": [{"name": "mud-61898-v6to","type": "ipv6-acl-type","aces": {"ace": [{"name": "cl0-todev","matches": {"l3": {"ipv6": {"ietf-acldns:src-dnsname": "service.bms.example.com","protocol": 6}},"l4": {"tcp": {"ietf-mud:direction-initiated": "from-device","source-port-range-or-operator": {"operator": "eq","port": 443}}}},"actions": {"forwarding": "accept"}}]}},{"name": "mud-61898-v6fr","type": "ipv6-acl-type","aces": {"ace": [{"name": "cl0-frdev","matches": {"l3": {"ipv6": {"ietf-acldns:dst-dnsname": "service.bms.example.com","protocol": 6}},"l4": {"tcp": {"ietf-mud:direction-initiated": "from-device","destination-port-range-or-operator": {"operator": "eq","port": 443}}}},"actions": {"forwarding": "accept"}}]}}]}}\', \'{"s1691":{"sec3a1AIaa_NIST_Defects":"NA","sec3a1AII_Upgradable":"True","sec3a1AIIIaa_NonDepricatedCommunicationProtocol":"True","sec3a1AIIIbb_NonDepreciatedEncryption":"True","sec3a1AIIIcc_NonDepricatedInterconnection":"True","sec3a1AIV_NoHardCodedCredentials":"True","sec3a1Eii_AnticipatedEndingSecuritySupprotDate":"1/1/2020"}}\', \'1.0\', \'www.acme.com/0x425fd133b04814563267cec46e360ef33a106f28/image.zip\']'

      MfgModelId = w3.toChecksumAddress("0xa8f77fc608378ed9961d71ac34fe23279a7c21e1")

      result = DeviceSecurity.Read(MfgModelId, 0)
      if str(result) != SecurityDescription1 : 
         print("SecurityDescription1 does not match")
         print("Expect-> ", SecurityDescription1)
         print("Read-> ",   str(result))
         return False
  

      print("DeviceSecurity read passes")
      return True

