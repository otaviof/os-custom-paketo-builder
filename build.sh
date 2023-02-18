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

function phase() {
    echo "---> Phase: ${*}..."
}

#
# Preparing the Environment
#

phase "Preparing the environment"

# fully qualified container image name
readonly OUTPUT_REGISTRY_IMAGE="${OUTPUT_REGISTRY_IMAGE:-}"
# path to the `.spec.output.pushSecret` secret mount
readonly PUSH_DOCKERCFG_PATH="${PUSH_DOCKERCFG_PATH:-}"
# informed by OpenShift Builds points to the fully qualified container registry hostname
readonly OUTPUT_REGISTRY="${OUTPUT_REGISTRY:-}"

# making sure the required configuration environment varaibles are present
[[ ! -n "${OUTPUT_REGISTRY_IMAGE}" ]] && \
    fail "OUTPUT_REGISTRY_IMAGE environment varible is not set!"
[[ ! -n "${PUSH_DOCKERCFG_PATH}" ]] && \
    fail "PUSH_DOCKERCFG_PATH environment varible is not set!"

#
# Container-Registry Authentication
#

phase "Preparing Container-Registry credentials ('${PUSH_DOCKERCFG_PATH}')"

# docker configuration directory path, by convetion located at the user's home directory
readonly export DOCKER_CONFIG="${DOCKER_CONFIG:-${HOME}/.docker}"

[[ ! -d "${DOCKER_CONFIG}" ]] && \
    mkdir -pv "${DOCKER_CONFIG}"

# complete secret file path mounted by OpenShift Builds (".spec.output.pushSecret.name"), the secret
# is mandatory since it controls the Container-Registry credentials.
readonly PUSH_DOCKERCFG_FILE_PATH="${PUSH_DOCKERCFG_PATH}/.dockerconfigjson"

[[ ! -f "${PUSH_DOCKERCFG_FILE_PATH}" ]] && \
    fail "'${PUSH_DOCKERCFG_FILE_PATH}' is not found!"

# the CNB uses the Docker configuration format to load the Container Registry authentication details
# and OpenShift mounts the BuildConfig's ".spec.output.pushSecret" in the build container using a
# different file path than the CNB expects, this script is a worksaround to link the data to the
# conventional location
ln -sv "${PUSH_DOCKERCFG_FILE_PATH}" "${DOCKER_CONFIG}/config.json"

#
# OpenShift Internal Registry CA
#

# common location where the secret is mounted in OpenShift Builds
readonly CLUSTER_CA_PATH="/var/run/configs/openshift.io/certs/certs.d/${OUTPUT_REGISTRY}/ca.crt"

if [ -f "${CLUSTER_CA_PATH}" ] ; then
    phase "Adding CA to local trust store ('${CLUSTER_CA_PATH}')"
    sudo cp -v "${CLUSTER_CA_PATH}" /usr/local/share/ca-certificates
    sudo update-ca-certificates
fi

#
# Buildpacks Lifecycle
#

readonly export CNB_LOG_LEVEL="debug"
readonly export CNB_APP_DIR="."

# making sure the application repository clone location is `rw` for the cnb user, for instance when
# building a Node.js application it needs to populate `node_modules` folder
phase "Changing the ownership of '${CNB_APP_DIR}' recursively ('UID=${UID}')"
sudo chown -Rv cnb:cnb "${CNB_APP_DIR}"

phase "Files on '${CNB_APP_DIR}' ('PWD=${PWD}')"
ls -l ${CNB_APP_DIR}/

#
# CNB
#

phase "Running creator for image-tag '${OUTPUT_REGISTRY_IMAGE}'"
set -x
exec /cnb/lifecycle/creator \
    -log-level="${CNB_LOG_LEVEL}" \
    -app="${CNB_APP_DIR}" \
    "${OUTPUT_REGISTRY_IMAGE}"
