pragma solidity ^0.4.4;

/* 

  Last update: 2018-02-06
  Version: 2.0

  Super Contract to add Stop and Resume functionality to a child contract:
  - The 'onlyIfRunning' modifier allows children contracts to check for the running status
  - Stopped contracts shall prevent any state-changing functions to be executed
  - Only owner/administrators shall stop/resume contracts

  Modifiers:
  - onlyIfRunning

  Core functions:
  - Constructor
  - stopContract
  - resumeContract

  Support functions:
  - isStopped

*/

import "./_Owned.sol";

contract Stoppable is Owned {
    bool private stop;

    modifier onlyIfRunning () { require (!stop); _; }

// CORE functions

        event LogStoppableNew (address _sender);
    function Stoppable ()
        public
    {
        LogStoppableNew (msg.sender);
    }

        event LogStoppableStopContract (address _sender);
        // Function to soft stop the contract
    function stopContract ()
        onlyOwner
        public
        returns (bool _success)
    {
        stop = true;

        LogStoppableStopContract (msg.sender);
        return true;
    }

        event LogStoppableResumeContract (address _sender);
        // Function to soft resume the contract
    function resumeContract ()
        onlyOwner
        public
        returns (bool _success)
    {
        stop = false;

        LogStoppableResumeContract (msg.sender);
        return true;
    }

// SUPPORT functions

    function isStopped ()
        public
        constant
        returns (bool _stop)
    {
        return stop;
    }
}