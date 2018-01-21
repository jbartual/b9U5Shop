pragma solidity ^0.4.4;

import "./Owned.sol";

// Common functions for contracts that are stoppable
contract Stoppable is Owned {
    bool private stop;
    
    function Stoppable ()
        public
    {
    }

    modifier onlyIfRunning () { require (!stop); _; }

    function isStopped ()
        public
        constant
        returns (bool _stop)
    {
        return stop;
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
}
