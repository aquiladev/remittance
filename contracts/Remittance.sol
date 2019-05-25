pragma solidity ^0.5.2;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "./Pausable.sol";

contract Remittance is Ownable, Pausable {
    using SafeMath for uint256;

    event Remitted(address indexed sender, uint256 amount);
    event Claimed(address indexed who, uint amount);

    mapping (address => uint) public balances;
    mapping (address => mapping (uint256 => uint256)) private _allowed;

    function remit(uint256 key) public payable whenNotPaused {
        require(key != 0, "Key cannot be zero");
        require(msg.value > 0, "Value should be greater 0 Wei");

        balances[msg.sender] = balances[msg.sender].add(msg.value);
        _allowed[msg.sender][key].add(msg.value);

        emit Remitted(msg.sender, msg.value);
    }

    function claim(address remitter, uint256 key1, uint256 key2) public whenNotPaused {
        require(remitter != address(0), "Remitter cannot be empty");

        uint256 key = keccak256(abi.encodePacked(msg.sender, key1, key2));
        uint256 amount = _allowed[remitter][key];
        require(amount > 0, "Amount cannot be zero");

        uint256 balance = balances[remitter];
        require(balance >= amount, "Not enough balance");

        balances[remitter] = balances[remitter].sub(amount);
        _allowed[remitter][key] = 0;
        msg.sender.transfer(amount);

        emit Claimed(msg.sender, amount);
    }
}