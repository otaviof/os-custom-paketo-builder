#!/bin/bash

shopt -s inherit_errexit
set -eu -o pipefail

#
# Functions
#

function fail() {
    echo "ERROR: ${*}" 2>&1
    exit 1
}

function print_phase() {
    echo "---> Phase: ${*}..."
}

#
# Preparing the Environment
#

print_phase "Preparing the environment"

# the following environment variables are provided by the default by OpenShift Builds, providing
# essential information for the CNB lifecycle manager, however in a sightly different format
OUTPUT_REGISTRY_IMAGE="${OUTPUT_REGISTRY_IMAGE:-}"
PUSH_DOCKERCFG_PATH="${PUSH_DOCKERCFG_PATH:-}"

# making sure the required configuration environment varaibles are present
[[ ! -n "${OUTPUT_REGISTRY_IMAGE}" ]] && \
    fail "OUTPUT_REGISTRY_IMAGE environment varible is not set!"
[[ ! -n "${PUSH_DOCKERCFG_PATH}" ]] && \
    fail "PUSH_DOCKERCFG_PATH environment varible is not set!"

#
# Docker Config
#

print_phase "Preparing Container-Registry credentials"

# docker configuration directory path
DOCKER_CONFIG="${DOCKER_CONFIG:-}"

[[ ! -n "${DOCKER_CONFIG}" ]] && \
    fail "DOCKER_CONFIG environment varible is not set!"
[[ ! -d "${DOCKER_CONFIG}" ]] && \
    fail "'${DOCKER_CONFIG}' directory is not found!"

# complete secret file path mounted by OpenShift Builds (".spec.output.pushSecret.name"), the secret
# is mandatory since it controls the Container-Registry credentials.
DOCKER_CONFIG_PATH="${PUSH_DOCKERCFG_PATH}/.dockerconfigjson"

[[ ! -f "${DOCKER_CONFIG_PATH}" ]] && \
    fail "'${DOCKER_CONFIG_PATH}' is not found!"

# the CNB uses the Docker configuration format to load the Container Registry authentication details
# and OpenShift mounts the BuildConfig's ".spec.output.pushSecret" in the build container using a
# different file path than the CNB expects, this script is a worksaround to link the data to the
# conventional location
ln -sv "${DOCKER_CONFIG_PATH}" "${DOCKER_CONFIG}/config.json"

#
# Buildpacks Lifecycle
#

export CNB_LOG_LEVEL="debug"
export CNB_APP_DIR="."

if [ ! -d "${CNB_APP_DIR}" ]; then
    fail "'${CNB_APP_DIR}' is not found!"
fi

# making sure the application repository clone location is `rw` for the cnb user, for instance when
# building a Node.js application it needs to populate `node_modules` folder
print_phase "Changing the ownership of '${CNB_APP_DIR}' recursively (UID='${UID}')"
sudo chown -Rv cnb:cnb "${CNB_APP_DIR}"

print_phase "Files on '${CNB_APP_DIR}' ('PWD=${PWD}')"
ls -l ${CNB_APP_DIR}/

#
# CNB
#

print_phase "Running creator for image-tag '${OUTPUT_REGISTRY_IMAGE}'"
set -x
exec /cnb/lifecycle/creator \
    -log-level="${CNB_LOG_LEVEL}" \
    -app="${CNB_APP_DIR}" \
    "${OUTPUT_REGISTRY_IMAGE}"
