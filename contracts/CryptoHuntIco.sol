pragma solidity ^0.4.18;

import './TokenTimedChestMulti.sol';
import '../node_modules/zeppelin-solidity/contracts/math/SafeMath.sol';
import '../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol';

contract ERC20Events {
    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
}

contract ERC20 is ERC20Events {
    function totalSupply() public view returns (uint) {}

    function balanceOf(address guy) public view returns (uint) {}

    function allowance(address src, address guy) public view returns (uint) {}

    function approve(address guy, uint wad) public returns (bool) {}

    function transfer(address dst, uint wad) public returns (bool) {}

    function transferFrom(address src, address dst, uint wad) public returns (bool) {}
}

contract CryptoHuntIco is Ownable {
    using SafeMath for uint256;

    ERC20 public token;

    // address where funds are collected
    address public wallet;

    // how many token units a buyer gets per wei
    uint256 public rate;

    // amount of raised money in wei
    uint256 public weiRaised;

    uint256 public softcap;
    uint256 public hardcap;

    // start and end timestamps where investments are allowed (both inclusive)
    uint256 public startTime;
    uint256 public endTime;
    uint256 public whitelistEndTime;
    // duration in days
    uint256 public duration;
    uint256 public wlDuration;

    bool public isFinalized = false;
    event Finalized();

    modifier onlyAfter(uint _time) {
        require(now >= _time);
        _;
    }

    modifier onlyBy(address _account) {
        require(msg.sender == _account);
        _;
    }

    /**
     * event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
    */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
    * @param addr whitelisted user
    * @param if whitelisted, will almost always be true unless subsequently blacklisted
    */
    event Whitelisted(address addr, bool status);

    function CryptoHuntIco(uint256 _durationSeconds, uint256 _wlDurationSeconds, address _wallet, address _token, uint _softcap, uint _hardcap) public {
        require(_durationSeconds > 0);
        require(_wlDurationSeconds > 0);
        require(_wallet != address(0));
        require(_token != address(0));
        require(_softcap > 0);
        require(_hardcap > 0);

        softcap = _softcap;
        hardcap = _hardcap;
        duration = _durationSeconds;
        wlDuration = _wlDurationSeconds;
        wallet = _wallet;
        token = ERC20(_token);
        owner = msg.sender;
    }

    /**
    * Setting the rate starts the ICO and sets the end time
    */
    function setRateAndStart(uint256 _rate) external onlyBy(owner) {
        require(_rate > 0 && rate < 1);
        rate = _rate;

        startTime = now;
        whitelistEndTime = startTime.add(wlDuration * 1 seconds);
        endTime = whitelistEndTime.add(duration * 1 seconds);
    }

    // fallback function can be used to buy tokens
    function () external payable {
        buyTokens(msg.sender);
    }

    function whitelistAddresses(address[] users) onlyOwner external {
        for (uint i = 0; i < users.length; i++) {
            wl[users[i]] = true;
            Whitelisted(users[i], true);
        }
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokens = getTokenAmount(weiAmount);

        // update state
        weiRaised = weiRaised.add(weiAmount);

        //@todo
        // transfer token, not mint

        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        //@todo
        //forwardFunds();
    }

    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        return (weiRaised > hardcap) || now > endTime;
    }

    // @return true if whitelist period has ended
    function whitelistHasEnded() public view returns (bool) {
        return now > whitelistEndTime;
    }

    // Override this method to add business logic to crowdsale when buying
    // @todo
    function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
        return weiAmount.mul(rate);
    }

    // send ether to the fund collection wallet
    // override to create custom fund forwarding mechanisms
    function forwardFunds() internal {
        wallet.transfer(msg.value);
        // delay until soft cap is passed!
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal view returns (bool) {
        // Sent more than 0 eth
        bool nonZeroPurchase = msg.value != 0;

        // Still under hardcap
        bool withinCap = weiRaised.add(msg.value) <= cap;

        // if in regular period, ok
        bool withinPeriod = now >= startTime && now <= endTime;

        // if whitelisted, and in wl period, and value is <= 5, ok
        // @todo

        return withinCap && (withinPeriod || whitelisted) && nonZeroPurchase;
    }

    /**
     * @dev Must be called after crowdsale ends, to do some extra finalization
     * work. Calls the contract's finalization function.
     * @todo
     */
    function finalize() onlyOwner public {
        require(!isFinalized);
        require(hasEnded());

        finalization();
        Finalized();

        isFinalized = true;
    }

    /**
     * @dev Can be overridden to add finalization logic. The overriding function
     * should call super.finalization() to ensure the chain of finalization is
     * executed entirely.
     @todo
     */
    function finalization() internal {
    }
}