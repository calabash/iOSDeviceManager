#!/usr/bin/env bash

set -e

BUILD_DIR="build"
XC_PROJECT="iOSDeviceManager.xcodeproj"
XC_TARGET="iOSDeviceManager"

if [ "${XCPRETTY}" = "0" ]; then
  USE_XCPRETTY=
else
  USE_XCPRETTY=`which xcpretty | tr -d '\n'`
fi

if [ ! -z ${USE_XCPRETTY} ]; then
  XC_PIPE='xcpretty -c'
else
  XC_PIPE='cat'
fi

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
  GCC_TREAT_WARNINGS_AS_ERRORS=NO \
  GCC_GENERATE_TEST_COVERAGE_FILES=NO \
  GCC_INSTRUMENT_PROGRAM_FLOW_ARCS=NO \
  build | $XC_PIPE

mkdir -p Products
cp build/Release/iOSDeviceManagerServer Products

