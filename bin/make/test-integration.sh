#!/usr/bin/env bash

set -e

XC_WORKSPACE="iOSDeviceManager.xcworkspace"
XC_SCHEME="Integration"
BUILD_DIR="build/${XC_SCHEME}"

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

XCODE_VERSION=`xcrun xcodebuild -version | head -1 | awk '{print $2}' | tr -d '\n'`
REPORT="reports/${XC_SCHEME}-${XCODE_VERSION}.xml"
rm -rf "${REPORT}"

if [ "${XCPRETTY}" = "0" ]; then
  USE_XCPRETTY=
else
  USE_XCPRETTY=`which xcpretty | tr -d '\n'`
fi

if [ ! -z ${USE_XCPRETTY} ]; then
  XC_PIPE="xcpretty -c --report junit --output ${REPORT}"
else
  XC_PIPE='cat'
fi

carthage update
xcrun xcodebuild \
  -derivedDataPath ${BUILD_DIR} \
  -SYMROOT="${BUILD_DIR}" \
  -OBJROOT="${BUILD_DIR}" \
  -workspace "${XC_WORKSPACE}" \
  -scheme "${XC_SCHEME}" \
  -configuration Debug \
  -sdk macosx \
  test | $XC_PIPE && exit ${PIPESTATUS[0]}
