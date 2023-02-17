#!/bin/bash

shopt -s inherit_errexit
set -xeu -o pipefail

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
OUTPUT_REGISTRY="${OUTPUT_REGISTRY:-}"
OUTPUT_IMAGE="${OUTPUT_IMAGE:-}"
DOCKER_CONFIG="${DOCKER_CONFIG:-}"
PUSH_DOCKERCFG_PATH="${PUSH_DOCKERCFG_PATH:-}"

if [ ! -n "${OUTPUT_REGISTRY}" ]; then
    fail "OUTPUT_REGISTRY environment varible is not set!"
fi

if [ ! -n "${OUTPUT_IMAGE}" ]; then
    fail "OUTPUT_IMAGE environment varible is not set!"
fi

if [ ! -d "${DOCKER_CONFIG}" ] ; then
    fail "${DOCKER_CONFIG} directory is not found!"
fi

# complete secret file path
PUSH_DOCKERCFG_PATH="${PUSH_DOCKERCFG_PATH}/.dockerconfigjson"

if [ ! -f ${PUSH_DOCKERCFG_PATH} ] ; then
    fail "${PUSH_DOCKERCFG_PATH} is not found!"
fi

#
# Docker Config
#

# the CNB uses the Docker configuration format to load the Container Registry authentication details
# and OpenShift mounts the BuildConfig's .spec.output.pushSecret in the build container using
# different file name and expected location, this script worksaround to copy the data following
# convention recognized by the CNB
sudo cp -v ${PUSH_DOCKERCFG_PATH} "${DOCKER_CONFIG}/config.json" && \
    sudo chown cnb:cnb "${DOCKER_CONFIG}/config.json"

#
# Buildpacks Lifecycle
#

export CNB_LOG_LEVEL="debug"
export CNB_APP_DIR="."

if [ ! -d "${CNB_APP_DIR}" ]; then
    fail "'${CNB_APP_DIR}' is not found!"
fi

# making sure the repository clone location is readable by the cnb user, this location is the actual
# application source code
print_phase "Changing the ownership '${CNB_APP_DIR}' contents (UID='${UID}')"
sudo chown -Rv cnb:cnb "${CNB_APP_DIR}"

print_phase "Files on '${CNB_APP_DIR}' ($PWD)"
ls -l ${CNB_APP_DIR}/

# fully qualified container registry, required by the CNB creator
FQIN="${OUTPUT_REGISTRY}/${OUTPUT_IMAGE}"

#
# CNB
#

print_phase "Runing creator for image-tag '${FQIN}'"
exec /cnb/lifecycle/creator \
    -log-level="${CNB_LOG_LEVEL}" \
    -app="${CNB_APP_DIR}" \
    "${FQIN}"
