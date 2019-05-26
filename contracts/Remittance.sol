pragma solidity ^0.5.2;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "./Ownable.sol";
import "./Pausable.sol";
import "./Killable.sol";

contract Remittance is Ownable, Pausable, Killable {
    using SafeMath for uint256;

    event LogRemitted(address indexed remitter, bytes32 puzzle, uint256 amount);
    event LogClaimed(address indexed who, uint amount);

    mapping (address => uint) public balances;
    mapping (address => mapping (bytes32 => uint256)) private _allowed;

    constructor() public Pausable(false) {
    }

    function () external payable {
        revert("Not supported");
    }

    function remit(bytes32 key) public payable whenRunning whenAlive {
        require(key != 0, "Key cannot be zero");
        require(msg.value > 0, "Value should be greater 0 Wei");

        balances[msg.sender] = balances[msg.sender].add(msg.value);
        _allowed[msg.sender][key] = _allowed[msg.sender][key].add(msg.value);

        emit LogRemitted(msg.sender, key, msg.value);
    }

    function claim(address remitter, bytes32 key1, bytes32 key2) public whenRunning {
        require(remitter != address(0), "Remitter cannot be empty");

        bytes32 key = keccak256(abi.encodePacked(msg.sender, key1, key2));
        uint256 amount = _allowed[remitter][key];
        require(amount > 0, "Amount cannot be zero");

        uint256 balance = balances[remitter];
        require(balance >= amount, "Not enough balance");

        balances[remitter] = balances[remitter].sub(amount);
        _allowed[remitter][key] = 0;

        emit LogClaimed(msg.sender, amount);
        msg.sender.transfer(amount);
    }
}