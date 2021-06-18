#!/usr/bin/env bash

source bin/log.sh
source bin/simctl.sh

if [ -z "${FBSIMCONTROL_PATH}" ]; then
  #if [ -e "../FBSimulatorControl" ]; then
  #  FBSIMCONTROL_PATH="../FBSimulatorControl"
  #fi
  #if [ -e "../FBSimulatorControl_old" ]; then
  #  FBSIMCONTROL_PATH="../FBSimulatorControl_old"
  #fi
  if [ -e "../idb" ]; then
    FBSIMCONTROL_PATH="../idb"
  fi
fi

if [ ! -d "${FBSIMCONTROL_PATH}" ]; then
  error "FBSimulatorControl does not exist at path:"
  error "  ${FBSIMCONTROL_PATH}"
  error "Set the FBSIMCONTROL_PATH=path/to/FBSimulatorControl or"
  error "checkout the calabash fork of the FBSimulatorControl repo to ../"
  exit 4
fi

rm -rf ./Frameworks/*.framework
OUTPUT_DIR="${PWD}/Frameworks"

echo "${FBSIMCONTROL_PATH}"
(cd "${FBSIMCONTROL_PATH}";

#./build.sh
make frameworks;

xcrun ditto build/Release/FBControlCore.framework \
  "${OUTPUT_DIR}/FBControlCore.framework" ;

xcrun ditto build/Release/FBDeviceControl.framework \
  "${OUTPUT_DIR}/FBDeviceControl.framework" ;

xcrun ditto build/Release/FBSimulatorControl.framework \
  "${OUTPUT_DIR}/FBSimulatorControl.framework" ;

xcrun ditto build/Release/XCTestBootstrap.framework \
  "${OUTPUT_DIR}/XCTestBootstrap.framework" ;

#xcrun ditto Vendor/CocoaLumberjack.framework \
#  "${OUTPUT_DIR}/CocoaLumberjack.framework" ;
)
#CocoaLumberjack.framework is temporarely copied from previous FBSimulatorControl build results, because there is no such framework in idm
xcrun ditto ../CocoaLumberjack.framework ${OUTPUT_DIR}/CocoaLumberjack.framework

xcrun codesign \
--force \
--deep \
--sign "Mac Developer: Karl Krukow (YTTN6Y2QS9)" \
--keychain "${HOME}/.calabash/Calabash.keychain" \
"Frameworks/CocoaLumberjack.framework"
