# Karst

Karst is a web3 social graph on Starknet. it aims to build a social infrastructure for the starknet ecosystem.

## TODOS

- [ ] Implement `create profiles contract` functionality using `erc6551`
  - [x] Implement `create profile` functionality
  - [x] Implement `setProfileMetadataURI` functionality
  - [x] Write test for `createProfile` and related `profile` functions
- [ ] implement `Publications` contract
- [ ] Make contract upgradable, preferably uups.
  - [ ] implement `post` functionality
  - [ ] Implement `like` functionality
  - [ ] Implement `comment` functionality
  - [ ] Implement `mirror` functionality
  - [ ] Implement `quote` functionality
  - [ ] implement `tipPost` functionality
  - [ ] implement `follow` functionality from followNFT
- [ ] Implement `FollowNFT` contract
  - [ ] implement `unwrap` functionality
  - [ ] Implement `approveFollow` functionality
  - [ ] Implement `removeFollower` functionality
  - [ ] Implement `wrap` functionality
  - [ ] Implement `follow` functionality
  - [ ] Implement `unfollow` functionality
  - [ ] Implement `getOriginalFollowTimestamp` functionality
  - [ ] Implement `getFollowTimestamp` functionality
  - [ ] Implement `getProfileIdAllowedToRecover` functionality
  - [ ] Implement `getFollowData` functionality
  - [ ] Implement `getFollowApproved` functionality
  - [ ] Implement `getFollowerCount` functionality
- Implement `addDelegate` functionality
- [ ] Implement indexing of publish contract
  - [ ] indexing shall be done with [arweave](https://www.arweave.org/)
  - [ ] index all events emitted by the publications contract
- [ ] set up api endpoints to query the indexer
- [ ] not important at the moment
  - [ ] create a custom explorer for querying the content layer

## Remarks

our implementation may defer from lens by they both achieve the same goal
link to [Lens protocol](https://polygonscan.com/address/0x176c2a1c54e8b028eeec14bf0a059e354408ff47#code) contracts

## Architecture

Check out the architecture below, and also reference [lens protocol](https://github.com/lens-protocol/core/tree/master) to understand more.

*Architecture Preview.*
![Local Image](./img/karst%20archieture.png)
