## Overview

`minnie-kenny.sh` invokes `git secrets --install` to add the github hooks, and configures the `.git/config` to read from
`minnie-kenny.gitconfg`. To remove the configurations that `minnnie-kenny.sh` has installed:

## To remove the `minnie-kenny.sh` setup per repository

- edit the `.git/config`:
    - remove the `[secrets]` stanza
    - remove the `[include]` for `minnie-kenny.sh`
- remove any calls to `git secrets` in the hooks:
    - `.git/hooks/commit-msg`
    - `.git/hooks/pre-commit`
    - `.git/hooks/prepare-commit-msg`

## To remove the `git-secrets` from your system

- the `git secrets` script, usually installed at `/usr/local/bin/git-secrets`
- the `git secrets` man page, usually installed at `/usr/local/share/man/man1/git-secrets.1`
