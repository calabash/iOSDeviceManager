#!/usr/bin/env bash

source bin/simctl.sh
source bin/log.sh

set -e

source bin/log.sh

info "Use the TESTS env variable to run specific tests:"
info ""
info "# Run single test:"
info "$ TESTS=Integration/PhysicalDeviceCLIIntegrationTests/testLaunchAndKillApp make test-integration"
info ""
info "# Run all tests in a class:"
info "$ TESTS=Integration/PhysicalDeviceCLIIntegrationTests make test-integration"
info ""
info "# General pattern:"
info "$ TESTS=<Scheme>/<Class>/<testMethod>"

banner "iOSDeviceManager emits no stderr"
# Test to see if there is any unsual output e.g. "symbol is redefined"

# xcodebuild test job below builds iOSDeviceManager, but does not stage
# Frameworks correctly - the @rpath is correct, but the framework bundles
# are incomplete.  If the build starts taking a very long time, we can
# investigate staging the frameworks correctly.
bin/make/build.sh

tmpfile=$(mktemp)
Products/iOSDeviceManager >/dev/null 2>"${tmpfile}"
if [ -s "${tmpfile}" ]; then
  error "Expected iOSDeviceManager to output nothing on stderr"
  error "Output captured here: ${tmpfile}"
  exit 1
else
  info "iOSDeviceManager did not have unusual output"
  rm -f "${tmpfile}"
fi

banner "Integration XCTests"

XC_WORKSPACE="iOSDeviceManager.xcworkspace"
XC_SCHEME="Integration"
BUILD_DIR="build/${XC_SCHEME}"

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

XCODE_VERSION=`xcrun xcodebuild -version | head -1 | awk '{print $2}' | tr -d '\n'`
REPORT="reports/${XC_SCHEME}-${XCODE_VERSION}.xml"
rm -rf "${REPORT}"

if [ $(gem list -i xcpretty) = "true" ] && [ "${XCPRETTY}" != "0" ]; then
  XC_PIPE="xcpretty -c --report junit --output ${REPORT}"
else
  XC_PIPE='cat'
fi

info "Will pipe xcodebuild to: ${XC_PIPE}"

set -e -o pipefail

#  -only-testing:"Integration/PhysicalDeviceTest/testUploadXCAppDataBundleCLI" \
#  -only-testing:"Integration/SimulatorTest" \

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
