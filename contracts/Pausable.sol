pragma solidity ^0.5.2;

import "./Ownable.sol";

contract Pausable is Ownable {
    event LogPaused(address account);
    event LogResumed(address account);
    event LogKilled(address account);

    bool private _paused;
    bool private _killed;

    modifier whenRunning() {
        require(!_paused, "Paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Running");
        _;
    }

    modifier whenAlive() {
        require(!_killed, "Killed");
        _;
    }

    function isPaused() public view returns (bool) {
        return _paused;
    }

    function pause() public onlyOwner whenRunning {
        _paused = true;
        emit LogPaused(msg.sender);
    }

    function resume() public onlyOwner whenPaused whenAlive {
        _paused = false;
        emit LogResumed(msg.sender);
    }

    function kill() public onlyOwner whenPaused whenAlive {
        _killed = true;
        emit LogKilled(msg.sender);
    }
}
