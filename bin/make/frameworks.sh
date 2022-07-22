#!/usr/bin/env bash

source bin/log.sh
source bin/simctl.sh

banner "Preparing"

IDB_VERSION="v1.1.7"

if [ -z "${FBSIMCONTROL_PATH}" ]; then
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

banner "Checkout idb tag ${IDB_VERSION}"

(cd "${FBSIMCONTROL_PATH}";
git checkout $IDB_VERSION;
)

banner "Building idb frameworks inside idb's directory"

rm -rf ./Frameworks/*.framework
OUTPUT_DIR="${PWD}/Frameworks"

cp -a bin/idb/. ${FBSIMCONTROL_PATH}

echo "${FBSIMCONTROL_PATH}"
(cd "${FBSIMCONTROL_PATH}";

make frameworks;

xcrun ditto build/Release/FBControlCore.framework \
  "${OUTPUT_DIR}/FBControlCore.framework" ;

xcrun ditto build/Release/FBDeviceControl.framework \
  "${OUTPUT_DIR}/FBDeviceControl.framework" ;

xcrun ditto build/Release/FBSimulatorControl.framework \
  "${OUTPUT_DIR}/FBSimulatorControl.framework" ;

xcrun ditto build/Release/XCTestBootstrap.framework \
  "${OUTPUT_DIR}/XCTestBootstrap.framework" ;

rm -rf Makefile;
rm -rf bin;
)

banner "Signing frameworks"

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

