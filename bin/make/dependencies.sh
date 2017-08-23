#!/usr/bin/env bash

set +e
source bin/simctl.sh
ensure_valid_core_sim_service
set -e

source bin/log.sh

if [ -z "${DEVICEAGENT_PATH}" ]; then
  if [ -e "../DeviceAgent.iOS" ]; then
    DEVICEAGENT_PATH="../DeviceAgent.iOS"
  fi
fi

if [ ! -d "${DEVICEAGENT_PATH}" ]; then
  error "DeviceAgent.iOS does not exist at path:"
  error "  ${DEVICEAGENT_PATH}"
  error "Set the DEVICEAGENT_PATH=path/to/DeviceAgent.iOS or"
  error "checkout the DeviceAgent.iOS repo to ../"
  exit 4
fi

info "Using DeviceAgent: ${DEVICEAGENT_PATH}"

EXECUTABLE=iOSDeviceManager
OUTPUT_DIR="${PWD}/Distribution/dependencies"

rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}/Frameworks"
mkdir -p "${OUTPUT_DIR}/bin"
mkdir -p "${OUTPUT_DIR}/app"
mkdir -p "${OUTPUT_DIR}/ipa"

banner "Copying Frameworks/ to Dependencies"

declare -a FBFRAMEWORKS=("FBControlCore" "FBDeviceControl" "FBSimulatorControl" "XCTestBootstrap" "CocoaLumberjack")

for framework in "${FBFRAMEWORKS[@]}"
do
  TARGET="${OUTPUT_DIR}/Frameworks/${framework}.framework"
  xcrun ditto Frameworks/${framework}.framework "${TARGET}"
  info "Copied ${framework} to ${TARGET}"
done

banner "Making DeviceAgent"

(cd "${DEVICEAGENT_PATH}";
 make app-agent;
 make ipa-agent;
 xcrun ditto Products/ipa/DeviceAgent/DeviceAgent-Runner.app \
   "${OUTPUT_DIR}/ipa/DeviceAgent-Runner.app";
 xcrun ditto Products/app/DeviceAgent/DeviceAgent-Runner.app \
   "${OUTPUT_DIR}/app/DeviceAgent-Runner.app")

banner "Copying Licenses"

cp LICENSE "${OUTPUT_DIR}"
cp Licenses/* "${OUTPUT_DIR}/Frameworks"

banner "Making iOSDeviceManager"

make clean
make build

cp "Products/${EXECUTABLE}" "${OUTPUT_DIR}/bin"

info "Gathered dependencies in ${OUTPUT_DIR}"
