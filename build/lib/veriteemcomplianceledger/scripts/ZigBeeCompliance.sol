//***********************************************************************************
// Copyright 2018 Verimatrix
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of 
// this software and associated documentation files (the "Software"), to deal in the 
// Software without restriction, including without limitation the rights to use, copy, 
// modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, 
// and to permit persons to whom the Software is furnished to do so, subject to 
// the following conditions:
//
// The above copyright notice and this permission notice shall be included in all 
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
// INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
// PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION 
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
// SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//***********************************************************************************


pragma solidity ^0.4.8;

contract ZigBeeCompliance
{
  
  // List size constants
  uint constant MaxAdminList      = 5;
  uint constant MaxTesterList  = 5;
  uint constant MaxMediatorList   = 3;
  
  // Mediation States
  uint constant MediationStateNormal            = 0;
  uint constant MediationStateInMediation       = 1;
  uint constant MediationStateReadyForNewAdmin  = 2;

  // Admin variables
  address [MaxAdminList]      AdminList;
  address [MaxTesterList]  TesterList;
  address [MaxMediatorList]   MediatorList;
  address [MaxMediatorList]   MediatorNewAdminList;
  uint                        MediationState;
  
  // Compliance records
  address [] ModelList;
  struct FamilyTableStruct{
    string      FamilyString;
    bool        Valid;
    address     ComplianceId;
    address []  SubAddress;
    string  []  SubFamilyString;
    address []  SubComplianceId;
  }
  mapping (address => FamilyTableStruct) FamilyTable;  

  mapping (address => address) ComplianceIdMap;
    
  struct ComplianceStruct{
    address   MfgModelId;
    address   Tester;
    address   MfgCertHash;
    string    ExpirationDate;
    string    ComplianceData;
    bool      Valid;
  }
  mapping (address => ComplianceStruct) ComplianceArray;  
    

  constructor() public
  {
    AdminList[0] = msg.sender;
    MediationState = MediationStateNormal;
  }

  // *****************************************************************************
  // Contract administration list management
  // *****************************************************************************
  function VerifyAdminId(address UserId) private constant returns (bool Match)
  {
    for (uint Loop = 0; Loop < MaxAdminList; Loop ++)
    {
      if (AdminList[Loop] == UserId)
      {
        Match = true;
        return;
      }
    }
    Match = false;
    return;
  }

  function VerifyTesterId(address UserId) private constant returns (bool Match)
  {
    for (uint Loop = 0; Loop < MaxAdminList; Loop ++)
    {
      if (TesterList[Loop] == UserId)
      {
        Match = true;
        return;
      }
    }
    Match = false;
    return;
  }

  function WriteAdmin(uint Index, address AdminId) public returns (bool Status)
  {
    if (!VerifyAdminId(msg.sender) || (Index > MaxAdminList))
    {
      Status = false;
      return;
    }
  
    AdminList[Index] = AdminId;
    Status = true;
    return;
  }

  function ReadAdminList() public constant returns (address [MaxAdminList] ReturnList)
  {
    ReturnList = AdminList;
    return;
  }

  function WriteTester(uint Index, address TesterId) public returns (bool Status)
  {
    if (!VerifyAdminId(msg.sender) || (Index > MaxAdminList))
    {
      Status = false;
      return;
    }
  
    TesterList[Index] = TesterId;
    Status = true;
    return;
  }

  function ReadTesterList() public constant returns (address [MaxTesterList] ReturnList)
  {
    ReturnList = TesterList;
    return;
  }

  // *****************************************************************************
  // Contract Mediation management
  // *****************************************************************************
  function WriteMediator(uint Index, address MediatorId) public returns (bool Status)
  {
    if (!VerifyAdminId(msg.sender) || (Index > MaxMediatorList))
    {
      Status = false;
      return;
    }
  
    MediatorList[Index] = MediatorId;
    Status = true;
    return;
  }

  function ReadMediatorList() public constant returns (address [MaxMediatorList] ReturnMediatorList)
  {
    ReturnMediatorList = MediatorList;
  }

  function ReadMediatorAdminList() public constant returns (address [MaxMediatorList] ReturnAdminList)
  {
    ReturnAdminList = MediatorNewAdminList;
    return;
  }
  
  function ReadMediationState() public constant returns (uint ReturnMediationState)
  {
    ReturnMediationState = MediationState;
    return;
  }
  
  
  function WriteMediatorAdmin(uint Index, address AdminId) public returns (bool Status)
  {
    // If the sender does not own this index, then exit
    if ((MediatorList[Index] != msg.sender) || (Index > MaxMediatorList))
    {
      Status = false;
      return;
    }
  
    // Update NewAdminList
    MediatorNewAdminList[Index] = AdminId;
  
    // If we are in Normal Operation, then move to Mediation
    if (MediationState == MediationStateNormal)
    {
      MediationState = MediationStateInMediation;
    }
  
    // If we are in mediation, then see if we are ready to exit
    if (MediationState == MediationStateInMediation)
    {
      bool ReadyForNewState = true;
      address NewAdminId = 0;
      for (uint Loop = 0; Loop < MaxMediatorList; Loop++)
      {
        if (MediatorList[Loop] != 0)
        {
          // If this is the first time we have a valid Admin, then init the NewAdminId
          if (NewAdminId == 0)
          {
            NewAdminId = MediatorNewAdminList[Loop];
          }
        
          // If the NewAdminId != the Admin assigned from the mediator, then stay in mediation
          if (NewAdminId != MediatorNewAdminList[Loop])
          {
            ReadyForNewState = false;
          }
        }
      }
    
      if ((NewAdminId != 0) && (ReadyForNewState))
      {
        MediationState = MediationStateReadyForNewAdmin;
      }
    }    
  
    Status = true;
    return;
  }

  function ExitMediationState() public returns (bool Status)
  {
    // Exit if we are not in ReadForNewAdmin
    if (MediationState != MediationStateReadyForNewAdmin)
    {
      Status = false;
      return;
    }
  
    bool SenderIdMatch = true;
    uint MediatorCount = 0;
    for (uint Loop = 0; Loop < MaxMediatorList; Loop++)
    {
      // All Valid Mediators must point to the sender's ID
      if (MediatorList[Loop] != 0)
      {
        MediatorCount = MediatorCount + 1;
        // If the NewAdminId != the Admin assigned from the mediator, then stay in mediation
        if (msg.sender != MediatorNewAdminList[Loop])
        {
          SenderIdMatch = false;
        }
      }
    }
  
    // If the sender is the ID set by the mediators, then
    // Assign the Admin List to the sender
    // Clear all other Admins
    // Clear the Mediator New Admin List
    // Reset mediation state to Normal
    
    if (SenderIdMatch && (MediatorCount > 1))
    {
      AdminList[0] = msg.sender;
      for (Loop = 1; Loop < MaxAdminList; Loop ++)
      {
        AdminList[Loop] = 0;
      }
      for (Loop = 0; Loop < MaxMediatorList; Loop++)
      {
        MediatorNewAdminList[Loop] = 0;
      }
      MediationState = MediationStateNormal;
    }

    Status = true;
    return;
  }

  //*************************************************************************
  // Model List Management
  // The model list is used as a shortcut such that all registered models
  // can easily be indexed.
  //*************************************************************************
  
  function ModelListCount() public constant returns (uint Count)
  {
    Count = ModelList.length;
    return;
  }

  function ReadModelList(uint Index) public constant returns (address ComplianceModelId)
  {
    ComplianceModelId = ModelList[Index];
    return;
  }

  //*************************************************************************
  // Core compliance functions: Write, Read, Delete, Valid
  //*************************************************************************
  function WriteValid(address ComplianceModelId, bool Valid) public returns (bool Status)
  {
    // If record is not owned by the msg.sender, then exit
    if ((!VerifyAdminId(msg.sender)) || (ComplianceArray[ComplianceModelId].MfgModelId == 0))
    {
      Status = false;
      return;
    }
    ComplianceArray[ComplianceModelId].Valid = Valid;
    Status = true;
    return;
  }
  
  function Write(address ComplianceModelId, address MfgModelId, string ExpirationDate, string ComplianceData, address MfgCertHash) public returns (bool Status)
  {
    // If record is not owned by the msg.sender, then exit
    if (!VerifyTesterId(msg.sender))
    {
      Status = false;
      return;
    }

    // If ModelId not already registered, then add to the ModelList
    if (ComplianceArray[ComplianceModelId].MfgModelId == 0)
    {
      ModelList.push(ComplianceModelId);
    }

    ComplianceArray[ComplianceModelId].MfgModelId = MfgModelId;
    ComplianceArray[ComplianceModelId].ExpirationDate = ExpirationDate;
    ComplianceArray[ComplianceModelId].ComplianceData = ComplianceData;
    ComplianceArray[ComplianceModelId].Tester = msg.sender;
    ComplianceArray[ComplianceModelId].MfgCertHash = MfgCertHash;
    
    ComplianceIdMap[MfgModelId] = ComplianceModelId;
    
    if (VerifyAdminId(msg.sender))
      ComplianceArray[ComplianceModelId].Valid = true;
    else
      ComplianceArray[ComplianceModelId].Valid = false;
    
    Status = true;
    return;
  }
  
  // ***************************************************************************
  // The Delete function will reset the contents of the ComplainceArray,
  // and clean up the ModelList.
  // However, this function should not be used too often as it is expensive
  // to sort the ModelList.
  //
  // The prefered manor to remove a certification should be the clearing
  // on the ComplianceArray, and leave the ModelList point to the empty record.
  // ***************************************************************************
  function Delete(address ComplianceModelId) public returns (bool Status)
  {
    uint Loop;
    uint MatchIndex;
    bool MatchFound;

    // If record is not owned by the msg.sender, then exit
    if (!VerifyAdminId(msg.sender))
    {
      Status = false;
      return;
    }
    
    Loop = 0;
    MatchIndex = 0;
    MatchFound = false;
    
    while (Loop < ModelList.length)
    {
      // If the Value in the list == requested delete value,
      // Then copy all other items
      if (ModelList[Loop] == ComplianceModelId)
      {
        MatchFound = true;
        MatchIndex = Loop;
        ComplianceIdMap[ComplianceArray[ComplianceModelId].MfgModelId] = 0;
        
        ComplianceArray[ComplianceModelId].Tester = msg.sender;
        ComplianceArray[ComplianceModelId].MfgModelId = 0;
        ComplianceArray[ComplianceModelId].ExpirationDate = "";
        ComplianceArray[ComplianceModelId].ComplianceData = "";
        ComplianceArray[ComplianceModelId].Valid = false;
        ComplianceArray[ComplianceModelId].MfgCertHash = 0;
        
      }
      
      if (MatchFound)
      {
        // Do not copy beyond end of list
        if (Loop < (ModelList.length - 1))
        {
          ModelList[Loop] = ModelList[Loop + 1];
        }
      }
      Loop = Loop + 1;
    }
    if (MatchFound)
    {
      ModelList.length --;
      Status = true;
    }
    else
    {
      Status = false;
    }
    return;
  }

//  function Read(address ComplianceModelId, address MfgContract) public constant returns (ComplianceStruct RtnCompliance)
  function Read(address ComplianceModelId) public constant returns (address Tester, address MfgModelId, string ExpirationDate, string ComplianceData, bool Valid, address MfgCertHash)
  {
    // return Compliance record
    Tester       = ComplianceArray[ComplianceModelId].Tester;
    MfgModelId      = ComplianceArray[ComplianceModelId].MfgModelId;
    ExpirationDate  = ComplianceArray[ComplianceModelId].ExpirationDate;
    ComplianceData  = ComplianceArray[ComplianceModelId].ComplianceData;
    Valid           = ComplianceArray[ComplianceModelId].Valid;
    MfgCertHash     = ComplianceArray[ComplianceModelId].MfgCertHash;

    // return MfgRecord?
    return;
  }
  
  function ReadComplianceId(address MfgModelId) public constant returns (address ComplianceId)
  {
    ComplianceId = ComplianceIdMap[MfgModelId];
    return;
  }
  
  function Valid(address ComplianceModelId) public constant returns (bool Status)
  {
    if ((ComplianceArray[ComplianceModelId].MfgModelId != 0) && (ComplianceArray[ComplianceModelId].Valid))
      Status = true;
    else
      Status = false;
      
    return;
  }  
  
  function CalcComplianceId(string FamilyString) public pure returns (address FamilyIndex)
  {
    bytes32 Family;
    
    Family = keccak256(FamilyString);
    FamilyIndex = address(Family);
    return;
    
  }
  
  function WriteFamily(string FamilyString, bool FamilyValid, address ComplianceId) public returns (bool Status)
  {
    address FamilyIndex;
    
    if (!VerifyAdminId(msg.sender))
    {
      Status = false;
      return;
    }

    FamilyIndex = CalcComplianceId(FamilyString);
    FamilyTable[FamilyIndex].FamilyString = FamilyString;
    FamilyTable[FamilyIndex].Valid = FamilyValid;
    FamilyTable[FamilyIndex].ComplianceId = ComplianceId;
    Status = true;
    return;
  }
  
  function ReadFamily(string FamilyString) public constant returns (address FamilyIndex, bool FamilyValid, uint SubCount, address ComplianceId)
  {
    FamilyIndex = CalcComplianceId(FamilyString);
    FamilyString = FamilyTable[FamilyIndex].FamilyString;
    FamilyValid = FamilyTable[FamilyIndex].Valid;
    SubCount = FamilyTable[FamilyIndex].SubAddress.length;
    ComplianceId = FamilyTable[FamilyIndex].ComplianceId;
    //SubAddress = FamilyTable[FamilyIndex].SubAddress[0];
  //  SubString = FamilyTable[FamilyIndex].SubFamilyString;
    return;
  }
  
  function ReadFamilyIndex(address FamilyIndex) public constant returns (string FamilyString, uint SubCount, address ComplianceId)
  {
    FamilyString = FamilyTable[FamilyIndex].FamilyString;
    SubCount = FamilyTable[FamilyIndex].SubAddress.length;
    ComplianceId = FamilyTable[FamilyIndex].ComplianceId;
    //SubAddress = FamilyTable[FamilyIndex].SubAddress[0];
  //  SubString = FamilyTable[FamilyIndex].SubFamilyString;
    return;
  }
  
  
  function ReadSubFamilyIndex(string FamilyString, uint SubFamilyIndex) public constant returns (address SubAddress, string SubString, address SubComplianceId)
  {
    address FamilyIndex;
    
    FamilyIndex = CalcComplianceId(FamilyString);
    SubAddress = FamilyTable[FamilyIndex].SubAddress[SubFamilyIndex];
    SubString = FamilyTable[FamilyIndex].SubFamilyString[SubFamilyIndex];
    SubComplianceId = FamilyTable[FamilyIndex].SubComplianceId[SubFamilyIndex];
    return;
  }
  
  
  
  function WriteSubFamily(string FamilyString, string SubFamilyString, address SubComplianceId) public returns (bool Status)
  {
    address FamilyIndex;
    address SubFamilyIndex;
    uint  Loop;
    
    if (!VerifyAdminId(msg.sender))
    {
      Status = false;
      return;
    }

    Status = false;
    Loop = 0;

    FamilyIndex = CalcComplianceId(FamilyString);
    SubFamilyIndex = CalcComplianceId(SubFamilyString);

    while (!Status && (Loop < FamilyTable[FamilyIndex].SubAddress.length))
    {
      if (FamilyTable[FamilyIndex].SubAddress[Loop] == SubFamilyIndex)
      {
        Status = true;
        return;
      }
      Loop = Loop + 1;
    }
    
    FamilyTable[FamilyIndex].SubAddress.push(SubFamilyIndex);
    FamilyTable[FamilyIndex].SubFamilyString.push(SubFamilyString);
    FamilyTable[FamilyIndex].SubComplianceId.push(SubComplianceId);
      
    return;
        
  }
  
  // Cert, Name, Model, HwVer, FwVer
  function WriteFamilyTree(string FamilyStringC, string FamilyStringCN, string FamilyStringCNM, string FamilyStringCNMH, string FamilyStringCNMHF, address ComplianceId) public returns (bool Status)
  {
    if (!VerifyAdminId(msg.sender))
    {
      Status = false;
      return;
    }

    if (bytes(FamilyStringCNMHF).length > 0)
    {
      // CNMHF
      WriteFamily(FamilyStringCNMHF, true, ComplianceId);
      WriteSubFamily(FamilyStringCNMH, FamilyStringCNMHF, ComplianceId);
    }
    if (bytes(FamilyStringCNMH).length > 0)
    {
      // MMHF
      WriteFamily(FamilyStringCNMH, true, 0);
      WriteSubFamily(FamilyStringCNM, FamilyStringCNMH, 0);
    }
    if (bytes(FamilyStringCNM).length > 0)
    {
      // MMHF
      WriteFamily(FamilyStringCNM, true, 0);
      WriteSubFamily(FamilyStringCN, FamilyStringCNM, 0);
    }

    if (bytes(FamilyStringCN).length > 0)
    {
      // MMHF
      WriteFamily(FamilyStringCN, true, 0);
      WriteSubFamily(FamilyStringC, FamilyStringCN, 0);
    }
      
    if (bytes(FamilyStringC).length > 0)
    {
      // MMHF
      WriteFamily(FamilyStringC, true, 0);
    }
      
    Status = true;
    return;
    
  }
  
  function DeleteSubFamily(string FamilyString, string SubFamilyString) public returns (bool Status)
  {
    uint Loop;
    uint MatchIndex;
    bool MatchFound;
    address FamilyIndex;
    address SubFamilyIndex;

    // If record is not owned by the msg.sender, then exit
    if (!VerifyAdminId(msg.sender))
    {
      Status = false;
      return;
    }
    
    Loop = 0;
    MatchIndex = 0;
    MatchFound = false;
    
    FamilyIndex = CalcComplianceId(FamilyString);
    SubFamilyIndex = CalcComplianceId(SubFamilyString);

    
    while (Loop < FamilyTable[FamilyIndex].SubAddress.length)
    {
      // If the Value in the list == requested delete value,
      // Then copy all other items
      if (FamilyTable[FamilyIndex].SubAddress[Loop] == SubFamilyIndex)
      {
        MatchFound = true;
        MatchIndex = Loop;
        FamilyTable[FamilyIndex].SubAddress[Loop] = 0;
        FamilyTable[FamilyIndex].SubFamilyString[Loop] = "";
        FamilyTable[FamilyIndex].SubComplianceId[Loop] = 0;
      }
      
      if (MatchFound)
      {
        // Do not copy beyond end of list
        if (Loop < (FamilyTable[FamilyIndex].SubAddress.length - 1))
        {
          FamilyTable[FamilyIndex].SubAddress[Loop] = FamilyTable[FamilyIndex].SubAddress[Loop + 1];
          FamilyTable[FamilyIndex].SubFamilyString[Loop] = FamilyTable[FamilyIndex].SubFamilyString[Loop + 1];
          FamilyTable[FamilyIndex].SubComplianceId[Loop] = FamilyTable[FamilyIndex].SubComplianceId[Loop + 1];
        }
      }
      Loop = Loop + 1;
    }
    if (MatchFound)
    {
      FamilyTable[FamilyIndex].SubAddress.length --;
      FamilyTable[FamilyIndex].SubFamilyString.length --;
      FamilyTable[FamilyIndex].SubComplianceId.length --;
      Status = true;
    }
    else
    {
      Status = false;
    }
    return;
  }
  
  function ImportTreeModelSku(string FamilyStringC, string FamilyStringCN, string ModelFamilyStringCNM, string ModelFamilyStringCNMH, 
                  string ModelFamilyStringCNMHF, 
                  string SkuFamilyStringCNM, string SkuFamilyStringCNMH, string SkuFamilyStringCNMHF,
                  address ComplianceId) 
                  public returns (bool Status)
  {
    if (!VerifyAdminId(msg.sender))
    {
      Status = false;
      return;
    }
    Status = WriteFamilyTree(FamilyStringC, FamilyStringCN, ModelFamilyStringCNM, ModelFamilyStringCNMH, ModelFamilyStringCNMHF, ComplianceId);
    Status = WriteFamilyTree(FamilyStringC, FamilyStringCN, SkuFamilyStringCNM, SkuFamilyStringCNMH, SkuFamilyStringCNMHF, ComplianceId);
    return Status;

  }

}

