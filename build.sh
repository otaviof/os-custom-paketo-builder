#!/bin/bash

shopt -s inherit_errexit
set -aeu -o pipefail

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

phase "Inspecting the environment variables"

# informed by OpenShift Builds points to the fully qualified container registry hostname, optional
# for this script
readonly OUTPUT_REGISTRY="${OUTPUT_REGISTRY:-}"
# fully qualified container image name, mandatory
readonly OUTPUT_REGISTRY_IMAGE="${OUTPUT_REGISTRY_IMAGE:-}"
# path to the `.spec.output.pushSecret` secret mount, mandatory
readonly PUSH_DOCKERCFG_PATH="${PUSH_DOCKERCFG_PATH:-}"

# making sure the required configuration environment varaibles are present
[[ ! -n "${OUTPUT_REGISTRY_IMAGE}" ]] && \
    fail "OUTPUT_REGISTRY_IMAGE environment varible is not set!"
[[ ! -n "${PUSH_DOCKERCFG_PATH}" ]] && \
    fail "PUSH_DOCKERCFG_PATH environment varible is not set!"

#
# Container-Registry Authentication
#

readonly export DOCKER_CONFIG="${DOCKER_CONFIG:-${PUSH_DOCKERCFG_PATH}}"
phase "Container-Registry credentials on directory '${DOCKER_CONFIG}'"

[[ ! -d "${DOCKER_CONFIG}" ]] && \
    fail "${DOCKER_CONFIG} is not found!"

#
# OpenShift Internal Registry CA
#

# common location where the secret is mounted in OpenShift Builds
readonly CLUSTER_CA_PATH="/var/run/configs/openshift.io/certs/certs.d/${OUTPUT_REGISTRY}/ca.crt"

if [ -f "${CLUSTER_CA_PATH}" ]; then
    phase "Adding CA to the trust store ('${CLUSTER_CA_PATH}')"
    sudo cp -v "${CLUSTER_CA_PATH}" /usr/local/share/ca-certificates
    sudo update-ca-certificates
fi

#
# Buildpacks Lifecycle
#

readonly export CNB_APP_DIR="${CNB_APP_DIR:-.}"

# making sure the application repository clone location is `rw` for the cnb user, for instance when
# building a Node.js application it needs to populate `node_modules` folder
phase "Changing the ownership of '${CNB_APP_DIR}' recursively ('UID=${UID}')"
sudo chown -Rv cnb:cnb "${CNB_APP_DIR}"

phase "Files on '${CNB_APP_DIR}' ('PWD=${PWD}')"
ls -l ${CNB_APP_DIR}/

phase "Running creator for image-tag '${OUTPUT_REGISTRY_IMAGE}'"
set -x
exec /cnb/lifecycle/creator -log-level="debug" -app="${CNB_APP_DIR}" "${OUTPUT_REGISTRY_IMAGE}"
