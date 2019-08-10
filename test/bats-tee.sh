#!/usr/bin/env bash
#   Use this script to capture bats results into a file since kcov seems to send the stdout to... nowhere?

set -euo pipefail

bats_tee_file="${1:-}"

if [[ -e "${bats_tee_file}" ]] && [[ ! -f "${bats_tee_file}" ]] || [[ -z "${bats_tee_file}" ]]; then
  echo "Error: Must specify a file to capture output, instead got '${bats_tee_file}'" 1>&2
  exit 1
else
  shift
  bats "$@" | tee "${bats_tee_file}"
fi
