pragma solidity ^0.5.2;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "./Pausable.sol";

contract Remittance is Pausable {
    using SafeMath for uint256;

    event LogRemitted(address indexed sender, bytes32 puzzle, uint256 amount);
    event LogClaimed(address indexed who, uint amount);

    mapping (address => uint) public balances;
    mapping (address => mapping (bytes32 => uint256)) private _allowed;

    function () external payable {
        revert("Not supported");
    }

    function generateSecret(address recipient, bytes32 key) public view onlyOwner returns(bytes32) {
        return _getSecret(recipient, key);
    }

    function createRemittance(bytes32 key) public payable whenRunning whenAlive {
        require(key != 0, "Key cannot be zero");
        require(msg.value > 0, "Value should be greater 0 Wei");

        balances[msg.sender] = balances[msg.sender].add(msg.value);
        _allowed[msg.sender][key] = _allowed[msg.sender][key].add(msg.value);

        emit LogRemitted(msg.sender, key, msg.value);
    }

    function claim(address sender, bytes32 key) public whenRunning {
        require(sender != address(0), "Sender cannot be empty");

        bytes32 key = _getSecret(msg.sender, key);
        uint256 amount = _allowed[sender][key];
        require(amount > 0, "Amount cannot be zero");

        uint256 balance = balances[sender];
        require(balance >= amount, "Not enough balance");

        balances[sender] = balances[sender].sub(amount);
        _allowed[sender][key] = 0;

        emit LogClaimed(msg.sender, amount);
        msg.sender.transfer(amount);
    }

    function _getSecret(address account, bytes32 key) private pure returns(bytes32) {
        return keccak256(abi.encodePacked(account, key));
    }
}