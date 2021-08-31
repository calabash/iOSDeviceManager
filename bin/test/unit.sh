#!/usr/bin/env bash

source bin/log.sh
source bin/simctl.sh

set -e

info "Use the TESTS env variable to run specific tests:"
info ""
info "# Run single test:"
info "$ TESTS=Unit/XCTestConfigurationPlistTest/testXcodeVersionIsGreaterThanEqualTo83 make test-integration"
info ""
info "# Run all tests in a class:"
info "$ TESTS=Unit/XCTestConfigurationPlistTest make test-integration"
info ""
info "# General pattern:"
info "$ TESTS=<Scheme>/<Class>/<testMethod>"

XC_WORKSPACE="iOSDeviceManager.xcworkspace"
XC_SCHEME="Unit"

BUILD_DIR="build/${XC_SCHEME}"
XCODE_VERSION=`xcrun xcodebuild -version | head -1 | awk '{print $2}' | tr -d '\n'`
REPORT="reports/${XC_SCHEME}-${XCODE_VERSION}.xml"
rm -rf "${REPORT}"

#if [ $(gem list -i xcpretty) = "true" ] && [ "${XCPRETTY}" != "0" ]; then
#  XC_PIPE="xcpretty -c --report junit --output ${REPORT}"
#else
#  XC_PIPE='cat'
#fi
XC_PIPE='cat'

info "Will pipe xcodebuild to: ${XC_PIPE}"

set -e -o pipefail

if [ -z "${TESTS}" ]; then
  xcrun xcodebuild \
    -derivedDataPath ${BUILD_DIR} \
    -SYMROOT="${BUILD_DIR}" \
    -OBJROOT="${BUILD_DIR}" \
    -workspace "${XC_WORKSPACE}" \
    -scheme "${XC_SCHEME}" \
    -configuration Debug \
    -sdk macosx \
    test | $XC_PIPE && exit ${PIPESTATUS[0]}
else
  xcrun xcodebuild \
    -derivedDataPath ${BUILD_DIR} \
    -SYMROOT="${BUILD_DIR}" \
    -OBJROOT="${BUILD_DIR}" \
    -workspace "${XC_WORKSPACE}" \
    -scheme "${XC_SCHEME}" \
    -configuration Debug \
    -sdk macosx \
    -only-testing:"${TESTS}" \
    test | $XC_PIPE && exit ${PIPESTATUS[0]}
fi

