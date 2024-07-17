# Rush Contracts

![Foundry CI](https://github.com/rush-trading/contracts/actions/workflows/ci.yml/badge.svg)
[![Foundry][foundry-badge]][foundry]
[![License: UNLICENSED](https://img.shields.io/badge/License-UNLICENSED-blue.svg)](https://github.com/rush-trading/contracts/blob/main/LICENSE)

[foundry]: https://getfoundry.sh/
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg

## Overview

This repository contains the smart contracts of Rush.Trading. The contracts are written in Solidity and are tested using
Foundry.

## Setup

This project was built using [Foundry](https://book.getfoundry.sh/). Refer to installation instructions
[here](https://github.com/foundry-rs/foundry#installation).

```sh
git clone git@github.com:rush-trading/contracts.git rush-trading-contracts
cd rush-trading-contracts
bun install
```

## Scripts

To make it easier to perform some tasks within the repo, a few scripts are available via a `package.json` file.

### Build Scripts

| Script                   | Action                                                      |
| ------------------------ | ----------------------------------------------------------- |
| `bun run build`          | Compile all contracts.                                      |
| `bun run clean`          | Remove all cached and compiled files.                       |
| `bun run lint`           | Lint all files in the project.                              |
| `bun run lint:sol"`      | Lint all Solidity files in the project.                     |
| `bun run prettier:check` | Check formatting for all non-Solidity files in the project. |
| `bun run prettier:write` | Fix formatting for all non-Solidity files in the project.   |

### Test Scripts

| Script                         | Description                                                  |
| ------------------------------ | ------------------------------------------------------------ |
| `bun run gas:report`           | Generate gas report from all tests except those that revert. |
| `bun run test`                 | Run all Foundry tests.                                       |
| `bun run test:coverage`        | Run all Foundry tests and output coverage.                   |
| `bun run test:coverage:report` | Run all Foundry tests and generate coverage report.          |

Specific tests can be run using `forge test` conventions, specified in more detail in the Foundry
[Book](https://book.getfoundry.sh/reference/forge/forge-test#test-options).
