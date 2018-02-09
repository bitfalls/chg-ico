pragma solidity ^0.4.13;

contract TokenTimedChestMulti {

    struct Beneficiary {
        address withdrawer;
        uint releaseTime;
        ERC20 token;
        uint amount;
    }

    // The addresses allowed to do withdraws
    Beneficiary[] public beneficiaries;

    // Beneficiary-added tokens so far
    mapping (address => uint) public tokensAdded;

    // Owner / creator of the contract
    address public owner;

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

    function TokenTimedChestMulti() public {
        // Define owner of the contract.
        owner = msg.sender;
    }

    function addBeneficiary(uint _releaseDelay, uint _amount, address _token, address _beneficiary) public onlyBy(owner) {

        // Upgraded implementation: track who sent how many tokens and then open up addBeneficiary to everyone
        // Could be really cool public utility contract

        // Sanity checks, only proceed if addresses involved are valid
        require(address(_token) != 0x0);
        require(address(_beneficiary) != 0x0);
        require(_amount > 0);
        require(_releaseDelay > 0);

        // Find out due time
        uint newTime = now + (_releaseDelay * 1 seconds);

        // Find out furthest due time for given user and given token
        uint furthestTime = getFurthestBeneficiaryTime(_beneficiary, _token);
        // Do not let them add a beneficiaries entry that's before the latest!
        require(furthestTime < newTime);

        // Add a beneficiary
        beneficiaries.push(
            Beneficiary(
                _beneficiary,
                newTime,
                ERC20(_token),
                _amount
            )
        );

        refreshTokenBalance(_token);
    }

    function refreshTokenBalance(address _token) internal {
        tokensAdded[_token] = ERC20(_token).balanceOf(address(this));
    }

    /**
    * Extracts latest time for specific token that a beneficiary has an entry
    * in the contract for. This is used so that a user cannot add a ben entry
    * for an already entered token that happens before the currently set time,
    * thereby getting to the tokens ahead of time.
    */
    function getFurthestBeneficiaryTime(address _beneficiary, address _token) internal view returns (uint) {
        uint bens = beneficiaries.length;
        uint latestTime = now;
        for (uint i = 0; i < bens; i++) {
            if (
                beneficiaries[i].withdrawer == _beneficiary
                && beneficiaries[i].amount > 0
                && beneficiaries[i].token == ERC20(_token)
                && beneficiaries[i].releaseTime > latestTime
            ) {
                latestTime = beneficiaries[i].releaseTime;
            }
        }
        return latestTime;
    }

    /**
    * If a user has many locks in the contract, several of which may have
    * expired, this will withdraw them all.
    */
    function withdrawAllMyDue() external {
        withdrawAllHisDue(msg.sender);
    }

    /**
    * If a user has many locks in the contract, several of which may have
    * expired, this will let the owner of the contract or this beneficiary
    * himself withdraw them all at once. If triggered by the owner, the tokens
    * are of course sent to the beneficiary, not the owner.
    */
    function withdrawAllHisDue(address _beneficiary) public {

        require(msg.sender == owner || msg.sender == _beneficiary);

        uint bens = beneficiaries.length;
        bool sentSomething = false;
        for (uint i = 0; i < bens; i++) {
            Beneficiary storage b = beneficiaries[i];
            if (
                b.withdrawer == _beneficiary
                && b.releaseTime < now
                && b.amount > 0
                && b.token.balanceOf(address(this)) >= b.amount
            ) {
                b.token.transfer(b.withdrawer, b.amount);
                b.amount = 0;
                sentSomething = true;
                refreshTokenBalance(address(b.token));
            }
        }
        assert(sentSomething == true);
    }

    /**
    * If a beneficiary knows they are due some tokens but the auto-search
    * method above is too expensive because of iteration, the beneficiary
    * can look up the ID in the contract and use that ID in this method.
    *
    * Especially useful when withdraws are rare or one-off.
    */
    function withdrawSpecific(uint id) external {
        Beneficiary storage b = beneficiaries[id];
        require(b.amount > 0);
        require(b.withdrawer == msg.sender || msg.sender == owner);
        require(b.releaseTime < now);
        require(b.token.balanceOf(address(this)) >= b.amount);

        b.token.transfer(b.withdrawer, b.amount);
        b.amount = 0;
        refreshTokenBalance(address(b.token));
    }


    /**
    * Executable by owner of contract. Releases all tokens past due time (so all
    * unlocked tokens) to their beneficiaries. Only the owner can call this.
    * Used for mass distribution of tokens after a lockdown period.
    *
    * To be eligible for withdrawing, beneficiary's claim:
    * Must be due, positive, and contract must have more than demanded amount.
    */
    function withdrawAllDue() external onlyBy(owner) {
        uint bens = beneficiaries.length;
        bool sentSomething = false;
        /** Go through each, find all due, send if OK */
        for (uint i = 0; i < bens; i++) {
            Beneficiary storage b = beneficiaries[i];
            if (
                b.releaseTime < now
                && b.amount > 0
                && b.token.balanceOf(address(this)) >= b.amount
            ) {
                b.token.transfer(b.withdrawer, b.amount);
                b.amount = 0;
                sentSomething = true;
                refreshTokenBalance(address(b.token));
            }
        }
        assert(sentSomething == true);
    }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

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

    // refund vault used to hold funds while crowdsale is running
    RefundVault public vault;

    // start and end timestamps where investments are allowed (both inclusive)
    uint256 public startTime;
    uint256 public endTime;
    uint256 public whitelistEndTime;
    // duration in days
    uint256 public duration;
    uint256 public wlDuration;

    // A collection of tokens owed to people to be timechested on finalization
    address[] public tokenBuyersArray;
    // A sum of tokenbuyers' tokens
    uint256 public tokenBuyersAmount;
    // A mapping of buyers and amounts
    mapping(address => uint) public tokenBuyersMapping;

    TokenTimedChestMulti public chest;

    // List of addresses who can purchase in pre-sale
    mapping(address => bool) public wl;
    address[] public wls;

    bool public isFinalized = false;

    event Finalized();

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
    * @param status if whitelisted, will almost always be true unless subsequently blacklisted
    */
    event Whitelisted(address addr, bool status);

    function CryptoHuntIco(uint256 _durationSeconds, uint256 _wlDurationSeconds, address _wallet, address _token) public {
        require(_durationSeconds > 0);
        require(_wlDurationSeconds > 0);
        require(_wallet != address(0));
        require(_token != address(0));
        duration = _durationSeconds;
        wlDuration = _wlDurationSeconds;

        wallet = _wallet;
        vault = new RefundVault(wallet);

        token = ERC20(_token);
        owner = msg.sender;
    }

    /**
    * Setting the rate starts the ICO and sets the end time
    */
    function setRateAndStart(uint256 _rate, uint256 _softcap, uint256 _hardcap) external onlyOwner {

        require(_rate > 0 && rate < 1);
        require(_softcap > 0);
        require(_hardcap > 0);
        require(_softcap < _hardcap);
        rate = _rate;

        softcap = _softcap;
        hardcap = _hardcap;

        startTime = now;
        whitelistEndTime = startTime.add(wlDuration * 1 seconds);
        endTime = whitelistEndTime.add(duration * 1 seconds);
    }

    // fallback function can be used to buy tokens
    function() external payable {
        buyTokens(msg.sender);
    }

    function whitelistAddresses(address[] users) onlyOwner public {
        for (uint i = 0; i < users.length; i++) {
            wl[users[i]] = true;
            wls.push(users[i]);
            Whitelisted(users[i], true);
        }
    }

    function unwhitelistAddresses(address[] users) onlyOwner external {
        for (uint i = 0; i < users.length; i++) {
            wl[users[i]] = false;
            Whitelisted(users[i], false);
        }
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != address(0));
        require(validPurchase());

        uint256 weiAmount = msg.value;

        // calculate token amount to be created
        uint256 tokenAmount = getTokenAmount(weiAmount);

        // update state
        weiRaised = weiRaised.add(weiAmount);

        tokenBuyersMapping[beneficiary] = tokenBuyersMapping[beneficiary].add(tokenAmount);
        tokenBuyersArray.push(beneficiary);
        tokenBuyersAmount.add(tokenAmount);

        TokenPurchase(msg.sender, beneficiary, weiAmount, tokenAmount);

        forwardFunds();
    }

    // @return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        return (weiRaised > hardcap) || now > endTime;
    }

    function getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(rate).div(1e6);
    }

    // send ether to the fund collection wallet
    function forwardFunds() internal {
        vault.deposit.value(msg.value)(msg.sender);
    }

    // @return true if the transaction can buy tokens
    function validPurchase() internal view returns (bool) {
        // Sent more than 0 eth
        bool nonZeroPurchase = msg.value != 0;

        // Still under hardcap
        bool withinCap = weiRaised.add(msg.value) <= hardcap;

        // if in regular period, ok
        bool withinPeriod = now >= whitelistEndTime && now <= endTime;

        // if whitelisted, and in wl period, and value is <= 5, ok
        bool whitelisted = now >= startTime && now <= whitelistEndTime && msg.value <= 5 && wl[msg.sender];

        return withinCap && (withinPeriod || whitelisted) && nonZeroPurchase;
    }

    /**
     * @dev Must be called after crowdsale ends, to do some extra finalization
     * work. Calls the contract's finalization function.
     */
    function finalize() onlyOwner public {
        require(!isFinalized);
        require(hasEnded());

        finalization();
        Finalized();

        isFinalized = true;

    }

    // if crowdsale is unsuccessful, investors can claim refunds here
    function claimRefund() public {
        require(isFinalized);
        require(!goalReached());

        vault.refund(msg.sender);
    }

    function goalReached() public view returns (bool) {
        return weiRaised >= softcap;
    }

    function forceRefundState() external onlyOwner {
        vault.enableRefunds();
        token.transfer(owner, token.balanceOf(address(this)));
        Finalized();
        isFinalized = true;
    }

    /**
     * @dev Can be overridden to add finalization logic. The overriding function
     * should call super.finalization() to ensure the chain of finalization is
     * executed entirely.
     */
    function finalization() internal {

        if (goalReached()) {
            vault.close();
            // create timed chests for all participants
            createTimedChest();
            token.transfer(chest, tokenBuyersAmount);

            for (uint i = 0; i < tokenBuyersArray.length; i++) {
                uint256 bought = tokenBuyersMapping[tokenBuyersArray[i]];
                uint256 fraction = bought.div(uint256(8));
                for (uint8 j = 1; j <= 8; j++) {
                    // addBeneficiary(uint _releaseDelay, uint _amount, address _token, address _beneficiary)
                    chest.addBeneficiary(604800 * j, fraction, address(token), tokenBuyersArray[i]);
                }
            }

        } else {
            vault.enableRefunds();
        }
        // Transfer leftover tokens to owner
        token.transfer(owner, token.balanceOf(address(this)));
    }

    /**
    * Instantiates a new timelocked token chest and stores it in ICO's state
    */
    function createTimedChest() internal {
        chest = new TokenTimedChestMulti();
    }

    /**
    * Initiates a withdraw-all-due command on the chest, sending due tokens
    * Only callable if the crowdsale was successful and it's finished
    */
    function withdrawAllDue() public onlyOwner {
        require(isFinalized && goalReached());
        chest.withdrawAllDue();
    }
}

contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  function RefundVault(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    Closed();
    wallet.transfer(this.balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }

  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
  }
}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

