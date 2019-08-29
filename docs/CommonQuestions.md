## Can I just configure GitHub, GitLab, Bitbucket, etc. to prevent secrets being allowed?

`git` as a command line program supports [server side pre-receive
hooks](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks#_server_side_hooks). However, these hooks are only
supported on self-hosted git repositories, usually under the "Enterprise" offerings.

Instead `minnie-kenny.sh` can be used to setup a shareable `git secrets` configuration, significantly reducing the
chance that secrets will be pushed to your publicly hosted git repository.

## Can `minnie-kenny.sh` install `git secrets` automatically?

Not currently. Like `git`, `git secrets` must be installed manually once per system. Once the program is available on
the `$PATH`, `minnie-kenny.sh` will ensure that the pre-commit hooks are configured correctly.

To install `git secrets`, follow the [installation instructions in the `git secrets`
readme](https://github.com/awslabs/git-secrets#installing-git-secrets).

## Even though I added `allowed` entries why am I getting false positives when `git secrets` runs on BusyBox / Alpine?

[Alpine](https://alpinelinux.org/about/), the tiny linux distribution based on
[BusyBox](https://busybox.net/about.html), includes a non-standard `grep` by default. This causes an issue where allowed
expressions are not processed by `git secrets`.

`git secrets` [loads the allowed](https://github.com/awslabs/git-secrets/blob/1.3.0/git-secrets#L63-L69) statements into
a multiline string. This string is then fed as the filter to `grep -v`. [The POSIX manual states
that](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/grep.html#tag_20_55_03):

> The pattern_list's value shall consist of one or more patterns separated by <newline> characters

> Since a &lt;newline&gt; separates or terminates patterns (see the -e and -f options below), regular expressions cannot
> contain a &lt;newline&gt;.

> -v Select lines not matching any of the specified pattern

On ubuntu we see that `bar` is successfully excluded via a multiline expression:

```console
$ docker run --rm ubuntu sh -c \
  "printf 'foo\nbar\nbaz' | grep -Ev \"\$(printf 'line1\nbar')\""
foo
baz
$
```

However on alpine and busybox the `bar` still ends up in the output:

```console
$ docker run --rm busybox sh -c \
  "printf 'foo\nbar\nbaz' | grep -Ev \"\$(printf 'line1\nbar')\""
foo
bar
baz
$
```

A workaround is to install [GNU grep](https://pkgs.alpinelinux.org/packages?name=grep&branch=edge) before using
`git secrets`:

```console
fetch http://dl-cdn.alpinelinux.org/alpine/v3.10/main/x86_64/APKINDEX.tar.gz
$ docker run --rm alpine sh -c \
  "apk update && apk add grep &&
  printf 'foo\nbar\nbaz' | grep -Ev \"\$(printf 'line1\nbar')\""
fetch http://dl-cdn.alpinelinux.org/alpine/v3.10/community/x86_64/APKINDEX.tar.gz
v3.10.1-110-g1e85ba7cf4 [http://dl-cdn.alpinelinux.org/alpine/v3.10/main]
v3.10.1-110-g1e85ba7cf4 [http://dl-cdn.alpinelinux.org/alpine/v3.10/community]
OK: 10337 distinct packages available
(1/2) Installing pcre (8.43-r0)
(2/2) Installing grep (3.3-r0)
Executing busybox-1.30.1-r2.trigger
OK: 6 MiB in 16 packages
foo
baz
$
```

`git secrets` already requires `bash` to run, so adding GNU's grep shouldn't be much more of an addition.

## How do I uninstall `minnie-kenny.sh` / `git secrets`?

`minnie-kenny.sh` invokes `git secrets --install` to add the github hooks, and configures the `.git/config` to read from
`minnie-kenny.gitconfg`. To remove the configurations that `minnnie-kenny.sh` has installed:

To remove the `minnie-kenny.sh` setup per repository:

- edit the `.git/config`:
    - remove the `[secrets]` stanza
    - remove the `[include]` for `minnie-kenny.sh`
- remove any calls to `git secrets` in the hooks:
    - `.git/hooks/commit-msg`
    - `.git/hooks/pre-commit`
    - `.git/hooks/prepare-commit-msg`

To remove the `git-secrets` from your system:

- the `git secrets` script, usually installed at `/usr/local/bin/git-secrets`
- the `git secrets` man page, usually installed at `/usr/local/share/man/man1/git-secrets.1`
