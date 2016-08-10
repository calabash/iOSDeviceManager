#!/usr/bin/env bash

set -e

source bin/log_functions.sh

DEP_STAGING_DIR=Distribution/dependencies
NUGET_DIR=Distribution/DeviceAgent.iOS.Dependencies
NUGET_DEP_ZIP="${NUGET_DIR}/dependencies.zip"
VERSION_FILE=Distribution/version.txt
VERSION=`cat ${VERSION_FILE}`

rm -f "${NUGET_DEP_ZIP}"
zip -qr "${NUGET_DEP_ZIP}" "${DEP_STAGING_DIR}"
cp -f "${VERSION_FILE}" "${NUGET_DIR}"

CURRENT_DIR=$PWD

cd "${NUGET_DIR}"

dotnet version "${VERSION}"
dotnet pack -c Release

cd "${CURRENT_DIR}"

info "Built Nuget package ${NUGET_DIR}"
