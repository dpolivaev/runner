#!/bin/bash -Eeu

readonly MY_NAME=`basename "${BASH_SOURCE[0]}"`

if [ "${1:-}" == '-h' ] || [ "${1:-}" == '--help' ]; then
  echo
  echo "Use: ${MY_NAME} [client|server] [ID...]"
  echo 'Options:'
  echo '   client  - only run the tests from inside the client'
  echo '   server  - only run the tests from inside the server'
  echo '   ID...   - only run the tests matching these identifiers'
  echo
  exit 0
fi

readonly SH_DIR="$(cd "$(dirname "${0}")/sh" && pwd )"
source ${SH_DIR}/versioner_env_vars.sh
export $(versioner_env_vars)

readonly client_user="${CYBER_DOJO_RUNNER_CLIENT_USER}"
readonly server_user="${CYBER_DOJO_RUNNER_SERVER_USER}"

${SH_DIR}/build_images.sh
${SH_DIR}/tag_image.sh
if [ "${1:-}" == '--build-only' ] || [ "${1:-}" == '-bo' ] ; then
  exit 0
fi
${SH_DIR}/tear_down.sh
${SH_DIR}/containers_up.sh
${SH_DIR}/on_ci_pull_dependent_images.sh
${SH_DIR}/test_in_containers.sh "${client_user}" "${server_user}" "$@"
${SH_DIR}/containers_down.sh
${SH_DIR}/on_ci_publish_tagged_images.sh
#${SH_DIR}/trigger_dependent_images.sh
