#!/usr/bin/env bash

set -e

source bin/log_functions.sh

DEP_STAGING_DIR=Distribution/dependencies
NUGET_DIR=Distribution/DeviceAgent.iOS.Dependencies/DeviceAgent.iOS.Dependencies
NUGET_DEP_DIR="${NUGET_DIR}/dependencies"
NUSPEC="${NUGET_DIR}"/DeviceAgent.iOS.nuspec

rm -rf "${NUGET_DEP_DIR}" 
cp -r "${DEP_STAGING_DIR}" "${NUGET_DEP_DIR}"

nuget pack "${NUSPEC}" -Version `cat Distribution/version.txt`

info "Built Nuget package to ${NUGET_DIR}"
