# Election Smart Contract

![Foundry CI](https://github.com/InnocentInnocentdb/election-smart-contract/actions/workflows/test.yml/badge.svg)

A Solidity election contract — reviewed, bug-fixed, and extended with party support — backed by a full Foundry test suite verified continuously through GitHub Actions. Assignment 3.

## Overview

The contract lets a chairman register candidates and (optionally) political parties, register eligible voters, run an election from start to end, and determine a winner — with every rule enforced on-chain: only the chairman can administer the election, only registered adults can vote, and nobody can vote twice.

## Bugs Identified and Fixed

The original contract compiled, but several bugs meant it couldn't actually run an election:

- **Chairman was never set** — declared but never assigned, so it permanently equalled `address(0)` and no chairman-only action could ever succeed.
- **`createCandidates()` recorded the wrong id, against the wrong address** — every candidate was hardcoded to id `1`, stored against the chairman's address instead of the candidate's.
- **`registerVoters()` had its access check backwards** — it required the *voter* to be the chairman, rather than the *caller*.
- **`vote()` re-registered a voter instead of checking registration**, and tracked the wrong address for double-vote prevention.
- **`winner()` indexed the candidates array off by one**, and didn't guard against there being no leader yet.
- **`removeCandidates()` took no parameter** — it always deleted the chairman's own entry.
- **`getWinner()` had no return statement** — an empty body with a declared return type, which fails to compile until completed.
- Minor: misspelled SPDX tag, and dead/unused state variables.

## Extra Logic Added

- `onlyChairman` modifier and a constructor to fix the root cause of several bugs above
- `endElection()` / `isElectionActive()` — completes the election lifecycle
- `assignCandidateToParty()` — links a candidate to a party once parties exist
- `getWinnerDetails()`, `getCandidateCount()`, `getPartyCount()`, `getAllCandidates()` — read-only conveniences
- Events on every state-changing action, and clearly named custom errors throughout

## Completed Functions

- `createParties(string memory _partyName) returns (uint256)`
- `getWinner() returns (uint256)`

## Project Structure

```
├── foundry.toml
├── src/
│   └── election.sol
├── test/
│   └── Election.t.sol
└── .github/
    └── workflows/
        └── test.yml
```

## Test Coverage

40 checks across 9 stages, run automatically on every push via GitHub Actions:

1. Deployment & chairman assignment
2. `createCandidates()` — happy path and every revert case
3. `createParties()` — happy path and duplicate-name revert
4. `assignCandidateToParty()`
5. Election lifecycle — start/end and their guards
6. `registerVoters()` — happy path, under-18 revert, non-chairman revert
7. `vote()` — happy path and every revert path
8. `getWinner()` / `getWinnerDetails()` — including tie-handling and leader changes
9. `removeCandidates()` — happy path, double-remove, and voting-after-removal

## Running the Tests

```
forge install foundry-rs/forge-std --no-commit
forge test -vvv
```

Or simply push — the workflow in `.github/workflows/test.yml` runs `forge build` and `forge test` automatically on a clean container every time.
