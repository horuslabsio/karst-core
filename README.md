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

Check out the contract architecture below, and join our [working group](https://t.me/+DFfuHjLkeXlkNTg0).

<img width="100%" alt="Screenshot 2024-05-24 at 00 11 16" src="https://github.com/horuslabsio/karst-core/blob/main/img/architecture.png?raw=true">


## Contributing

BEFORE you start work on a feature or fix, please read and follow our [contribution guide](https://github.com/horuslabsio/karst-core/blob/master/CONTRIBUTING.md) to help avoid any wasted or duplicate effort.

## Security 

If you believe you have found a security vulnerability in our code, please report it to us as described in our [security policy](https://github.com/horuslabsio/karst-core/blob/master/SECURITY.md).

## License

KARST is an open-source software licensed under the [MIT](https://github.com/horuslabsio/karst-core/blob/master/LICENSE.md).

## Contributors

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tbody>
    <tr>
      <td align="center" valign="top" width="14.28%"><a href="http://mubarak23.github.io/"><img src="https://avatars.githubusercontent.com/u/7858376?v=4?s=100" width="100px;" alt="Mubarak Muhammad Aminu"/><br /><sub><b>Mubarak Muhammad Aminu</b></sub></a><br /><a href="#code-mubarak23" title="Code">💻</a> <a href="#review-mubarak23" title="Reviewed Pull Requests">👀</a> <a href="#infra-mubarak23" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a></td>
      <td align="center" valign="top" width="14.28%"><a href="http://0xdarlington.disha.page"><img src="https://avatars.githubusercontent.com/u/75126961?v=4?s=100" width="100px;" alt="Darlington Nnam"/><br /><sub><b>Darlington Nnam</b></sub></a><br /><a href="#infra-Darlington02" title="Infrastructure (Hosting, Build-Tools, etc)">🚇</a> <a href="#code-Darlington02" title="Code">💻</a> <a href="#review-Darlington02" title="Reviewed Pull Requests">👀</a></td>
    </tr>
  </tbody>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->