# Initial version of the CryptoHunt ICO + Token

More information: [Cryptohuntgame.com](http://cryptohuntgame.com).

## Info

- Token is deployed at: 0xb5f42d711844997443fc72767ee55f43f95cd9cc
- ICO contract is CryptoHuntIco.sol
- Launching procedure:
  - Deploy ICO. First param is duration of whitelist period in seconds. Second is duration of regular period. This is ADDED to whitelist end, so 600, 600, means 10 minutes of whitelist followed by 10 minutes of regular, total 20 minutes. Third param is wallet to receive Ether on finalization, and fourth is the address of the deployed token (will be 0xb5f42d711844997443fc72767ee55f43f95cd9cc on Mainnet)
  - Send 300 million tokens to ICO contract. During testing, experiment with any ERC20 token all are supported. Launch a demo token for that purpose even.
  - Call the set rate and start function, params are rate (how many tokens per 1 ether), soft cap in Wei, and hard cap in Wei
- When ICO is done, call finalize()
- Every contributor can call ClaimMyTokens every week to get them (see Known Issues)

### Known issues

- claim tokens function pulls all tokens instantly instead of 12.5% per week - looks like weeksFromEnd() function is bugged
- owner cannot initiate mass forced-claim for users. Users need to do it themselves. Minor barrier, but [favorable](https://blog.zeppelin.solutions/onward-with-ethereum-smart-contract-security-97a827e47702)

### Alternative solutions

Use TokenTimedChestMulti.sol which was intended for periodic locking of tokens for the team, to be deployed later. Works fine but uses a lot of gas for so many contributors.