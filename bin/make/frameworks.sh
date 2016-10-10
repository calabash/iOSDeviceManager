#!/usr/bin/env bash

set -e

source bin/log_functions.sh

banner "Build FBSimulatorControl"

info "Checking FBSIMCONTROL_PATH"

if [ -z "${FBSIMCONTROL_PATH}" ]; then
  if [ -e "../FBSimulatorControl" ]; then
    FBSIMCONTROL_PATH="../FBSimulatorControl"
  fi
fi

if [ ! -d "${FBSIMCONTROL_PATH}" ]; then
  error "FBSimulatorControl does not exist at path:"
  error "  ${FBSIMCONTROL_PATH}"
  error "Set the FBSIMCONTROL_PATH=path/to/FBSimulatorControl or"
  error "checkout the calabash fork of the FBSimulatorControl repo to ../"
  exit 4
fi

info "Removing old frameworks"

rm -rf ./Frameworks/*.framework

OUTPUT_DIR="${PWD}/Frameworks"

(cd "${FBSIMCONTROL_PATH}";
make frameworks;

banner "Copying Facebook Frameworks to iOSDeviceManager"

xcrun ditto build/Release/FBControlCore.framework \
    "${OUTPUT_DIR}/FBControlCore.framework" ;

xcrun ditto build/Release/FBDeviceControl.framework \
    "${OUTPUT_DIR}/FBDeviceControl.framework" ;

xcrun ditto build/Release/FBSimulatorControl.framework \
    "${OUTPUT_DIR}/FBSimulatorControl.framework" ;

xcrun ditto build/Release/XCTestBootstrap.framework \
    "${OUTPUT_DIR}/XCTestBootstrap.framework" ;

xcrun ditto Vendor/CocoaLumberjack.framework \
    "${OUTPUT_DIR}/CocoaLumberjack.framework" ;
)

banner "Done"
