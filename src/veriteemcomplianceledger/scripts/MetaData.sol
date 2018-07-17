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

contract MetaData 
{
  uint constant MaxAdminList      = 5;
  uint constant MaxMediatorList   = 5;
  // Mediation States
  uint constant MediationStateNormal            = 0;
  uint constant MediationStateInMediation       = 1;
  uint constant MediationStateReadyForNewAdmin  = 2;
  
  struct DeviceStruct{
    address  [MaxAdminList]     AdminList;
    address  [MaxMediatorList]  MediatorList;
    address  [MaxMediatorList]  MediatorNewAdminList;
    uint                        MediationState;
    string  []                  Tag;
    string  []                  Data;
  }
  mapping (address => DeviceStruct) DeviceTable;

  constructor() public
  {
  }
  
  function VerifyAdminId(address DeviceIndex, address UserId) public constant returns (bool Match)
  {
    for (uint Loop = 0; Loop < MaxAdminList; Loop ++)
    {
      if (DeviceTable[DeviceIndex].AdminList[Loop] == UserId)
      {
        Match = true;
        return;
      }
    }
    Match = false;
    return;
  }
  
  function Write(address ModelId, string Tag, string Data) public returns (bool Status)
  {
    if (!VerifyAdminId(ModelId, msg.sender))
    {
      Status = false;
      return;
    }
    
    DeviceTable[ModelId].Tag.push(Tag);
    DeviceTable[ModelId].Data.push(Data);
    Status = true;
    return;
  }
  
  
  function Read (address ModelId, uint Index) public constant returns (string Tag, string Data)
  {
    Tag = DeviceTable[ModelId].Tag[Index];
    Data = DeviceTable[ModelId].Data[Index];
    return;
  }
  
  function ReadCount(address DeviceIndex) public constant returns (uint Count)
  {
    Count = DeviceTable[DeviceIndex].Tag.length;
    return;
  }
  
  function Delete(address ModelId) public returns (bool Status)
  {
    //uint Loop;

    // If record is not owned by the msg.sender, then exit
    if (!VerifyAdminId(ModelId, msg.sender))
    {
      Status = false;
      return;
    }
    
    DeviceTable[ModelId].Tag.length --;
    DeviceTable[ModelId].Data.length --;
      
    Status = true;
    return;
  }
  
  function VerifyUnclaimedAdmin(address DeviceIndex) public constant returns (bool Match)
  {
    Match = true;
    for (uint Loop = 0; Loop < MaxAdminList; Loop ++)
    {
      if (DeviceTable[DeviceIndex].AdminList[Loop] != 0)
      {
        Match = false;
        return;
      }
    }
    return;
  }
  
  function WriteAdmin(address DeviceIndex, uint Index, address AdminId) public returns (bool Status)
  {
    if (!VerifyAdminId(DeviceIndex, msg.sender) || (Index > MaxAdminList))
    {
      if (!VerifyUnclaimedAdmin(DeviceIndex))
      {
        Status = false;
        return;
      }
    }
  
    DeviceTable[DeviceIndex].AdminList[Index] = AdminId;
    Status = true;
    return;
  }

  function ReadAdminList(address DeviceIndex) public constant returns (address [MaxAdminList] ReturnList)
  {
    ReturnList = DeviceTable[DeviceIndex].AdminList;
    return;
  }

  function WriteMediator(address DeviceIndex, uint Index, address MediatorId) public returns (bool Status)
  {
    if (!VerifyAdminId(DeviceIndex, msg.sender) || (Index > MaxMediatorList))
    {
      Status = false;
      return;
    }
  
    DeviceTable[DeviceIndex].MediatorList[Index] = MediatorId;
    Status = true;
    return;
  }

  function ReadMediatorList(address DeviceIndex) public constant returns (address [MaxMediatorList] ReturnMediatorList)
  {
    ReturnMediatorList = DeviceTable[DeviceIndex].MediatorList;
  }

  function ReadMediatorAdminList(address DeviceIndex) public constant returns (address [MaxMediatorList] ReturnAdminList)
  {
    ReturnAdminList = DeviceTable[DeviceIndex].MediatorNewAdminList;
    return;
  }
  
  function ReadMediationState(address DeviceIndex) public constant returns (uint ReturnMediationState)
  {
    ReturnMediationState = DeviceTable[DeviceIndex].MediationState;
    return;
  }
  
  
  function WriteMediatorAdmin(address DeviceIndex, uint Index, address AdminId) public returns (bool Status)
  {
    // If the sender does not own this index, then exit
    if ((DeviceTable[DeviceIndex].MediatorList[Index] != msg.sender) || (Index > MaxMediatorList))
    {
      Status = false;
      return;
    }
  
    // Update NewAdminList
    DeviceTable[DeviceIndex].MediatorNewAdminList[Index] = AdminId;
  
    // If we are in Normal Operation, then move to Mediation
    if (DeviceTable[DeviceIndex].MediationState == MediationStateNormal)
    {
      DeviceTable[DeviceIndex].MediationState = MediationStateInMediation;
    }
  
    // If we are in mediation, then see if we are ready to exit
    if (DeviceTable[DeviceIndex].MediationState == MediationStateInMediation)
    {
      bool ReadyForNewState = true;
      address NewAdminId = 0;
      for (uint Loop = 0; Loop < MaxMediatorList; Loop++)
      {
        if (DeviceTable[DeviceIndex].MediatorList[Loop] != 0)
        {
          // If this is the first time we have a valid Admin, then init the NewAdminId
          if (NewAdminId == 0)
          {
            NewAdminId = DeviceTable[DeviceIndex].MediatorNewAdminList[Loop];
          }
        
          // If the NewAdminId != the Admin assigned from the mediator, then stay in mediation
          if (NewAdminId != DeviceTable[DeviceIndex].MediatorNewAdminList[Loop])
          {
            ReadyForNewState = false;
          }
        }
      }
    
      if ((NewAdminId != 0) && (ReadyForNewState))
      {
        DeviceTable[DeviceIndex].MediationState = MediationStateReadyForNewAdmin;
      }
    }    
  
    Status = true;
    return;
  }

  function ExitMediationState(address DeviceIndex) public returns (bool Status)
  {
    // Exit if we are not in ReadForNewAdmin
    if (DeviceTable[DeviceIndex].MediationState != MediationStateReadyForNewAdmin)
    {
      Status = false;
      return;
    }
  
    bool SenderIdMatch = true;
    uint MediatorCount = 0;
    for (uint Loop = 0; Loop < MaxMediatorList; Loop++)
    {
      // All Valid Mediators must point to the sender's ID
      if (DeviceTable[DeviceIndex].MediatorList[Loop] != 0)
      {
        MediatorCount = MediatorCount + 1;
        // If the NewAdminId != the Admin assigned from the mediator, then stay in mediation
        if (msg.sender != DeviceTable[DeviceIndex].MediatorNewAdminList[Loop])
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
      DeviceTable[DeviceIndex].AdminList[0] = msg.sender;
      for (Loop = 1; Loop < MaxAdminList; Loop ++)
      {
        DeviceTable[DeviceIndex].AdminList[Loop] = 0;
      }
      for (Loop = 0; Loop < MaxMediatorList; Loop++)
      {
        DeviceTable[DeviceIndex].MediatorNewAdminList[Loop] = 0;
      }
      DeviceTable[DeviceIndex].MediationState = MediationStateNormal;
    }

    Status = true;
    return;
  }



}

