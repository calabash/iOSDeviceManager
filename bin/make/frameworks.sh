#!/usr/bin/env bash
source bin/log_functions.sh

if [ -z "${FBSIMCONTROL_PATH}" ]; then
  error "Set FBSIMCONTROL_PATH=/path/to/FBSimulatorControl and rerun"
  exit 1
fi

set -e

rm -rf ./Frameworks/*.framework
HERE=$(pwd)

(cd "${FBSIMCONTROL_PATH}";
make frameworks;

xcrun ditto build/Release/FBControlCore.framework \
  "${HERE}/${OUTPUT_DIR}/Frameworks/FBControlCore.framework" ;

xcrun ditto build/Release/FBDeviceControl.framework \
  "${HERE}/${OUTPUT_DIR}/Frameworks/FBDeviceControl.framework" ;

xcrun ditto build/Release/FBSimulatorControl.framework \
  "${HERE}/${OUTPUT_DIR}/Frameworks/FBSimulatorControl.framework" ;

xcrun ditto build/Release/XCTestBootstrap.framework \
  "${HERE}/${OUTPUT_DIR}/Frameworks/XCTestBootstrap.framework" ;
)

