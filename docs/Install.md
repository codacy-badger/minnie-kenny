## Adding `minnie-kenny.sh` to a git repository

### 1. Create `minnie-kenny.gitconfig` in the root of your git repository

The `minnie-kenny.gitconfig` is a standard [`git config`
file](https://git-scm.com/docs/git-config#_configuration_file). It has the exact same syntax as `.git/config`, but
unlike the files under the `.git` directory the `minnie-kenny.gitconfig` lives in the working directory of your
repository. Thus the configuration file is committed beside the rest of your version controlled software.

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

Additional secret configuration may be appended to the file. The command `git secrets --add` and
`git secrets --add-provider` modify the `.git/config` file directly. The additions to `.git/config` may be moved to
`minnie-kenny.gitconfig`, where they may then be committed to your git repository.

```bash
git add minnie-kenny.config
```

### 2. Download and add `minnie-kenny.sh` to your git repository

A raw `minnie-kenny.sh` should be downloaded from GitHub and added to your repository.

```bash
curl -O https://raw.githubusercontent.com/broadinstitute/minnie-kenny/master/minnie-kenny.sh
```

After reviewing the contents of the script, add it to your git repository.

```bash
git add minnie-kenny.sh
```

### 3. Run `minnie-kenny.sh` during your build's test process

`minnie-kenny.sh` is recommended to be run during the test phase of your build tool. The test phase is a compromise
between:

- Anyone testing changes to the code may likely be committing their changes back to git
- The users who are just building / assembling the code may not want to install `git secrets` on their system

Every build system allows you to run custom shell commands. As `minnie-kenny.sh` is pure POSIX shell script it should
run on most platforms.

Example languages, with links on how to run custom executables on some of their build tools:

- C / C++
    - [GNU Make](https://www.gnu.org/software/make/manual/html_node/Force-Targets.html#Force-Targets)
    - [B2](https://boostorg.github.io/build/manual/master/index.html#jam.language.rules.builtins.utility._shell__)
- Clojure / Groovy / Java / Kotlin / Scala
    - [Gradle](https://docs.gradle.org/current/dsl/org.gradle.api.tasks.Exec.html)
    - [Maven](https://www.mojohaus.org/exec-maven-plugin/)
    - [Mill](https://www.lihaoyi.com/mill/page/extending-mill.html#custom-targets--commands)
    - [Leiningen](https://github.com/hyPiRion/lein-shell#readme)
    - [sbt](https://www.scala-sbt.org/1.x/docs/Process.html)
- ECMAScript / JavaScript
    - [npm](https://docs.npmjs.com/misc/scripts#examples)
- Python
    - [Conda](https://docs.conda.io/projects/conda-build/en/latest/resources/define-metadata.html?highlight=test#test-commands)
    - [Distutils](https://docs.python.org/3/distutils/extending.html)
    - [Setuptools](https://setuptools.readthedocs.io/en/latest/setuptools.html#adding-commands)
- Ruby
    - [Rake](https://ruby.github.io/rake/FileUtils.html#method-i-sh)

If you would like to run the script as an executable via `./minnie-kenny.sh` you will need to
`chmod +x minnie-kenny.sh`. Alternatively if you do not want to give the script executable permissions then during your
tests execute `sh minnie-kenny.sh`.

## Adding `git secrets` to your CI test environment

After `minnie-kenny.sh` is installed in your git repository, your continuous integration (CI) test environment will
likely require an update also. When the CI runs tests it will look for the executable `git-secrets` within the `$PATH`.
If you have not already added `git secrets` to your CI, example `bash` installation instructions are:

```bash
# Clone the git-secrets repo
git clone https://github.com/awslabs/git-secrets.git

# Change directories to the git secrets directory
pushd git-secrets

# Checkout whatever version you'd like
git checkout 1.3.0

# Add the `git secrets` directory to the PATH
export PATH="${PATH}:${PWD}"

# Change back to the previous working directory
popd

# Continue running your tests...
```

After `minnie-kenny.sh` runs as part of your build scripts tests, you will also want your CI to run
`git secrets --scan-history` to check for secrets across all previous commits.
