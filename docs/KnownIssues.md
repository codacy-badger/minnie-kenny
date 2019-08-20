## Unable prevent secrets from being pushed to hosted GitHub, GitLab, Bitbucket, etc.

`git` supports [server side pre-receive
hooks](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks#_server_side_hooks). However, these hooks are only
supported on self-hosted git repositories, usually under the "Enterprise" offerings.

Instead `minnie-kenny.sh` can be used to setup a shareable `git secrets` configuration, reducing the chances that
secrets will be pushed to your publicly hosted git repository.

## `git secrets` is not automatically installed

Like `git`, `git secrets` must be installed manually once per system.

Follow the [installation instructions in the `git secrets`
readme](https://github.com/awslabs/git-secrets#installing-git-secrets).

## False positives when `git secrets` runs on Busybox, Alpine, etc.

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

```bash
$ docker run --rm ubuntu sh -c \
  "printf 'foo\nbar\nbaz' | grep -Ev \"\$(printf 'line1\nbar')\""
foo
baz
$
```

However on alpine and busybox the `bar` still ends up in the output:

```bash
$ docker run --rm busybox sh -c \
  "printf 'foo\nbar\nbaz' | grep -Ev \"\$(printf 'line1\nbar')\""
foo
bar
baz
$
```

A workaround is to install [GNU grep](https://pkgs.alpinelinux.org/packages?name=grep&branch=edge) before using
`git secrets`:

```bash
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
