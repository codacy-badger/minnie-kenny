#!/usr/bin/env bash
#   Use this script to test minnie-kenny.sh

set -euo pipefail

minnie_kenny_bats_core_commit="c706d1470dd1376687776bbe985ac22d09780327"
minnie_kenny_git_secrets_commit="ad82d68ee924906a0401dfd48de5057731a9bc84"

case "${MINNIE_KENNY_TEST_TYPE:-bats}" in
  bats)
    # Run basic bats tests on multiple platforms
    if [[ "${TRAVIS:-}" == "true" ]]; then
      set -x
      git clone https://github.com/bats-core/bats-core.git
      pushd bats-core
      git checkout "${minnie_kenny_bats_core_commit}"
      ./install.sh "${HOME}"
      popd
      git clone https://github.com/awslabs/git-secrets.git
      pushd git-secrets
      git checkout "${minnie_kenny_git_secrets_commit}"
      case "${TRAVIS_OS_NAME}" in
        windows)
          powershell -Command "Unblock-File -Path install.ps1"
          powershell -File install.ps1
          ;;
        *) make DESTDIR="${HOME}" PREFIX="" install ;;
      esac
      popd
      export PATH="${PATH}:${HOME}/bin"
      set +x
    fi
    bats --tap test/
    ;;
  lint)
    # Ensure files are consistent
    minnie_kenny_lint_result=0
    if ! curl --fail --silent --data-binary @codecov.yml https://codecov.io/validate >/dev/null; then
      echo "Error: Codecov yaml validation failed. Double check the file contents." \
        "https://docs.codecov.io/docs/codecov-yaml#section-validate-your-repository-yaml" 1>&2
      minnie_kenny_lint_result=1
    fi
    if ! shfmt -i 2 -ci -d .; then
      echo "Error: Format files with \`shfmt -w -i 2 -ci .\`" \
        "to match https://google.github.io/styleguide/shell.xml" 1>&2
      minnie_kenny_lint_result=1
    fi
    if ! shfmt -f . | xargs shellcheck --check-sourced --external-sources; then
      echo "Error: Fix everything reported by \`shfmt -f . | xargs shellcheck --check-sourced --external-sources\`" 1>&2
      minnie_kenny_lint_result=1
    fi
    exit "${minnie_kenny_lint_result}"
    ;;
  alpine)
    # Ensure minnie-kenny.sh executes without error on /bin/sh even if git-secrets requires /bin/bash
    docker run \
      --rm \
      --volume "${PWD}/minnie-kenny.sh:/usr/local/bin/minnie-kenny.sh" \
      alpine \
      sh -c "set -xue && apk --update add git && mkdir -p /src && cd /src && touch minnie-kenny.inc && minnie-kenny.sh"
    ;;
  coverage)
    # Ensure all lines of minnie-kenny are covered
    minnie_kenny_main_dir="${PWD}"
    minnie_kenny_test_dir="${minnie_kenny_main_dir}/test"
    minnie_kenny_temp_dir="${minnie_kenny_test_dir}/tmp"
    minnie_kenny_kcov_out="${minnie_kenny_temp_dir}/kcov.out"
    minnie_kenny_bats_out="${minnie_kenny_temp_dir}/bats.out"
    # Use `tee` as `kcov` seems to send the `bats` stdout to... nowhere? Haven't found a existing git issue yet.
    minnie_kenny_bats_tee="${minnie_kenny_temp_dir}/bats-tee.sh"
    minnie_kenny_coverage_dir="${minnie_kenny_temp_dir}/coverage"
    minnie_kenny_coverage_tag="broadinstitute/minnie-kenny-coverage:temp"
    # Use the same $USER inside and outside the docker to keep files accessible while running as a non-root user
    #   https://github.com/bats-core/bats-core/issues/15
    #   https://github.com/SimonKagstrom/kcov/issues/234#issuecomment-363013297
    # Use useradd --no-log-init to keep Docker for Mac from filling up the disk
    #   https://github.com/moby/moby/issues/5419
    echo "\
      FROM kcov/kcov:v36
      ENTRYPOINT []
      RUN [\"/bin/bash\", \"-c\", \"set -xuo pipefail && \
        apt-get update && apt-get install -y git make && \
        mkdir -p /git && \
        git clone https://github.com/bats-core/bats-core.git /git/bats-core && \
        pushd /git/bats-core && git checkout '${minnie_kenny_bats_core_commit}' && ./install.sh /usr/local && popd && \
        git clone https://github.com/awslabs/git-secrets.git /git/git-secrets && \
        pushd /git/git-secrets && git checkout '${minnie_kenny_git_secrets_commit}' && make install && popd && \
        chmod a+rwx /usr/bin && \
        chmod a+rwx /usr/local/bin && \
        groupadd --gid $(id -g "${USER}") '${USER}' && \
        useradd --uid $(id -u "${USER}") --gid '${USER}' --no-log-init --no-create-home '${USER}'\"]
      USER '${USER}':'${USER}'
      ENV MINNIE_KENNY_DOCKER=true
    " | docker build --tag "${minnie_kenny_coverage_tag}" -
    mkdir -p "${minnie_kenny_coverage_dir}"
    docker run \
      --tty --rm \
      --volume "${minnie_kenny_main_dir}:${minnie_kenny_main_dir}" \
      --workdir "${minnie_kenny_main_dir}" \
      "${minnie_kenny_coverage_tag}" bash -c "
        printf '#!/bin/sh\nbats \"\$@\" | tee \"${minnie_kenny_bats_out}\"' >\"${minnie_kenny_bats_tee}\" && \
        chmod +x \"${minnie_kenny_bats_tee}\"
        kcov \
          \"--include-path=${minnie_kenny_main_dir}\" \
          \"--exclude-path=${minnie_kenny_test_dir}\" \
          \"${minnie_kenny_coverage_dir}\" \
          \"${minnie_kenny_bats_tee}\" --tap \"${minnie_kenny_test_dir}\" \
          2>\"${minnie_kenny_kcov_out}\"
        minnie_kenny_bats_exit_status=\$?
        if [[ \${minnie_kenny_bats_exit_status} -ne 0 ]]; then
          echo \"Contents of ${minnie_kenny_kcov_out}\"
          cat \"${minnie_kenny_kcov_out}\"
        fi
        echo \"Contents of ${minnie_kenny_bats_out}\"
        cat \"${minnie_kenny_bats_out}\"
        exit \${minnie_kenny_bats_exit_status}
      "
    if [[ "${TRAVIS:-}" == "true" ]]; then
      bash <(curl -s https://codecov.io/bash) -s "${minnie_kenny_coverage_dir}"
    fi
    ;;
esac
