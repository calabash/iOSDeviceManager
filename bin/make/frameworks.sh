#!/usr/bin/env bash

source bin/log.sh
source bin/simctl.sh

IDB_COMPANION_VERSION="1.1.6"

if [ -z "${IDB_FRAMEWORKS_PATH}" ]; then
  IDB_FRAMEWORKS_PATH="/usr/local/Cellar/idb-companion/${IDB_COMPANION_VERSION}/Frameworks"
fi

if [ ! -d "${IDB_FRAMEWORKS_PATH}" ]; then
  error "FBSimulatorControl does not exist at path:"
  error "  ${IDB_FRAMEWORKS_PATH}"
  error "Set the IDB_FRAMEWORKS_PATH=path/to/FBSimulatorControl or"
  error "checkout the calabash fork of the FBSimulatorControl repo to ../"
  exit 4
fi

function strip_framework() {
  local FRAMEWORK_PATH="${OUTPUT_DIR}/${1}"
  if [ -d "$FRAMEWORK_PATH" ]; then
    rm -r "$FRAMEWORK_PATH"
  fi
}

rm -rf ./Frameworks/*.framework
OUTPUT_DIR="${PWD}/Frameworks"

xcrun ditto "${IDB_FRAMEWORKS_PATH}/FBControlCore.framework" \
  "${OUTPUT_DIR}/FBControlCore.framework" ;

xcrun ditto "${IDB_FRAMEWORKS_PATH}/FBDeviceControl.framework" \
  "${OUTPUT_DIR}/FBDeviceControl.framework" ;

xcrun ditto "${IDB_FRAMEWORKS_PATH}/FBSimulatorControl.framework" \
  "${OUTPUT_DIR}/FBSimulatorControl.framework" ;

xcrun ditto "${IDB_FRAMEWORKS_PATH}/XCTestBootstrap.framework" \
  "${OUTPUT_DIR}/XCTestBootstrap.framework" ;

xcrun ditto ./Vendor/CocoaLumberjack.framework ${OUTPUT_DIR}/CocoaLumberjack.framework

strip_framework "FBSimulatorControlKit.framework/Versions/Current/Frameworks/FBSimulatorControl.framework"
strip_framework "FBSimulatorControlKit.framework/Versions/Current/Frameworks/FBDeviceControl.framework"
strip_framework "FBSimulatorControl.framework/Versions/Current/Frameworks/XCTestBootstrap.framework"
strip_framework "FBSimulatorControl.framework/Versions/Current/Frameworks/FBControlCore.framework"
strip_framework "FBSimulatorControl.framework/Versions/Current/Frameworks/CocoaLumberjack.framework"
strip_framework "FBDeviceControl.framework/Versions/Current/Frameworks/XCTestBootstrap.framework"
strip_framework "FBDeviceControl.framework/Versions/Current/Frameworks/FBControlCore.framework"
strip_framework "FBDeviceControl.framework/Versions/Current/Frameworks/CocoaLumberjack.framework"
strip_framework "XCTestBootstrap.framework/Versions/Current/Frameworks/FBControlCore.framework"
strip_framework "XCTestBootstrap.framework/Versions/Current/Frameworks/CocoaLumberjack.framework"
strip_framework "FBControlCore.framework/Versions/Current/Frameworks/CocoaLumberjack.framework"

xcrun codesign \
--force \
--deep \
--sign "Mac Developer: Karl Krukow (YTTN6Y2QS9)" \
--keychain "${HOME}/.calabash/Calabash.keychain" \
"Frameworks/CocoaLumberjack.framework"

xcrun codesign \
--force \
--deep \
--sign "Mac Developer: Karl Krukow (YTTN6Y2QS9)" \
--keychain "${HOME}/.calabash/Calabash.keychain" \
"Frameworks/FBControlCore.framework"

xcrun codesign \
--force \
--deep \
--sign "Mac Developer: Karl Krukow (YTTN6Y2QS9)" \
--keychain "${HOME}/.calabash/Calabash.keychain" \
"Frameworks/FBDeviceControl.framework"

xcrun codesign \
--force \
--deep \
--sign "Mac Developer: Karl Krukow (YTTN6Y2QS9)" \
--keychain "${HOME}/.calabash/Calabash.keychain" \
"Frameworks/FBSimulatorControl.framework"

xcrun codesign \
--force \
--deep \
--sign "Mac Developer: Karl Krukow (YTTN6Y2QS9)" \
--keychain "${HOME}/.calabash/Calabash.keychain" \
"Frameworks/XCTestBootstrap.framework"