pragma solidity ^0.5.2;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "./Pausable.sol";

contract Remittance is Pausable {
    using SafeMath for uint256;

    struct Remittance {
        address sender;
        uint256 amount;
        uint256 expiration;
    }

    event LogRemitted(address indexed sender, bytes32 puzzle, uint256 amount);
    event LogCanceled(address indexed sender, bytes32 puzzle, uint256 amount);
    event LogClaimed(address indexed sender, uint amount);

    uint256 _minLifetime;
    mapping (bytes32 => Remittance) public _remittances;

    constructor (bool paused, uint256 minLifetime) public Pausable(paused) {
        _minLifetime = minLifetime;
    }

    function () external payable {
        revert("Not supported");
    }

    function generateSecret(address account, bytes32 plainKey) public view returns(bytes32) {
        return keccak256(abi.encodePacked(address(this), account, plainKey));
    }

    function createRemittance(bytes32 hashedKey, uint256 lifetime) public payable whenRunning {
        require(hashedKey != 0, "Key cannot be zero");
        require(lifetime >= _minLifetime, "Lifetime should be greater or equal then minimal lifetime");
        require(_remittances[hashedKey].sender == address(0), "Remittance exists");
        require(msg.value > 0, "Value should be greater 0 Wei");

        _remittances[hashedKey] = Remittance(
            msg.sender,
            msg.value,
            block.timestamp.add(lifetime)
        );

        emit LogRemitted(msg.sender, hashedKey, msg.value);
    }

    function cancelRemittance(bytes32 hashedKey) public whenRunning {
        require(hashedKey != 0, "Key cannot be zero");
        require(_remittances[hashedKey].sender == msg.sender, "Only owner can calcel");
        require(!isOpen(hashedKey), "Remittance is open");

        uint256 amount = _remittances[hashedKey].amount;
        require(amount > 0, "Amount cannot be zero");
        _remittances[hashedKey].amount = 0;
        _remittances[hashedKey].expiration = 0;

        emit LogCanceled(msg.sender, hashedKey, amount);
        msg.sender.transfer(amount);
    }

    function claim(bytes32 plainKey) public whenRunning {
        bytes32 hashedKey = generateSecret(msg.sender, plainKey);
        require(isOpen(hashedKey), "Remittance is expired");

        uint256 amount = _remittances[hashedKey].amount;
        require(amount > 0, "Amount cannot be zero");

        _remittances[hashedKey].amount = 0;

        emit LogClaimed(msg.sender, amount);
        msg.sender.transfer(amount);
    }

    function isOpen(bytes32 hashedKey) public view returns (bool) {
        return block.timestamp <= _remittances[hashedKey].expiration;
    }
}