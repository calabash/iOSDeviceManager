#!/usr/bin/env bash

source bin/log.sh
source bin/simctl.sh
source bin/ditto.sh
ensure_valid_core_sim_service

BUILD_DIR="build"
XC_PROJECT="iOSDeviceManager.xcodeproj"
XC_TARGET="iOSDeviceManager"

if [ $(gem list -i xcpretty) = "true" ] && [ "${XCPRETTY}" != "0" ]; then
  XC_PIPE="xcpretty -c"
else
  XC_PIPE='cat'
fi

info "Will pipe xcodebuild to: ${XC_PIPE}"

set -e -o pipefail

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

install_with_ditto ThirdPartyNotices.txt Frameworks/ThirdPartyNotices.txt
install_with_ditto Licenses/CocoaLumberjack.LICENSE Frameworks/CocoaLumberjack.LICENSE
install_with_ditto Licenses/FBSimulatorControl.LICENSE Frameworks/FBSimulatorControl.LICENSE
