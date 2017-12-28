pragma solidity ^0.4.4;

import "zeppelin-solidity/contracts/crowdsale/CappedCrowdsale.sol";
import "zeppelin-solidity/contracts/crowdsale/RefundableCrowdsale.sol";
import "zeppelin-solidity/contracts/token/MintableToken.sol";
import "zeppelin-solidity/contracts/token/BurnableToken.sol";

/**
 * @title CryptoHunt Token
 */
contract CryptoHuntToken is MintableToken, BurnableToken {

    string public constant name = "CryptoHunt Token";
    string public constant symbol = "CH";
    uint8 public constant decimals = 18;

}

/**
 * @title CryptoHunt ICO
 * CappedCrowdsale - sets a max boundary for raised funds
 * RefundableCrowdsale - set a min goal to be reached and returns funds if it's not met
 */
contract CryptoHuntIco is CappedCrowdsale, RefundableCrowdsale {

    mapping (address => bool) wl;

    event Whitelisted(address addr, bool status);

    function whitelistAddress (address[] users) onlyOwner external {
        for (uint i = 0; i < users.length; i++) {
            wl[users[i]] = true;
            Whitelisted(users[i], true);
        }
    }

    function buyTokens(address beneficiary) public payable {
        require(wl[beneficiary]);
        super.buyTokens(beneficiary);
    }

    function CryptoHuntIco(uint256 _startTime, uint256 _endTime, uint256 _rate, uint256 _goal, uint256 _cap, address _wallet) public
    CappedCrowdsale(_cap)
    FinalizableCrowdsale()
    RefundableCrowdsale(_goal)
    Crowdsale(_startTime, _endTime, _rate, _wallet)
    {
        //As goal needs to be met for a successful crowdsale
        //the value needs to less or equal than a cap which is limit for accepted funds
        require(_goal <= _cap);
    }

    function createTokenContract() internal returns (StandardToken) {
        return new CryptoHuntToken();
    }

}
