#!/usr/bin/env bash

set -e

source bin/log_functions.sh

DEP_STAGING_DIR=Distribution/dependencies
NUGET_DIR=Distribution/DeviceAgent.iOS.Dependencies
DEP_ZIP=dependencies.zip
VERSION_FILE=Distribution/version.txt
VERSION=`cat ${VERSION_FILE}`
CURRENT_DIR=$PWD

rm -f "${NUGET_DEP_ZIP}"
cp -f "${VERSION_FILE}" "${NUGET_DIR}"

cd "${DEP_STAGING_DIR}"

info "Zipping up dependencies"

zip -qr "${DEP_ZIP}" *

cd "${CURRENT_DIR}"

mv "${DEP_STAGING_DIR}/${DEP_ZIP}" "${NUGET_DIR}"

cd "${NUGET_DIR}"

info "Building Nuget package"

dotnet version "${VERSION}" > /dev/null
dotnet pack -c Release > /dev/null

cd "${CURRENT_DIR}"

info "Built Nuget package ${NUGET_DIR} v${VERSION}"
