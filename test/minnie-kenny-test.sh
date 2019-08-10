#!/usr/bin/env bash
#   Use this script to test minnie-kenny.sh

set -euo pipefail

case "${MINNIE_KENNY_TEST_TYPE:-standard}" in
  standard)
    # Run standard tests on multiple platforms
    case "${TRAVIS_OS_NAME:-}" in
      osx)
        brew install bats-core
        ;;
      windows)
        git clone https://github.com/bats-core/bats-core.git
        pushd bats-core
        ./install.sh "${HOME}"
        popd
        export PATH="${PATH}:${HOME}/bin"
        ;;
      linux)
        git clone https://github.com/bats-core/bats-core.git
        pushd bats-core
        ./install.sh "${HOME}"
        popd
        export PATH="${PATH}:${HOME}/bin"
        ;;
    esac
    bats test/
    ;;
  format)
    # Ensure files are formatted consistently
    minnie_kenny_format_result=0
    if ! curl --fail --silent --data-binary @codecov.yml https://codecov.io/validate >/dev/null; then
      echo "Error: Codecov yaml validation failed. Double check the file contents." \
        "https://docs.codecov.io/docs/codecov-yaml#section-validate-your-repository-yaml" 1>&2
      minnie_kenny_format_result=1
    fi
    if ! shfmt -i 2 -ci -d .; then
      echo "Error: Files must be formatted with \`shfmt -w -i 2 -ci .\`" \
        "to match https://google.github.io/styleguide/shell.xml" 1>&2
      minnie_kenny_format_result=1
    fi
    if ! shfmt -f . | xargs shellcheck --check-sourced --external-sources; then
      minnie_kenny_format_result=1
    fi
    exit "${minnie_kenny_format_result}"
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
    set -x
    ls -al .
    ls -al test
    echo "\
      FROM kcov/kcov:v36
      ENTRYPOINT []
      RUN [\"/bin/bash\", \"-c\", \"set -xuo pipefail && \
          apt-get update && apt-get install -y git make && \
          mkdir -p /git && \
          git clone https://github.com/bats-core/bats-core.git /git/bats-core && \
          pushd /git/bats-core && git checkout c706d14 && ./install.sh /usr/local && popd && \
          git clone https://github.com/awslabs/git-secrets.git /git/git-secrets && \
          pushd /git/git-secrets && git checkout ad82d68 && make install && popd && \
          chmod a+rwx /usr/bin && \
          chmod a+rwx /usr/local/bin && \
          groupadd --gid $(id -g ${USER}) minnie-kenny && \
          useradd --uid $(id -u ${USER}) --gid $(id -g ${USER}) --no-log-init --no-create-home minnie-kenny\"]
      USER minnie-kenny:minnie-kenny
      ENV MINNIE_KENNY_DOCKER=true\
    " | docker build --tag broadinstitute/minnie-kenny-test-coverage -
    minnie_kenny_main_dir="${PWD}"
    minnie_kenny_test_dir="${minnie_kenny_main_dir}/test"
    minnie_kenny_temp_dir="${minnie_kenny_test_dir}/tmp"
    minnie_kenny_bats_out="${minnie_kenny_temp_dir}/bats.out"
    minnie_kenny_coverage_dir="${minnie_kenny_temp_dir}/coverage"
    mkdir -p "${minnie_kenny_coverage_dir}"
    docker run \
      --tty --rm \
      --volume "${minnie_kenny_main_dir}:${minnie_kenny_main_dir}" \
      --workdir "${minnie_kenny_main_dir}" \
      broadinstitute/minnie-kenny-test-coverage \
      bash -c "
        kcov \
          \"--include-path=${minnie_kenny_main_dir}\" \
          \"--exclude-path=${minnie_kenny_test_dir}\" \
          \"${minnie_kenny_coverage_dir}\" \
          \"${minnie_kenny_test_dir}/bats-tee.sh\" \
          \"${minnie_kenny_bats_out}\" \
          --pretty \
          \"${minnie_kenny_test_dir}\"
        minnie_kenny_bats_exit_status=\$?
        cat \"${minnie_kenny_bats_out}\"
        exit \${minnie_kenny_bats_exit_status}
      "
    if [[ "${TRAVIS:-}" == "true" ]]; then
      bash <(curl -s https://codecov.io/bash) -s "${minnie_kenny_coverage_dir}"
    fi
    ;;
esac
