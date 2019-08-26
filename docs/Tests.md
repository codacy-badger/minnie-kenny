## `test/minnie-kenny-test.sh`

These various tests ensure that any updates to `minnie-kenny.sh` continue working as expected.

Each test requires a different set of software be installed on the system running the tests.

## bats

Ensures `minnie-kenny.sh` runs on any `bash` compatible system.

This test requires that your system has installed:

- [`bats`](https://github.com/bats-core/bats-core#installation)
- [`git`](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- [`git-secrets`](https://github.com/awslabs/git-secrets#installing-git-secrets)

```bash
test/minnie-kenny-test.sh bats
```

The full list of bats tests are stored in [GitHub under
/test/minnie-kenny.bats](https://github.com/broadinstitute/minnie-kenny/tree/master/test/minnie-kenny.bats). However,
this test skips tests that require modifications to the host system, which instead are checked during `coverage` tests.

## coverage

This is an extension of the `bats` tests. It ensures that all of the lines in `minnie-kenny.sh` are covered.

This test requires that your system has installed:

- [`docker`](https://www.docker.com)

```bash
test/minnie-kenny-test.sh coverage
```

A Docker image will be built with all of the requirements to run all of the `bats` tests. The full suite of bats tests
will then run inside of a temporary Docker container. The results may be viewed by opening
`test/tmp/coverage/index.html` in your browser.

## alpine

This tests that even if `git secrets` requires `bash` that `minnie-kenny.sh` will run on a system without `bash`
installed.

This test requires that your system has installed:

- [`docker`](https://www.docker.com)

```bash
test/minnie-kenny-test.sh alpine
```

## lint

Ensures that files are consistent.

This test requires that your system has installed:

- [`mkdocs`](https://www.mkdocs.org/#installation)
- [`shellcheck`](https://github.com/koalaman/shellcheck#installing)
- [`shfmt`](https://github.com/mvdan/sh#shfmt)

```bash
test/minnie-kenny-test.sh lint
```

## clean

Tests deposit temporary files under `test/tmp`. These can be removed via `clean`.

```bash
test/minnie-kenny-test.sh clean
```

You cannot mix `clean` with the other tests types. It must be run separately.

```bash
test/minnie-kenny-test.sh clean && test/minnie-kenny-test.sh bats
```
