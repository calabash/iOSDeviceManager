#!/usr/bin/env bash

source bin/log.sh
source bin/simctl.sh
ensure_valid_core_sim_service

BUILD_DIR="build"
XC_PROJECT="iOSDeviceManager.xcodeproj"
XC_TARGET="iOSDeviceManager"

hash xcpretty 2>/dev/null
if [ $? -eq 0 ] && [ "${XCPRETTY}" != "0" ]; then
  XC_PIPE='xcpretty -c'
else
  XC_PIPE='cat'
fi

info "Will pipe xcodebuild to: ${XC_PIPE}"

set -e -o pipefail

# We want to fail on warnings, but linking FBSimulatorControl
# raises warnings.
# https://xamarin.atlassian.net/browse/TCFW-127
xcrun xcodebuild \
  -SYMROOT="${BUILD_DIR}" \
  -OBJROOT="${BUILD_DIR}" \
  -project ${XC_PROJECT} \
  -target ${XC_TARGET} \
  -configuration Release \
  -sdk macosx \
  GCC_TREAT_WARNINGS_AS_ERRORS=YES \
  GCC_GENERATE_TEST_COVERAGE_FILES=NO \
  GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=NO \
  build | $XC_PIPE

rm -rf Products
mkdir Products

# Will dynamically link Products/../Frameworks at runtime
ditto build/Release/iOSDeviceManager Products/iOSDeviceManager
