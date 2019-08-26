## Issue tracking

`minnie-kenny.sh` issues are tracked on the [DSP
Workbench](https://www.broadinstitute.org/data-sciences-platform/workbench) JIRA under [Batch
Analysis](https://broadworkbench.atlassian.net/projects/BA/issues). You will need to sign up with a free account before
being able to view or create issues.

Several known issues are listed in the documentation under [Common Questions](../CommonQuestions/).

## Code style

`minnie-kenny.sh` is mostly formatted according to the [Google Shell Style
Guide](https://google.github.io/styleguide/shell.xml).

Exceptions to the original style guide:

- Uses POSIX compatible `sh`
- Uses an `.sh` extension
- Lines are 120 characters
- Uses a `-` in the source file name

## Tests

See [Testing](../Testing/) for a list of existing tests. Before any [pull requests](#pull-requests) will be accepted, all
existing and new tests must pass, including `lint` and `coverage`. If your additions to `minnie-kenny.sh` are not
covered then add a new test. If you are having trouble designing a coverage test please mention it in the Jira ticket
covering your [issue](#issue-tracking) / [pull request](#pull-requests).

## Documentation

The documentation source files are available in
[GitHub under /docs](https://github.com/broadinstitute/minnie-kenny/tree/master/docs). The documentation is built using
[MkDocs](https://www.mkdocs.org), and may rendered locally using `mkdocs serve`.

## Pull requests

Updates are welcome and may be submitted via [GitHub pull
requests](https://github.com/broadinstitute/minnie-kenny/pulls).

Every pull request should refer to a Jira issue in the description. See above under [Issue Tracking](#issue-tracking)
for information on Jira. The pull request description should contain the string "BA-#" where "#" is the Jira issue
number, for example "My latest pull request BA-99999".

After the pull request is created, a commit to the same PR should also link to the PR within the
[CHANGELOG.md](https://github.com/broadinstitute/minnie-kenny/tree/master/CHANGELOG.md).

Before submitting pull requests please be sure to also verify and update if necessary:

- [Code style](#code-style)
- [Tests](#tests)
- [Documentation](#documentation)

## License

`minnie-kenny.sh` is open sourced under the [BSD 3-Clause
license](https://github.com/broadinstitute/minnie-kenny/blob/master/LICENSE.txt).
