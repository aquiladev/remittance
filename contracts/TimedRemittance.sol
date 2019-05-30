pragma solidity ^0.5.2;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "./Remittance.sol";

contract TimedRemittance is Remittance {
    using SafeMath for uint256;

    uint256 _lifetime;
    /// The mapping contains block number for remittance
    mapping (address => mapping (bytes32 => uint256)) private _block;

    modifier onlyWhileOpen(address sender, bytes32 plainKey) {
        bytes32 hashedKey = generateSecret(sender, plainKey);
        require(isOpen(sender, hashedKey), "Remittance is expired");
        _;
    }

    modifier whenExpired(address sender, bytes32 hashedKey) {
        require(!isOpen(sender, hashedKey), "Remittance is open");
        _;
    }

    constructor (bool paused, uint256 lifetimeInBlocks) public Remittance(paused) {
        _lifetime = lifetimeInBlocks;
    }

    function isOpen(address sender, bytes32 hashedKey) public view returns (bool) {
        return block.number >= _block[sender][hashedKey] &&
            block.number <= _block[sender][hashedKey].add(_lifetime);
    }

    function cancelRemittance(bytes32 hashedKey) public whenExpired(msg.sender, hashedKey) {
        super.cancelRemittance(hashedKey);
    }

    function claim(address sender, bytes32 plainKey) public onlyWhileOpen(sender, plainKey) {
        super.claim(sender, plainKey);
    }
}