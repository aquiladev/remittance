pragma solidity ^0.5.2;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract Timed {
    using SafeMath for uint256;

    uint256 private _openingTime;
    uint256 private _closingTime;

    modifier onlyWhileOpen {
        require(isOpen());
        _;
    }

    constructor (uint256 openingTime, uint256 closingTime) public {
        require(openingTime >= block.timestamp);
        require(closingTime > openingTime);

        _openingTime = openingTime;
        _closingTime = closingTime;
    }

    function isOpen() public view returns (bool) {
        return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
    }
}