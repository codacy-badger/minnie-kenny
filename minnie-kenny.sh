#!/bin/sh
#   Use this script to ensure git-secrets are setup

set -eu # -o pipefail isn't supported by POSIX

minnie_kenny_command_name=${0##*/}
minnie_kenny_quiet=0
minnie_kenny_strict=0
minnie_kenny_gitconfig="minnie-kenny.gitconfig"

usage() {
  cat <<USAGE >&2
Usage:
    ${minnie_kenny_command_name}
    -s | --strict               Require git-secrets to be setup or fail
    -q | --quiet                Don't output any status messages
    -i | --include=FILE         Path to the include for git-config (default: "minnie-kenny.gitconfig")
USAGE
  exit 1
}

echo_out() { if [ ${minnie_kenny_quiet} -ne 1 ]; then echo "$@"; fi; }
echo_err() { if [ ${minnie_kenny_quiet} -ne 1 ]; then echo "$@" 1>&2; fi; }

# process arguments
while [ $# -gt 0 ]; do
  case "$1" in
    -q | --quiet)
      minnie_kenny_quiet=1
      shift 1
      ;;
    -s | --strict)
      minnie_kenny_strict=1
      shift 1
      ;;
    -i)
      shift 1
      minnie_kenny_gitconfig="${1:-}"
      if [ "${minnie_kenny_gitconfig}" = "" ]; then break; fi
      shift 1
      ;;
    --include=*)
      minnie_kenny_gitconfig="${1#*=}"
      shift 1
      ;;
    --help)
      usage
      ;;
    *)
      echo_err "Unknown argument: $1"
      usage
      ;;
  esac
done

if [ "${minnie_kenny_gitconfig}" = "" ]; then
  echo_err "Error: you need to provide an include file."
  usage
fi

if ! command -v git >/dev/null 2>&1; then
  if [ ${minnie_kenny_strict} -eq 0 ]; then
    echo_out "\`git\` not found. Not checking for git-secrets."
    exit 0
  else
    echo_err "Error: \`git\` not found."
    exit 1
  fi
fi

minnie_kenny_is_work_tree="$(git rev-parse --is-inside-work-tree 2>/dev/null || echo false)"

if [ "${minnie_kenny_is_work_tree}" != "true" ]; then
  if [ ${minnie_kenny_strict} -eq 0 ]; then
    echo_out "Not a git working tree. Not checking for git-secrets."
    exit 0
  else
    echo_err "Error: Not a git working tree."
    exit 1
  fi
fi

minnie_kenny_git_dir="$(git rev-parse --absolute-git-dir)"
if [ ! -f "${minnie_kenny_git_dir}/../${minnie_kenny_gitconfig}" ]; then
  echo_err "Error: ${minnie_kenny_gitconfig} was not found next to the directory ${minnie_kenny_git_dir}"
  exit 1
fi

if ! command -v git-secrets >/dev/null 2>&1; then
  echo_err "\`git-secrets\` was not found while \`git\` was found." \
    "\`git-secrets\` must be installed first before using ${minnie_kenny_command_name}." \
    "See https://github.com/awslabs/git-secrets#installing-git-secrets"
  exit 1
fi

is_secret_hook() {
  path="${minnie_kenny_git_dir}/hooks/$1"
  if grep -q "^git secrets " "${path}" 2>/dev/null; then
    echo 1
  else
    echo 0
  fi
}

check_and_install_hooks() {
  expected=0
  actual=0
  for path in "commit-msg" "pre-commit" "prepare-commit-msg"; do
    increment=$(is_secret_hook ${path})
    actual=$((actual + increment))
    expected=$((expected + 1))
  done

  if [ ${actual} -eq 0 ]; then
    git secrets --install
  elif [ ${actual} -ne ${expected} ]; then
    echo_err "Error: git-secrets is not installed into all of the expected .git hooks." \
      "Double check the 'commit-msg' 'pre-commit' and 'prepare-commit-msg'" \
      "under your ${minnie_kenny_git_dir}/hooks and consider running \`git secrets --install --force\`."
    exit 1
  fi

  # Allow the minnie-kenny config in `git secrets --scan`
  if ! git config --get-all secrets.allowed | grep -Fxq "^${minnie_kenny_gitconfig}:\\d+"; then
    git config --add secrets.allowed "^${minnie_kenny_gitconfig}:\\d+"
  fi

  # Allow minnie-kenny to appear in `git secrets --scan-history`
  if ! git config --get-all secrets.allowed | grep -Fxq "^[0-9a-f]+:${minnie_kenny_gitconfig}:\\d+"; then
    git config --add secrets.allowed "^[0-9a-f]+:${minnie_kenny_gitconfig}:\\d+"
  fi

  if ! git config --get-all include.path | grep -Fxq "../${minnie_kenny_gitconfig}"; then
    git config --add include.path "../${minnie_kenny_gitconfig}"
  fi
}

check_and_install_hooks
