pragma solidity ^0.4.18;

import '../node_modules/zeppelin-solidity/contracts/token/ERC20/StandardToken.sol';

//contract ERC20Events {
//    event Approval(address indexed src, address indexed guy, uint wad);
//    event Transfer(address indexed src, address indexed dst, uint wad);
//}
//
//contract ERC20 is ERC20Events {
//    function totalSupply() public view returns (uint) {}
//    function balanceOf(address guy) public view returns (uint) {}
//    function allowance(address src, address guy) public view returns (uint) {}
//    function approve(address guy, uint wad) public returns (bool) {}
//    function transfer(address dst, uint wad) public returns (bool) {}
//    function transferFrom(address src, address dst, uint wad) public returns (bool) {}
//}

/**
* Todo: Add events
* Todo: Add UI
* Todo: Add contract's own publicly exposed token balance tracking
* Todo: Optimize lookups so that loop closes when number of times person was added or token was added is exceeded
*/
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

