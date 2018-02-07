pragma solidity ^0.4.4;

/* 

  Last update: 2018-02-07
  Version: 2.3

  Contract to manage Funds deposited into a contract for:
  - Purchasing the services/goods offered by the child contract
  - Execute a transfer between two parties from the child contract
  - Charge/refund optional commission

  Modifiers:
  - onlyDepositors

  Core functions:
  - Constrcutor
  - newHashTicket
  - depositFunds
  - withdrawFunds
  - spendFunds
  - newHashTicketTransfer
  - hashTicketTransfer
  - transferFunds
  - chargeCommission
  - refundCommission

  Admin functions:
  - emergencyWithdrawal

  Support functions:
  - getInfoContractFunds
  - getInfoContractCommissions
  - getInfoDeposit
  - getInfoCommission
  - isDepositor

*/

import "./_Stoppable.sol";

contract FundsManager is Stoppable {
    uint private contractFunds;
    uint private contractCommissions;

    struct Deposit {
        address depositor;
        uint amount;
    }
    mapping (bytes32 => Deposit) private deposits; // hashTicket => Deposit
    mapping (address => uint) private depositors; // msg.sender => deposits counter (used for hashTicket creation)
    mapping (bytes32 => uint) private commissions; // hashTicket => commission

    modifier onlyDepositors() { require(depositors[msg.sender] > 0); _; }

// CORE FUNCTIONS

        event LogFundsManagerNew (address _sender);
        // Constructor
    function FundsManager() 
        public 
    {
        LogFundsManagerNew (msg.sender);
    }

        // Anyone wishing to deposit funds into the contract is required to request a hash-ticket
    function newHashTicket ()
        constant
        public
        returns (bytes32 _hashTicket)
    {
        return keccak256 (msg.sender, depositors[msg.sender]);
    }

        event LogFundsManagerDepositFunds (address _sender, uint value);
        // With a hashed ticket anyone can deposits funds
    function depositFunds (bytes32 _hashTicket)
        onlyIfRunning
        internal
        returns (bool _success)
    {
        //require (msg.value > 0);
        require (_hashTicket != 0);

        deposits[_hashTicket].depositor = msg.sender;
        deposits[_hashTicket].amount += msg.value;
        depositors[msg.sender] += 1; // This counter allows multiple deposits by the same sender with different hash tickets
        contractFunds += msg.value; // Soft accounting of the deposit
        
        LogFundsManagerDepositFunds (msg.sender, msg.value);
        return true;
    }

        event LogFundsManagerWithdrawFunds (address _sender, address _depositor, uint _amount);
        // If a depositor wishes to withdraw funds they can do it using the hash-ticket
    function withdrawFunds (bytes32 _hashTicket)
        onlyDepositors
        onlyIfRunning
        internal
        returns (bool _success)
    {
        require(_hashTicket != 0);

        Deposit storage deposit = deposits[_hashTicket];
        
        require(deposit.amount > 0);
        require(deposit.depositor == msg.sender);

        delete deposits[_hashTicket]; // Delete the deposit
        
        depositors[msg.sender] -= 1; // Decrease the counter of valid deposits to the depositor
        contractFunds -= deposit.amount; // Soft accounting of the withdrawal

        deposit.depositor.transfer(deposit.amount);

        LogFundsManagerWithdrawFunds (msg.sender, deposit.depositor, deposit.amount);
        return true;
    }

        event LogFundsManagerSpendFunds (address _sender, bytes32 _hashTicket, uint _amount);
        // If the child contract provides a service, then execute this function to account the depositor with an expenditure
    function spendFunds (bytes32 _hashTicket, uint _amount)
        onlyDepositors
        onlyIfRunning
        internal
        returns (bool _success)
    {
        require (_hashTicket != 0);

        Deposit storage deposit = deposits[_hashTicket];

        require (deposit.depositor == msg.sender); //ensure that the sender is the depositor of the ticket
        require (deposit.amount > 0);
        require (deposit.amount >= _amount); //prevent overspending

        if (_amount == deposit.amount) delete deposits[_hashTicket]; //delete the deposit as all the funds are being spent
        else deposit.amount -= _amount; //account the expenditure

        LogFundsManagerSpendFunds (msg.sender, _hashTicket, _amount);
        return true;
    }

        // To be used when the contract is an intermediary between 2 parties
        // The sender shall deposit the funds that the beneficiary will transfer to their account
        // To secure the transfer both the origin and the beneficiary addresses are required as well as a password
    function newHashTicketTransfer (address _beneficiary, bytes32 _password)
        constant
        public
        returns (bytes32 _hashTicketTransfer)
    {
        return hashTicketTransfer (msg.sender, _beneficiary, _password);
    }

        // Both the origin and the beneficiary of the transfer will end up calling this function from different interfaces
    function hashTicketTransfer (address _origin, address _beneficiary, bytes32 _password)
        constant
        private
        returns (bytes32 _hashTicketTransfer)
    {
        require (_origin != 0);
        require (_beneficiary != 0);
        require (_password != 0);
        return keccak256(msg.sender, _beneficiary, _password);
    }

        event LogFundsManagerTransferFunds (address _sender, address _origin, bytes32 _password);
        // To be executed by the beneficiary that wishes to transfer the funds to their account
    function transferFunds (address _origin, bytes32 _password)
        onlyIfRunning
        internal
        returns (bool _success)
    {
        bytes32 hashTicketT = hashTicketTransfer (_origin, msg.sender, _password);
        uint transferAmount = deposits[hashTicketT].amount; 
        require (transferAmount > 0);

        delete deposits[hashTicketT]; //remove the deposit | optimistic accounting

        msg.sender.transfer(transferAmount);

        LogFundsManagerTransferFunds (msg.sender, _origin, _password);
        return true;
    }

        event LogFundsManagerChargeCommission (address _sender, bytes32 _hashTicket, uint _commissionAmount);
        // If the child contract requires to charge a commission, this function can be called by any sender
    function chargeCommission (bytes32 _hashTicket, uint _commissionAmount)
        internal
        returns (bool _success)
    {
        require (_hashTicket != 0);
        require (commissions[_hashTicket] == 0); //prevent more than one commission per ticket

        uint originalAmount = deposits[_hashTicket].amount;
        require (originalAmount > 0);
        require (originalAmount - _commissionAmount > 0); //prevent the commission to turn the balance negative

        contractCommissions += _commissionAmount; // account the commission
        contractFunds -= _commissionAmount; // substract the commission from funds

        commissions[_hashTicket] = _commissionAmount;
        deposits[_hashTicket].amount = originalAmount - _commissionAmount;

        LogFundsManagerChargeCommission (msg.sender, _hashTicket, _commissionAmount);
        return true;
    }

        event LogFundsManagerRefundCommission (address _sender, bytes32 _hashTicket);
        // In case the commission requires to be refunded
    function refundCommission (bytes32 _hashTicket)
        internal
        returns (bool _success)
    {
        require (commissions[_hashTicket] > 0);

        uint refundAmount = commissions[_hashTicket];
        delete commissions[_hashTicket];

        contractCommissions -= refundAmount; // account the refund
        contractFunds += refundAmount; // add the commission to funds

        uint originalAmount = deposits[_hashTicket].amount;
        deposits[_hashTicket].amount = originalAmount + refundAmount;
        
        LogFundsManagerRefundCommission (msg.sender, _hashTicket);
        return true;
    }

// ADMIN FUNCTIONS

        event LogFundsManagerNewDepositor (address _sender, address _depositor);
        // Owner can register new depositors without the need to deposit any funds
    function newDepositor (address _depositor)
        onlyOwner
        public
        returns (bool _success)
    {
        require (_depositor != 0);
        
        depositors[_depositor] += 1;
        
        LogFundsManagerNewDepositor (msg.sender, _depositor);
        return true;
    }

        event LogFundsManagerEmergencyWithdrawal (address _sender, address _depositor, uint _amount);
        // Only Owner
        // Contract can be stopped
    function emergencyWithdrawal (bytes32 _hashTicket)
        onlyOwner
        public
        returns (bool _success)
    {
        require(deposits[_hashTicket].amount > 0);
        
        address depositor = deposits[_hashTicket].depositor;
        uint withdrawalAmount = deposits[_hashTicket].amount;

        delete deposits[_hashTicket];

        depositor.transfer(withdrawalAmount);

        LogFundsManagerEmergencyWithdrawal (msg.sender, depositor, withdrawalAmount);
        return true;        
    }

// SUPPORT FUNCTIONS

    function getInfoContractFunds ()
        onlyOwner
        view
        public
        returns (uint _contractFunds)
    {
        return contractFunds;
    }

    function getInfoContractCommissions ()
        onlyOwner
        view
        public
        returns (uint _contractCommissions)
    {
        return contractCommissions;
    }

    function getInfoDeposit (bytes32 _hashTicket)
        view
        public
        returns (address _depositor, uint _amount)
    {
        require (_hashTicket != 0);

        return (deposits[_hashTicket].depositor, deposits[_hashTicket].amount);
    }

    function getInfoCommission (bytes32 _hashTicket)
        view
        public
        returns (uint _commissionAmount)
    {
        require (_hashTicket != 0);

        return (commissions[_hashTicket]);
    }

    function isDepositor (address _depositor)
        view
        public
        returns (bool _isIndeed)
    {
        require (_depositor != 0);

        if (depositors[_depositor] > 0)
            return true;
        else
            return false;
    }
}