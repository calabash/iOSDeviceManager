#!/usr/bin/env bash

XC_PROJECT=iOSDeviceManager.xcodeproj
XC_TARGET=Tests

set -e

if [[ "${SHELL}" =~ "zsh" ]]; then
  echo "-o pipefail is not available in zsh.  You have been warned."
else
  set -o pipefail
fi

make clean

BUILD_DIR="build"
XC_WORKSPACE="iOSDeviceManager.xcworkspace"

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

xcrun xcodebuild \
  -derivedDataPath ${BUILD_DIR} \
  -SYMROOT="${BUILD_DIR}" \
  -OBJROOT="${BUILD_DIR}" \
  -workspace ${XC_WORKSPACE} \
  -scheme Tests \
  -configuration Debug \
  -sdk macosx \
  test | $XC_PIPE

