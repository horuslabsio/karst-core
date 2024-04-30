# Karst

Karst is a web3 social graph on Starknet. it aims to build a social infrastructure for the starknet ecosystem.

## TODO

- [x] Implement `create profiles` functionality using `erc6551`
- [ ] implement `Publications` contract
- [ ] Make contract upgradable, preferably uups.
  - [ ] implement `post` functionality
  - [ ] Implement `like` parameter
  - [ ] Implement `comment` parameter
  - [ ] Implement `mirror` parameter
  - [ ] Implement `quote` parameter
- [ ] Implement indexing of publish contract
  - [ ] indexing shall be done with [arweave](https://www.arweave.org/)
  - [ ] index all events emitted by the publications contract
- [ ] set up api endpoints to query the indexer
- [ ] not important at the moment
  - [ ] create a custom explorer for querying the content layer

## Architecture

Check out the architecture below, and also reference [lens protocol](https://github.com/lens-protocol/core/tree/master) to understand more.

*Architecture Preview.*
![Local Image](./img/karst%20archieture.png)
