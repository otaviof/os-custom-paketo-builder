#!/bin/bash

set -xeu -o pipefail
shopt -s inherit_errexit

function print_phase() {
    echo "---> Phase: ${*}..."
}

function fail() {
    echo "ERROR: ${*}" 2>&1
    exit 1
}

# openshift custom build shares the parameters via the environment variable
BUILD="${BUILD:-}"

if [[ ! -n "${BUILD}" ]] ; then
    fail "BUILD environment varible is not set!"
fi

echo "BUILD=${BUILD}"
exit 0

#
# Buildpacks Lifecycle
#

# print_phase "Source files at ${CNB_APP_DIR}"
# cp -vfR ${S2I_SRC_DIR}/* ${CNB_APP_DIR}

print_phase "Detector"
/cnb/lifecycle/detector
print_phase "Analyzer"
/cnb/lifecycle/analyzer "${IMAGE_TAG}"

print_phase "Restorer"
/cnb/lifecycle/restorer

print_phase "Builder"
/cnb/lifecycle/builder \

# print_phase "Exporter"
# /cnb/lifecycle/exporter "${S2I_IMAGE_TAG}"
