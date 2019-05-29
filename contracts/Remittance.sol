pragma solidity ^0.5.2;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "./Pausable.sol";

contract Remittance is Pausable {
    using SafeMath for uint256;

    event LogRemitted(address indexed sender, bytes32 puzzle, uint256 amount);
    event LogCanceled(address indexed sender, bytes32 puzzle, uint256 amount);
    event LogClaimed(address indexed who, uint amount);

    /// The mapping contains allowed amount for recipient and puzzles
    mapping (address => mapping (bytes32 => uint256)) private _allowed;

    constructor (bool paused) public Pausable(paused) {
    }

    function () external payable {
        revert("Not supported");
    }

    function generateSecret(address recipient, bytes32 key) public view onlyOwner returns(bytes32) {
        return _getSecret(recipient, key);
    }

    function createRemittance(bytes32 key) public payable whenRunning whenAlive {
        require(key != 0, "Key cannot be zero");
        require(msg.value > 0, "Value should be greater 0 Wei");

        _allowed[msg.sender][key] = _allowed[msg.sender][key].add(msg.value);

        emit LogRemitted(msg.sender, key, msg.value);
    }

    function cancelRemittance(bytes32 key) public whenRunning whenAlive {
        require(key != 0, "Key cannot be zero");

        uint256 amount = _allowed[msg.sender][key];
        require(amount > 0, "Amount cannot be zero");
        _allowed[msg.sender][key] = 0;

        emit LogCanceled(msg.sender, key, amount);
        msg.sender.transfer(amount);
    }

    function claim(address sender, bytes32 key) public whenRunning {
        require(sender != address(0), "Sender cannot be empty");

        bytes32 secret = _getSecret(msg.sender, key);
        uint256 amount = _allowed[sender][secret];
        require(amount > 0, "Amount cannot be zero");

        _allowed[sender][secret] = 0;

        emit LogClaimed(msg.sender, amount);
        msg.sender.transfer(amount);
    }

    function _getSecret(address account, bytes32 key) private view returns(bytes32) {
        return keccak256(abi.encodePacked(address(this), account, key));
    }
}