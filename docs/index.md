## Welcome

`minnie-kenny.sh` is a POSIX shell script that ensures `git secrets` is correctly installed and consistently configured.

[`git secrets`](https://github.com/awslabs/git-secrets#readme) "prevents you from committing passwords and other
sensitive information to a git repository." Even after the executable is installed, it must be then configured correctly
on **every** git repository. Otherwise no secrets are prevented from being committed. Additionally by default the
secrets configuration is not shared in git repository and is instead configured per user device.

What `minnie-kenny.sh` does:

- Enables prohibited and allowed `git secrets` patterns to be version controlled in git
- Anyone running your tests who has `git` installed will also test that `git secrets` is installed
- Once `minnie-kenny.sh` completes the `git secrets` configuration once all future `git commits` are protected

What `minnie-kenny.sh` does not do:

- Does not require those who download a zip/tar of your code to install `git secrets`
- Does not install the `git secrets` executable, it must be installed once per system, like `git`
- Does not require `bash` by itself, though the `git secrets` command does

The script is [inspired by and based upon](Acknowledgments/) a number of individuals and open source projects.

## Quick start

1. Create `minnie-kenny.gitconfig` in the root of your git repository
2. Download and add `minnie-kenny.sh` to your git repository
3. Run `minnie-kenny.sh` during your build's test process

Example `minnie-kenny.gitconfig`:

```gitconfig
# NOTE: The stanza [secrets] must be included to be a valid git-config file
[secrets]
    providers = git secrets --aws-provider
    patterns = (A3T[A-Z0-9]|AKIA|AGPA|AIDA|AROA|AIPA|ANPA|ANVA|ASIA)[A-Z0-9]{16}
    patterns = (\"|')?(AWS|aws|Aws)?_?(SECRET|secret|Secret)?_?(ACCESS|access|Access)?_?(KEY|key|Key)(\"|')?\\s*(:|=>|=)\\s*(\"|')?[A-Za-z0-9/\\+=]{40}(\"|')?
    patterns = (\"|')?(AWS|aws|Aws)?_?(ACCOUNT|account|Account)_?(ID|id|Id)?(\"|')?\\s*(:|=>|=)\\s*(\"|')?[0-9]{4}\\-?[0-9]{4}\\-?[0-9]{4}(\"|')?
    allowed = AKIAIOSFODNN7EXAMPLE
    allowed = wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
    # NOTE: The above example is the equivalent of `git secrets --register-aws`. Futher customize for your own git repo.
```

Additional secret configuration may be appended to the file. See the [full Install instructions](Install/) for more
information.

## Issues

`minnie-kenny.sh` issues are tracked on the DSP Workbench JIRA under the [Batch
Board](https://broadworkbench.atlassian.net/projects/BA/issues). You will likely need to sign up before being to view or
create issues.

[Known Issues](KnownIssues/) are listed in the documentation.

## License

`minnie-kenny.sh` is open sourced under the [BSD 3-Clause
license](https://github.com/broadinstitute/minnie-kenny/blob/ks_first_draft/LICENSE.txt).
