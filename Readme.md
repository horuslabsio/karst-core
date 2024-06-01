<!-- logo -->
<p align="center">
  <img width='300' src="https://avatars.githubusercontent.com/u/123994955?s=200&v=4">
</p>

<!-- primary badges -->
<p align="center">
  <a href="https://github.com/argentlabs/starknetkit/blob/main/LICENSE/">
    <img src="https://img.shields.io/badge/license-MIT-black">
  </a>
</p>

<div align="center">
<h1> Karst </h1>
</div>

Karst is a permissionless and composable social graph built on Starknet, empowering creators to own every part of their social experience.

With Karst, creators no longer need to worry about losing their content, audience, and livelihood based on the whims of an individual platform's algorithms and policies.

## Development Setup
You will need to have Scarb and Starknet Foundry installed on your system. Refer to the documentations below:

- [Starknet Foundry](https://foundry-rs.github.io/starknet-foundry/index.html)
- [Scarb](https://docs.swmansion.com/scarb/download.html)

To use this repository, first clone it:
```
git clone git@github.com:horuslabsio/karst-core.git
cd karst-core
```

### Building contracts
To build the contracts, run the command:
```
scarb build
```

### Running Tests
To run the tests contained within the `tests` folder, run the command:
```
snforge test
```

### Formatting contracts
We use the in-built formatter that comes with Scarb. To format your contracts, simply run the command:
```
scarb fmt
```

For more information on writing and running tests, refer to the [Starknet-Foundry documentation](https://foundry-rs.github.io/starknet-foundry/index.html)

## Architecture

Check out the contract architecture below.

<img width="100%" alt="Screenshot 2024-05-24 at 00 11 16" src="https://github.com/horuslabsio/karst-core/blob/main/img/architecture.png?raw=true">


