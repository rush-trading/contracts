# Rush Trading

![Foundry CI](https://github.com/rush-trading/contracts/actions/workflows/ci.yml/badge.svg)
[![Foundry][foundry-badge]][foundry]
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://github.com/rush-trading/contracts/blob/main/LICENSE)

[foundry]: https://getfoundry.sh/
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg

## Overview

This repository contains the smart contracts of Rush.Trading. The contracts are written in Solidity and are tested using
Foundry.

## Architecture

Rush Trading utilizes a modular architecture, with each module being a separate contract. This allows for scalability
and flexibility in the future.

### Branching Tree Technique

You may notice that some test files are accompanied by `.tree` files. This is called the Branching Tree Technique, and
the goal is to structure the tests systematically, making it easier to cover all possible test cases.

The Branching Tree Technique is explained in detail here:

- [X/Twitter: Branching Tree Technique](https://x.com/PaulRBerg/status/1682346315806539776)
- [EthCC 2023](https://prberg.com/presentations/ethcc-2023)
- [Spearbit seminar](https://prberg.com/presentations/spearbit-2023)

## Setup

This project was built using [Foundry](https://book.getfoundry.sh/). Refer to installation instructions
[here](https://github.com/foundry-rs/foundry#installation).

```sh
git clone git@github.com:rush-trading/contracts.git rush-trading-contracts
cd rush-trading-contracts
bun install
```

## Scripts

To make it easier to perform some tasks within the repo, a few scripts are available via a
[package.json](./package.json#L20) file.

### Build Scripts

| Script                   | Action                                                      |
| ------------------------ | ----------------------------------------------------------- |
| `bun run build`          | Compile all contracts.                                      |
| `bun run clean`          | Remove all cached and compiled files.                       |
| `bun run lint`           | Lint all files in the project.                              |
| `bun run lint:sol`       | Lint all Solidity files in the project.                     |
| `bun run prettier:check` | Check formatting for all non-Solidity files in the project. |
| `bun run prettier:write` | Fix formatting for all non-Solidity files in the project.   |

### Test Scripts

Make sure to create a local `.env` file and add the necessary `API_KEY_ALCHEMY` environment variable to be able to run
fork tests. You can use the provided [`.env.example`](./.env.example) file as a template.

| Script                         | Description                                                         |
| ------------------------------ | ------------------------------------------------------------------- |
| `bun run gas:report`           | Output gas report from all tests except those that revert.          |
| `bun run gas:snapshot`         | Generate gas snapshot file from all tests except those that revert. |
| `bun run test`                 | Run all Foundry tests.                                              |
| `bun run test:coverage`        | Run all Foundry tests and output coverage.                          |
| `bun run test:coverage:report` | Run all Foundry tests and generate coverage report.                 |

Specific tests can be run using `forge test` conventions, specified in more detail in the Foundry
[Book](https://book.getfoundry.sh/reference/forge/forge-test#test-options).

## Deployment

Deployment instructions can be found in the [DEPLOYMENT.md](./DEPLOYMENT.md) file.
