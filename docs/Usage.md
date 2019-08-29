## Overview

```console
Usage:
    minnie-kenny.sh
    -f | --force                Modify the git config to run git secrets
    -n | --no-force             Do not modify the git config only verify installation
    -s | --strict               Require git-secrets to be setup or fail
    -q | --quiet                Do not output any status messages
    -i | --include=FILE         Path to the include for git-config (default: "minnie-kenny.gitconfig")
```

## `-f` / `--force`
Modify the local git config if necessary.

If the expected calls to `git-secrets` are not found in any of the expected git hooks then `-f` will run
`git secrets --install`. If only some of the hooks are found then `-f` will exit with an error.

The committed minnie-kenny.gitconfig must also be included and allowed by git-secrets. Running with `-f` will check that
the minnie-kenny.gitconfig is configured correctly within the local git config.

The `-f` option overrides any previous `-n` option.

## `-n` / `--no-force`
Do not modify the local git installation, only verify that `git-secrets` is setup correctly.

The `-n` option overrides any previous `-f` option.

## `-s` / `--strict`
Normally `minnie-kenny.sh` will not error on systems without `git` installed. Nor will it error if the script is run
within a directory outside of a git working directory. When running with the strict argument then all warnings will
instead be treated as errors.

## `-q` / `--quiet`
Run silently and do not output any status messages.

## `-i` / `--include=FILE`
Change the default location of the git-config include from `minnie-kenny.gitconfig` to the provided path. The path is
always relative to the git working directory.
