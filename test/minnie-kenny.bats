#!/usr/bin/env bats

# Couldn't get `run` to work with kcov plus bats UNLESS:
# - Use `run bash` instead of just `run`
# - Run as a non-root user, as kcov plus bats did not produce output when run with `--bash-method=DEBUG`
#
# Hints:
# https://github.com/particleflux/kcov-bats-circleci-codeclimate/blob/5f14e0d/tests/hello.bats
# https://github.com/bats-core/bats-core/issues/15
# https://github.com/SimonKagstrom/kcov/issues/234#issuecomment-363013297
run_test() {
  run bash "${BATS_TEST_DIRNAME}/../minnie-kenny.sh" "$@"
}

minnie_kenny_test_dir=test/tmp/git_dir

# The minnie kenny usage message.
minnie_kenny_usage_trimmed="\
Usage:
    minnie-kenny.sh
    -s | --strict               Require git-secrets to be setup or fail
    -q | --quiet                Don't output any status messages
    -i | --include=FILE         Path to the include for git-config (default: \"minnie-kenny.inc\")"

# The minnie kenny usage message with a leading newline.
minnie_kenny_usage=$'\n'"${minnie_kenny_usage_trimmed}"

# Reset the environment for a test
setup() {
  mkdir -p "${minnie_kenny_test_dir}"
  pushd "${minnie_kenny_test_dir}" || exit 1
  rm -rf .git  minnie-kenny.inc
  git init >/dev/null 2>&1
  git config user.email "minnie-kenny-test@example.com"
  git config user.name "minnie-kenny-test"
  touch minnie-kenny.inc
  popd || exit 1
  export GIT_DIR="${minnie_kenny_test_dir}/.git"
}

# Use this function if something doesn't work as expected.
# Prints in the TAP format for bats https://github.com/bats-core/bats-core/tree/v1.1.0#printing-to-the-terminal
# Example:
#   echo_dbg "${output}"
echo_dbg() {
  echo "$@" | sed 's/^/# /' >&3
}

# Call this right after run_test to print out the status and output
run_dbg() {
  echo_dbg "Debug: output"
  echo_dbg "${output}"
  echo_dbg "Debug: status ${status}"
}

skip_test_if_not_docker() {
  if [[ "${MINNIE_KENNY_DOCKER:-}" != "true" ]]; then
    skip
  fi
}

@test "print help" {
  run_test --help
  [ "${status}" -eq 1 ]
  [ "${output}" = "${minnie_kenny_usage_trimmed}" ]
}

@test "running with no git-secrets hooks succeeds" {
  run_test
  [ "${status}" -eq 0 ]
  check_mark="$(tput setaf 2)✓$(tput sgr 0)"
  expected="\
${check_mark} Installed commit-msg hook to ${minnie_kenny_test_dir}/.git/hooks/commit-msg
${check_mark} Installed pre-commit hook to ${minnie_kenny_test_dir}/.git/hooks/pre-commit
${check_mark} Installed prepare-commit-msg hook to ${minnie_kenny_test_dir}/.git/hooks/prepare-commit-msg"
  [ "${output}" = "${expected}" ]
}

@test "running with all git-secrets hooks succeeds" {
  run_test
  run_test
  [ "${status}" -eq 0 ]
  [ "${output}" = "" ]
}

@test "running with some git-secrets hooks fails" {
  run_test
  rm "${minnie_kenny_test_dir}/.git/hooks/pre-commit"
  run_test
  [ "${status}" -eq 1 ]
  minnie_kenny_git_dir="$(git rev-parse --absolute-git-dir)"
  expected="\
Error: git-secrets is not installed into all of the expected .git hooks. \
Double check the 'commit-msg' 'pre-commit' and 'prepare-commit-msg' \
under your ${minnie_kenny_git_dir}/hooks and consider running \`git secrets --install --force\`."
  [ "${output}" = "${expected}" ]
}

@test "running without a minnie-kenny.inc fails" {
  rm "${minnie_kenny_test_dir}/minnie-kenny.inc"
  run_test
  [ "${status}" -eq 1 ]
  expected="Error: minnie-kenny.inc was not found next to the directory $(git rev-parse --absolute-git-dir)"
  [ "${output}" = "${expected}" ]
}

@test "running with a made up include fails" {
  run_test -i "made-up"
  [ "${status}" -eq 1 ]
  expected="Error: made-up was not found next to the directory $(git rev-parse --absolute-git-dir)"
  [ "${output}" = "${expected}" ]
}

@test "running when the .git directory is not found succeeds" {
  rm -rf "${minnie_kenny_test_dir}/.git"
  run_test
  [ "${status}" -eq 0 ]
  [ "${output}" = "Not a git working tree. Not checking for git-secrets." ]
}

@test "running when the .git directory is not found and quiet succeeds" {
  rm -rf "${minnie_kenny_test_dir}/.git"
  run_test -q
  [ "${status}" -eq 0 ]
  [ "${output}" = "" ]
}

@test "running when the .git directory is not found and strict fails" {
  rm -rf "${minnie_kenny_test_dir}/.git"
  run_test -s
  [ "${status}" -eq 1 ]
  [ "${output}" = "Error: Not a git working tree." ]
}

@test "running when the .git directory is not found, strict, and quiet fails" {
  rm -rf "${minnie_kenny_test_dir}/.git"
  run_test -s -q
  [ "${status}" -eq 1 ]
  [ "${output}" = "" ]
}

@test "running without an argument for -i fails" {
  run_test -i
  [ "${status}" -eq 1 ]
  [ "${output}" = "Error: you need to provide an include file.${minnie_kenny_usage}" ]
}

@test "running without an argument for --include= fails" {
  run_test --include=
  [ "${status}" -eq 1 ]
  [ "${output}" = "Error: you need to provide an include file.${minnie_kenny_usage}" ]
}

@test "running with an invalid argument fails" {
  run_test --foo
  [ "${status}" -eq 1 ]
  [ "${output}" = "Unknown argument: --foo${minnie_kenny_usage}" ]
}

@test "running when git is not installed succeeds" {
  skip_test_if_not_docker
  git_path="$(which git)"
  mv "${git_path}" "${git_path}.bak"
  run_test
  mv "${git_path}.bak" "${git_path}"
  [ "${status}" -eq 0 ]
  [ "${output}" = "\`git\` not found. Not checking for git-secrets." ]
}

@test "running when git is not installed and strict fails" {
  skip_test_if_not_docker
  git_path="$(which git)"
  mv "${git_path}" "${git_path}.bak"
  run_test -s
  mv "${git_path}.bak" "${git_path}"
  [ "${status}" -eq 1 ]
  [ "${output}" = "Error: \`git\` not found." ]
}

@test "running when git-secrets is not installed fails" {
  skip_test_if_not_docker
  git_secrets_path="$(which git-secrets)"
  mv "${git_secrets_path}" "${git_secrets_path}.bak"
  run_test
  mv "${git_secrets_path}.bak" "${git_secrets_path}"
  expected="\
\`git-secrets\` was not found while \`git\` was found. \
\`git-secrets\` must be installed first before using minnie-kenny.sh. \
See https://github.com/awslabs/git-secrets#installing-git-secrets"
  [ "${status}" -eq 1 ]
  [ "${output}" = "${expected}" ]
}

@test "committing secrets with an empty minnie-kenny.inc succeeds" {
  run_test
  [ "${status}" -eq 0 ]
  temp_file="${minnie_kenny_test_dir}/file-with-secrets.txt"
  echo "This is my_super_secret content" >"${temp_file}"
  git add --force "${temp_file}"
  run git commit --message="This should get rejected, but doesn't because the minnie-kenny.inc is not populated"
  [ "${status}" -eq 0 ]
}

@test "committing secrets with a non-empty minnie-kenny.inc fails" {
  cat <<CONFIG >"${minnie_kenny_test_dir}/minnie-kenny.inc"
[secrets]
	patterns = my_super_secret
CONFIG
  run_test
  [ "${status}" -eq 0 ]
  temp_file="${minnie_kenny_test_dir}/file-with-secrets.txt"
  echo "This is my_super_secret content" >"${temp_file}"
  git add --force "${temp_file}"
  run git commit --message="This should get rejected"
  [ "${status}" -eq 1 ]
  expected="\
${temp_file}:1:This is my_super_secret content

[ERROR] Matched one or more prohibited patterns

Possible mitigations:
- Mark false positives as allowed using: git config --add secrets.allowed ...
- Mark false positives as allowed by adding regular expressions to .gitallowed at repository's root directory
- List your configured patterns: git config --get-all secrets.patterns
- List your configured allowed patterns: git config --get-all secrets.allowed
- List your configured allowed patterns in .gitallowed at repository's root directory
- Use --no-verify if this is a one-time false positive"
  [ "${output}" = "${expected}" ]
}
