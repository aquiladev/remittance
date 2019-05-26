pragma solidity ^0.5.2;

import "./Ownable.sol";

contract Killable is Ownable {
    event LogKilled(address account);

    bool private _killed;

    modifier whenAlive() {
        require(!_killed, "Killed");
        _;
    }

    constructor () internal {
        _killed = false;
    }

    function kill() public onlyOwner whenAlive {
        _killed = true;
        emit LogKilled(msg.sender);
    }
}
