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

contract ModelInfo 
{
  uint constant MaxAdminList      = 5;
  uint constant MaxMediatorList   = 5;
  // Mediation States
  uint constant MediationStateNormal            = 0;
  uint constant MediationStateInMediation       = 1;
  uint constant MediationStateReadyForNewAdmin  = 2;
  
  struct ModelStruct{
    address  [MaxAdminList]     AdminList;
    address  [MaxMediatorList]  MediatorList;
    address  [MaxMediatorList]  MediatorNewAdminList;
    uint                        MediationState;
    string                      Data;
    address []                  Component;
  }
  mapping (address => ModelStruct) ModelTable;

  function ModelInfo() public
  {
  }
  
  function VerifyAdminId(address ModelIndex, address UserId) public constant returns (bool Match)
  {
    for (uint Loop = 0; Loop < MaxAdminList; Loop ++)
    {
      if (ModelTable[ModelIndex].AdminList[Loop] == UserId)
      {
        Match = true;
        return;
      }
    }
    Match = false;
    return;
  }
  
  function Write (address ModelIndex, string Data) public returns (bool Status)
  {
    if (!VerifyAdminId(ModelIndex, msg.sender))
    {
      Status = false;
      return;
    }
    
    ModelTable[ModelIndex].Data = Data;
  }
  
  function Read (address ModelIndex) public constant returns (string Data, uint ComponentCount)
  {
    Data = ModelTable[ModelIndex].Data;
    ComponentCount = ModelTable[ModelIndex].Component.length;
    return;
  }
  
  function WriteComponent(address ModelIndex, address Component) public returns (bool Status)
  {
    if (!VerifyAdminId(ModelIndex, msg.sender))
    {
      Status = false;
      return;
    }
    ModelTable[ModelIndex].Component.push(Component);
    Status = true;
    return;
  }
  
  function ReadComponent(address ModelIndex, uint ComponentIndex) public constant returns (address Component)
  {
    Component = ModelTable[ModelIndex].Component[ComponentIndex];
    return;
  }
  
  function DeleteComponent(address ModelIndex, address Component) public returns (bool Status)
  {
    uint Loop;
    uint MatchIndex;
    bool MatchFound;

    // If record is not owned by the msg.sender, then exit
    if (!VerifyAdminId(ModelIndex, msg.sender))
    {
      Status = false;
      return;
    }
    
    Loop = 0;
    MatchIndex = 0;
    MatchFound = false;
    
    while (Loop < ModelTable[ModelIndex].Component.length)
    {
      // If the Value in the list == requested delete value,
      // Then copy all other items
      if (ModelTable[ModelIndex].Component[Loop] == Component)
      {
        MatchFound = true;
        MatchIndex = Loop;
        ModelTable[ModelIndex].Component[Loop] = 0;
      }
      
      if (MatchFound)
      {
        // Do not copy beyond end of list
        if (Loop < (ModelTable[ModelIndex].Component.length - 1))
        {
          ModelTable[ModelIndex].Component[Loop] = ModelTable[ModelIndex].Component[Loop + 1];
        }
      }
      Loop = Loop + 1;
    }
    if (MatchFound)
    {
      ModelTable[ModelIndex].Component.length --;
      Status = true;
    }
    else
    {
      Status = false;
    }
    return;
  }
  
  function VerifyUnclaimedAdmin(address ModelIndex) public constant returns (bool Match)
  {
    Match = true;
    for (uint Loop = 0; Loop < MaxAdminList; Loop ++)
    {
      if (ModelTable[ModelIndex].AdminList[Loop] != 0)
      {
        Match = false;
        return;
      }
    }
    return;
  }
  
  function WriteAdmin(address ModelIndex, uint Index, address AdminId) public returns (bool Status)
  {
    if (!VerifyAdminId(ModelIndex, msg.sender) || (Index > MaxAdminList))
    {
      if (!VerifyUnclaimedAdmin(ModelIndex))
      {
        Status = false;
        return;
      }
    }
  
    ModelTable[ModelIndex].AdminList[Index] = AdminId;
    Status = true;
    return;
  }

  function ReadAdminList(address ModelIndex) public constant returns (address [MaxAdminList] ReturnList)
  {
    ReturnList = ModelTable[ModelIndex].AdminList;
    return;
  }

  function WriteMediator(address ModelIndex, uint Index, address MediatorId) public returns (bool Status)
  {
    if (!VerifyAdminId(ModelIndex, msg.sender) || (Index > MaxMediatorList))
    {
      Status = false;
      return;
    }
  
    ModelTable[ModelIndex].MediatorList[Index] = MediatorId;
    Status = true;
    return;
  }

  function ReadMediatorList(address ModelIndex) public constant returns (address [MaxMediatorList] ReturnMediatorList)
  {
    ReturnMediatorList = ModelTable[ModelIndex].MediatorList;
  }

  function ReadMediatorAdminList(address ModelIndex) public constant returns (address [MaxMediatorList] ReturnAdminList)
  {
    ReturnAdminList = ModelTable[ModelIndex].MediatorNewAdminList;
    return;
  }
  
  function ReadMediationState(address ModelIndex) public constant returns (uint ReturnMediationState)
  {
    ReturnMediationState = ModelTable[ModelIndex].MediationState;
    return;
  }
  
  
  function WriteMediatorAdmin(address ModelIndex, uint Index, address AdminId) public returns (bool Status)
  {
    // If the sender does not own this index, then exit
    if ((ModelTable[ModelIndex].MediatorList[Index] != msg.sender) || (Index > MaxMediatorList))
    {
      Status = false;
      return;
    }
  
    // Update NewAdminList
    ModelTable[ModelIndex].MediatorNewAdminList[Index] = AdminId;
  
    // If we are in Normal Operation, then move to Mediation
    if (ModelTable[ModelIndex].MediationState == MediationStateNormal)
    {
      ModelTable[ModelIndex].MediationState = MediationStateInMediation;
    }
  
    // If we are in mediation, then see if we are ready to exit
    if (ModelTable[ModelIndex].MediationState == MediationStateInMediation)
    {
      bool ReadyForNewState = true;
      address NewAdminId = 0;
      for (uint Loop = 0; Loop < MaxMediatorList; Loop++)
      {
        if (ModelTable[ModelIndex].MediatorList[Loop] != 0)
        {
          // If this is the first time we have a valid Admin, then init the NewAdminId
          if (NewAdminId == 0)
          {
            NewAdminId = ModelTable[ModelIndex].MediatorNewAdminList[Loop];
          }
        
          // If the NewAdminId != the Admin assigned from the mediator, then stay in mediation
          if (NewAdminId != ModelTable[ModelIndex].MediatorNewAdminList[Loop])
          {
            ReadyForNewState = false;
          }
        }
      }
    
      if ((NewAdminId != 0) && (ReadyForNewState))
      {
        ModelTable[ModelIndex].MediationState = MediationStateReadyForNewAdmin;
      }
    }    
  
    Status = true;
    return;
  }

  function ExitMediationState(address ModelIndex) public returns (bool Status)
  {
    // Exit if we are not in ReadForNewAdmin
    if (ModelTable[ModelIndex].MediationState != MediationStateReadyForNewAdmin)
    {
      Status = false;
      return;
    }
  
    bool SenderIdMatch = true;
    uint MediatorCount = 0;
    for (uint Loop = 0; Loop < MaxMediatorList; Loop++)
    {
      // All Valid Mediators must point to the sender's ID
      if (ModelTable[ModelIndex].MediatorList[Loop] != 0)
      {
        MediatorCount = MediatorCount + 1;
        // If the NewAdminId != the Admin assigned from the mediator, then stay in mediation
        if (msg.sender != ModelTable[ModelIndex].MediatorNewAdminList[Loop])
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
      ModelTable[ModelIndex].AdminList[0] = msg.sender;
      for (Loop = 1; Loop < MaxAdminList; Loop ++)
      {
        ModelTable[ModelIndex].AdminList[Loop] = 0;
      }
      for (Loop = 0; Loop < MaxMediatorList; Loop++)
      {
        ModelTable[ModelIndex].MediatorNewAdminList[Loop] = 0;
      }
      ModelTable[ModelIndex].MediationState = MediationStateNormal;
    }

    Status = true;
    return;
  }

  function ImportAdminModelInfo(address ModelIndex, uint Index, address AdminId, string Data) public returns (bool Status)
  {
    Status = WriteAdmin(ModelIndex, Index, AdminId);
    Status = Write (ModelIndex, Data);
    return;
  }

}

