pragma solidity ^0.4.13;

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
    mapping(address => uint256) public tokenBuyersMapping;
    mapping(address => uint256) public tokenBuyersFraction;
    mapping(address => uint256) public tokenBuyersRemaining;

//    TokenTimedChestMulti public chest;

    // List of addresses who can purchase in pre-sale
    mapping(address => bool) public wl;

    bool public isFinalized = false;
    bool public forcedRefund = false;

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

        //chest = new TokenTimedChestMulti();
    }

    // fallback function can be used to buy tokens
    function() external payable {
        buyTokens(msg.sender);
    }

    // ["0x1dF184eA46b58719A7213f4c8a03870A309BcD64", "0xb794f5ea0ba39494ce839613fffba74279579268", "0x281055afc982d96fab65b3a49cac8b878184cb16", "0x6f46cf5569aefa1acc1009290c8e043747172d89", "0xa1dc8d31493681411a5137c6D67bD01935b317D3", "0x90e63c3d53e0ea496845b7a03ec7548b70014a91", "0x53d284357ec70ce289d6d64134dfac8e511c8a3d", "0xf4b51b14b9ee30dc37ec970b50a486f37686e2a8", "0xe853c56864a2ebe4576a807d26fdc4a0ada51919", "0xfbb1b73c4f0bda4f67dca266ce6ef42f520fbb98", "0xf27daff52c38b2c373ad2b9392652ddf433303c4", "0x3d2e397f94e415d7773e72e44d5b5338a99e77d9", "0x6f52730dba7b02beefcaf0d6998c9ae901ea04f9", "0xdc870798b30f74a17c4a6dfc6fa33f5ff5cf5770", "0x1b3cb81e51011b549d78bf720b0d924ac763a7c2", "0xb8487eed31cf5c559bf3f4edd166b949553d0d11", "0x51f9c432a4e59ac86282d6adab4c2eb8919160eb", "0xfe9e8709d3215310075d67e3ed32a380ccf451c8", "0xfca70e67b3f93f679992cd36323eeb5a5370c8e4", "0x07ee55aa48bb72dcc6e9d78256648910de513eca", "0x900d0881a2e85a8e4076412ad1cefbe2d39c566c", "0x3bf86ed8a3153ec933786a02ac090301855e576b", "0xbf09d77048e270b662330e9486b38b43cd781495", "0xdb6fd484cfa46eeeb73c71edee823e4812f9e2e1", "0x847ed5f2e5dde85ea2b685edab5f1f348fb140ed", "0x9d2bfc36106f038250c01801685785b16c86c60d", "0x2b241f037337eb4acc61849bd272ac133f7cdf4b", "0xab5801a7d398351b8be11c439e05c5b3259aec9b", "0xa7e4fecddc20d83f36971b67e13f1abc98dfcfa6", "0x9f1de00776811f916790be357f1cabf6ac1eca65", "0x7d04d2edc058a1afc761d9c99ae4fc5c85d4c8a6"]
    function whitelistAddresses(address[] users) onlyOwner external {
        for (uint i = 0; i < users.length; i++) {
            wl[users[i]] = true;
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

        if (tokenBuyersMapping[beneficiary] == 0) {
            tokenBuyersArray.push(beneficiary);
        }
        tokenBuyersMapping[beneficiary] = tokenBuyersMapping[beneficiary].add(tokenAmount);
        tokenBuyersAmount = tokenBuyersAmount.add(tokenAmount);

        TokenPurchase(msg.sender, beneficiary, weiAmount, tokenAmount);

        forwardFunds();
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
        bool nonZeroPurchase = msg.value > 0;

        // Still under hardcap
        bool withinCap = weiRaised.add(msg.value) <= hardcap;

        // if in regular period, ok
        bool withinPeriod = now >= whitelistEndTime && now <= endTime;

        // if whitelisted, and in wl period, and value is <= 5, ok
        bool whitelisted = now >= startTime && now <= whitelistEndTime && msg.value <= 5 ether && wl[msg.sender];

        return withinCap && (withinPeriod || whitelisted) && nonZeroPurchase;
    }

    /**
     * @dev Must be called after crowdsale ends, to do some extra finalization
     * work. Calls the contract's finalization function.
     */
    function finalize() onlyOwner public {
        require(!isFinalized);
        require((weiRaised == hardcap) || now > endTime);

        finalization();
        Finalized();

        isFinalized = true;

    }

    // if crowdsale is unsuccessful, investors can claim refunds here
    function claimRefund() public {
        require(isFinalized);
        require(!goalReached() || forcedRefund);

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
        forcedRefund = true;
    }

    /**
     * Wraps up the crowdsale
     *
     * If goal was not reached, refund mode is activated, tokens are sent back to crowdfund owner. Otherwise:
     *
     * - vault is closed and Eth funds are forwarded to wallet
     * -
     */
    function finalization() internal {

        if (goalReached()) {

            vault.close();

            // Alternatively, don't chest them. Make withdraw (pull) functions in this contract itself.
            // Also add pull function for owner.
//            token.transfer(chest, tokenBuyersAmount);
//
//            for (uint i = 0; i < tokenBuyersArray.length; i++) {
//                uint256 bought = tokenBuyersMapping[tokenBuyersArray[i]];
//                uint256 fraction = bought.div(uint256(8));
//                for (uint8 j = 1; j <= 8; j++) {
//                    // addBeneficiary(uint _releaseDelay, uint _amount, address _token, address _beneficiary)
//                    chest.addBeneficiary(604800 * j, fraction, address(token), tokenBuyersArray[i]);
//                }
//            }

        } else {
            vault.enableRefunds();
            token.transfer(owner, token.balanceOf(address(this)));
        }
        // Transfer leftover tokens to owner
    }

    /**
    * User can claim tokens once the crowdsale has been finalized
    *
    * - first one 8th of their bought tokens is calculated
    * - then that 8th is multiplied by number of weeks past end of crowdsale date, up to 8, to get to a max of 100%
    * - then the code checks how much the user has withdrawn so far by subtracting amount of remaining tokens from total bought tokens per user
    * - then is the user is owed more than they withdrew, they are given the difference. If this difference is more than they have (should not happen), they are given it all
    * - remaining amount of tokens for user is reduced
    * - this method can be called by a third party, not just by the owner
    */
    function claimTokens(address _beneficiary) public {
        require(isFinalized);

        // Determine fraction of deserved tokens for user
        fractionalize(_beneficiary);

        // Need to be able to withdraw by having some
        require(tokenBuyersMapping[_beneficiary] > 0 && tokenBuyersRemaining[_beneficiary] > 0);

        // Max 8 because we're giving out 12.5% per week and 8 * 12.5% = 100%
        uint256 w = weeksFromEnd();
        if (w > 8) {
            w = 8;
        }
        // Total number of tokens user was due by now
        uint256 totalDueByNow = w.mul(tokenBuyersFraction[_beneficiary]);

        // How much the user has withdrawn so far
        uint256 totalWithdrawnByNow = totalWithdrawn(_beneficiary);

        if (totalDueByNow > totalWithdrawnByNow) {
            uint256 diff = totalDueByNow.sub(totalWithdrawnByNow);
            if (diff > tokenBuyersRemaining[_beneficiary]) {
                diff = tokenBuyersRemaining[_beneficiary];
            }
            token.transfer(_beneficiary, diff);
            tokenBuyersRemaining[_beneficiary] = tokenBuyersRemaining[_beneficiary].sub(diff);
        }
    }

    // Determine 1/8th of every user's contribution in their deserved tokens
    function fractionalize(address _beneficiary) internal {
        require(tokenBuyersMapping[_beneficiary] > 0);
        if (tokenBuyersFraction[_beneficiary] == 0) {
            tokenBuyersRemaining[_beneficiary] = tokenBuyersMapping[_beneficiary];
            // 8 because 100% / 12.5% = 8
            tokenBuyersFraction[_beneficiary] = tokenBuyersMapping[_beneficiary].div(8);
        }
    }

    // How many tokens a user has already withdrawn
    function totalWithdrawn(address _beneficiary) public view returns(uint256) {
        if (tokenBuyersFraction[_beneficiary] == 0) {
            return 0;
        }
        return tokenBuyersMapping[_beneficiary].sub(tokenBuyersRemaining[_beneficiary]);
    }

    // How many weeks, as a whole number, have passed since the end of the crowdsale
    function weeksFromEnd() public view returns(uint256){
        require(now > endTime);
        return percent(now - (now - endTime), 604800, 0);
    }

    // Withdraw all the leftover tokens if more than 2 weeks since the last withdraw opportunity for contributors has passed
    function withdrawRest() external onlyOwner {
        require(weeksFromEnd() > 9);
        token.transfer(owner, token.balanceOf(address(this)));
    }

    // Helper function to do rounded division
    function percent(uint numerator, uint denominator, uint precision) internal pure returns(uint256 quotient) {
        // caution, check safe-to-multiply here
        uint _numerator  = numerator * 10 ** (precision+1);
        // with rounding of last digit
        uint _quotient =  ((_numerator / denominator) + 5) / 10;
        return ( _quotient);
    }















    /**
    * Initiates a withdraw-all-due command on the chest, sending due tokens
    * Only callable if the crowdsale was successful and it's finished
    */
//    function withdrawAllDue() public onlyOwner {
//        require(isFinalized && goalReached());
//        chest.withdrawAllDue();
//    }

    function unsoldTokens() public view returns (uint) {
        if (token.balanceOf(address(this)) == 0) {
            return 0;
        }
        return token.balanceOf(address(this)) - tokenBuyersAmount;
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

