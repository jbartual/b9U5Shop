pragma solidity ^0.4.4;

import "./Stoppable.sol";

// Common functions for contracts that are funded
contract Funded is Stoppable {
    uint256 private contractBalance;
    uint256 private contractProfit;
    mapping (address => bool) private cashiers; //addresses that can transfer funds between depositers
    mapping (address => uint256) private depositors; //total amount received by address

    event LogFundedNew (address _sender, address _cashier);
    // Constructor. A default cashier is mandatory
    function Funded (address _cashier)
        public
    {
        cashiers[_cashier] = true;
        LogFundedNew (msg.sender, _cashier);
    }

    modifier onlyCashiers () { require(cashiers[msg.sender]); _; }
    modifier onlyDepositors () { require (depositors[msg.sender] > 0); _; }

    function getContractBalance ()
        public
        constant
        returns (uint256 _contractBalance)
    {
        return contractBalance;
    }

    function isCashier (address _cashier)
        public
        constant
        returns (bool _is)
    {
        return (cashiers[_cashier]);
    }

    function isDepositor (address _depositor)
        public
        constant
        returns (bool _is)
    {
        return (depositors[_depositor] > 0);
    }

    function getDepositorBalance (address _depositor)
        public
        constant
        returns (uint256 _balance)
    {
        return (depositors[_depositor]);
    }

    event LogFundedDepositFunds (address _sender, uint _amount);
    // Fallback function payable to enable a contract to receive funds when inherinting this contract
    // The idea is to keep track of the funds and funders through this fallback function
    // The contract that inherits this contract shall not apply its own payable functions. Only use these ones
    function depositFunds()
        onlyIfRunning
        payable
        public
        returns (bool _success)
    {
        contractBalance = this.balance; // account the funds stored in the contract
        depositors[msg.sender] += msg.value;

        LogFundedDepositFunds (msg.sender, msg.value);
        return true;
    }

    event LogFundedWithdrawFunds (address _sender, uint _amount);
    // Function to withdraw money from sender's own balance
    function withdrawFunds (uint _amount)
        onlyDepositors
        onlyIfRunning
        public
        returns (bool _success)
    {
        require (contractBalance > 0); //prevent re-entry
        require (depositors[msg.sender] >= _amount); //prevent over spending
        require (_amount > 0);

        contractBalance -= _amount; //optimistic accounting
        depositors[msg.sender] -= _amount; //optimistic accounting

        msg.sender.transfer(_amount);

        LogFundedWithdrawFunds (msg.sender, _amount);
        return true;
    }

    event LogFundedSpendFunds (address _sender, uint256 _amount);
    // Allow a depositor to spend balance in the contract's services or goods
    function spendFunds (uint256 _amount)
        onlyDepositors
        onlyIfRunning
        public
        returns (bool _success)
    {
        require (contractBalance > 0); //prevent major re-entry
        require (depositors[msg.sender] >= _amount); //prevent over spending

          if (_amount == depositors[msg.sender] )
            delete depositors[msg.sender];
          else
            depositors[msg.sender] -= _amount; //optimistic accounting

        contractProfit += _amount; //account the spending

        LogFundedSpendFunds (msg.sender, _amount);
        return true;
    }

    event LogFundedAddCashier (address _sender, address _cashier);
    // To add a cashier to the mapping
    function addCashier (address _cashier)
        onlyOwner
        onlyIfRunning
        public
        returns (bool _success)
    {
        require (_cashier != 0);
        cashiers[_cashier] = true;
        LogFundedAddCashier (msg.sender, _cashier);
        return true;
    }

    event LogFundedRemoveCashier (address _sender, address _cashier);
    // To remove a cashier from the mapping
    function removeCashier (address _cashier)
        onlyOwner
        onlyIfRunning
        public
        returns (bool _success)
    {
        require (cashiers[_cashier]);
        cashiers[_cashier] = false;
        LogFundedRemoveCashier(msg.sender, _cashier);
        return true;
    }

    event LogFundedCashierMoveDeposits (address _sender, address _from, address _to, uint256 _amount);
    // Cashiers can move balance from one depositor to another depositor
    function cashierMoveDeposits (address _from, address _to, uint256 _amount)
        onlyCashiers
        onlyIfRunning
        public
        returns (bool _success)
    {
        require (depositors[_from] >= _amount); //require origin depositor to have enough balance
        require (_to != 0); //check _beneficiary is not 0

        depositors[_from] -= _amount;
        depositors[_to] += _amount;

        LogFundedCashierMoveDeposits (msg.sender, _from, _to, _amount);
        return true;
    }

    event LogFundedCashierUpdateDepositorBalance (address _sender, address _depositor, uint _newBalance);
    // Cashiers can update the soft accounting balance for a depositor
    function cashierUpdateDepositorBalance (address _depositor, uint _newBalance)
        onlyCashiers
        onlyIfRunning
        public
        returns (bool _success)
    {
        depositors[_depositor] = _newBalance;
        LogFundedCashierUpdateDepositorBalance (msg.sender, _depositor, _newBalance);
        return true;
    }

    event LogFundedEmergencyRefund (address _sender, address _beneficiary, uint _amount);
    // Emergency function only for the owner that allows to transfer funds
    // The contract doesn't require to be running to execute
    function emergencyRefund (address _beneficiary, uint _amount)
        onlyOwner
        public
        returns (bool _success)
    {
        require(contractBalance > _amount); //prevent re-entry
        require(depositors[_beneficiary] >= _amount); //require enough balance

        contractBalance -= _amount; //optimistic accounting
        depositors[_beneficiary] -= _amount; //optimistic accounting

        _beneficiary.transfer(_amount);

        LogFundedEmergencyRefund(msg.sender, _beneficiary, _amount);
        return true;
    }
}
