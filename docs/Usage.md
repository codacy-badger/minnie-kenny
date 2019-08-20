## Overview

```
Usage:
    minnie-kenny.sh
    -s | --strict               Require git-secrets to be setup or fail
    -q | --quiet                Don't output any status messages
    -i | --include=FILE         Path to the include for git-config (default: "minnie-kenny.gitconfig")
```

## `-s` / `--strict`
Normally `minnie-kenny.sh` will not error on systems without `git` installed. Nor will it error if the script is run
within a directory outside of a git working directory. When running with the strict argument then all warnings will
instead be treated as errors.

## `-q` / `--quiet`
Run silently and do not output any status messages.

## `-i` / `--include=FILE`
Change the default location of the git-config include from `minnie-kenny.gitconfig` to the provided path. The path is
always relative to the git working directory.
