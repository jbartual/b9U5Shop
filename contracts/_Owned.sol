pragma solidity ^0.4.4;

/* 

  Last update: 2018-02-06
  Version: 2.0

  Super Contract to add manage the ownership of a contract.

  Modifiers:
  - onlyOwner

  Core functions:
  - Constructor
  - changeOwner
  - confirmChangeOwner

  Support functions:
  - getInfoOwner
  - getInfoNewOwner

*/

contract Owned {
    address private owner;
    address private newOwner;

    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }

// CORE functions

        event LogOwnedNew (address _sender);
        // Constructor
    function Owned ()
        public
    {
        owner = msg.sender;
        LogOwnedNew(msg.sender);
    }

        event LogOwnedChangeOwner (address _sender, address _newOwner);
        // 2-step ownership transfer function
        // This is the first step where the original owner requests the transfer
    function changeOwner(address _newOwner)
        onlyOwner
        public
        returns(bool _success)
    {
        require(_newOwner != 0);

        newOwner = _newOwner;
        LogOwnedChangeOwner(msg.sender, _newOwner);
        return true;
    }

        event LogOwnedConfirmChangeOwner (address _sender, address _newOwner);
        // 2-step ownership transfer function
        // This is the second step where the new  owner confirms the transfer
    function confirmChangeOwner()
        public
        returns(bool _success)
    {
        require(msg.sender == newOwner); //ensure the sender is the correct address

        owner = newOwner;
        delete newOwner;

        LogOwnedConfirmChangeOwner(msg.sender, newOwner);
        return true;
    }

// SUPPORT functions    

    function getInfoOwner()
        constant
        public
        returns (address _owner)
    {
        return owner;
    }

    function getInfoNewOwner()
        constant
        public
        returns (address _newOwner)
    {
        return newOwner;
    }   
}