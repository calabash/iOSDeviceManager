#!/usr/bin/env bash

set +e
source bin/simctl.sh
ensure_valid_core_sim_service
set -e

source bin/log.sh

XC_WORKSPACE="iOSDeviceManager.xcworkspace"
XC_SCHEME="Unit"

BUILD_DIR="build/${XC_SCHEME}"
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

XCODE_VERSION=`xcrun xcodebuild -version | head -1 | awk '{print $2}' | tr -d '\n'`
REPORT="reports/${XC_SCHEME}-${XCODE_VERSION}.xml"
rm -rf "${REPORT}"

XC_PIPE="xcpretty -c --report junit --output ${REPORT}"
hash "xcpretty" 2>/dev/null && [ "${XCPRETTY}" != "0" ] || {
  XC_PIPE='cat'
}

info "Will pipe xcodebuild to: ${XC_PIPE}"

set -e -o pipefail

xcrun xcodebuild \
  -derivedDataPath ${BUILD_DIR} \
  -SYMROOT="${BUILD_DIR}" \
  -OBJROOT="${BUILD_DIR}" \
  -workspace "${XC_WORKSPACE}" \
  -scheme "${XC_SCHEME}" \
  -configuration Debug \
  -sdk macosx \
  test | $XC_PIPE && exit ${PIPESTATUS[0]}

