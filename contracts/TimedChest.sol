pragma solidity ^0.4.18;

import "../node_modules/zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol";
// import "../node_modules/zeppelin-solidity/contracts/token/SafeERC20.sol";

contract TimedChest {
    // using SafeERC20 for ERC20Basic;

    /** The address allowed to do withdraws */
    address public withdrawer;

    /** Owner / creator of the contract */
    address public owner;

    /** Address of the token we're time-locking */
    ERC20Basic public token;

    /** Times at which specific amount becomes available */
    uint[] public releaseTimes;

    /** List of amounts which can be withdrawn after a specific timestamp */
    uint[] public amounts;
    
    modifier onlyAfter(uint _time) {
        require(now >= _time);
        _;
    }

    modifier onlyBy(address _account) {
        require(msg.sender == _account);
        _;
    }

    function changeOwner(address _newOwner) public onlyBy(owner) {
        owner = _newOwner;
    }

    function TimedChest(uint[] _releaseDelays, uint[] _amounts, address _withdrawer, address _tokenAddress) public {
        owner = msg.sender;

        require (address(_tokenAddress) != 0x0);
        require (address(_withdrawer) != 0x0);
        require (_releaseDelays.length == _amounts.length && _releaseDelays.length > 0);

        for (uint8 i = 0; i < _releaseDelays.length; i++) {
            require(_releaseDelays[i] > now);
            require(_amounts[i] > 0);
            if (i == 0) {
                releaseTimes[i] = now + _releaseDelays[i];
            } else {
                releaseTimes[i] = releaseTimes[i-1] + _releaseDelays[i];
            }
        }
        
        releaseTimes = _releaseDelays;
        amounts = _amounts;
        withdrawer = _withdrawer;
        token = ERC20Basic(_tokenAddress);
    }

    function withdraw() onlyBy(withdrawer) external {
        uint256 amount = token.balanceOf(this);
        require (amount > 0);
        
        for (uint8 i = 0; i < releaseTimes.length; i++) {
            if (releaseTimes[i] < now && amounts[i] > 0) {
                token.transfer(withdrawer, amounts[i]);
            }
        }
    }

    function withdrawAll() onlyBy(owner) external {
        uint256 amount = token.balanceOf(this);
        require (amount > 0);
        
        token.transfer(owner, amount);
    }

}