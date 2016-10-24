#!/usr/bin/env bash

set -e

source bin/log_functions.sh

if [ -z "${DEVICEAGENT_PATH}" ]; then
  error "Please specify path to DeviceAgent.iOS repo via DEVICEAGENT_PATH=path/to/DeviceAgent.iOS"
  exit 3
fi

if [ ! -d "${DEVICEAGENT_PATH}" ]; then
  error "${DEVICEAGENT_PATH} does not exist"
  exit 4
fi

EXECUTABLE=iOSDeviceManager
OUTPUT_DIR="${PWD}/Distribution/dependencies"

rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}/Frameworks"
mkdir -p "${OUTPUT_DIR}/bin"
mkdir -p "${OUTPUT_DIR}/app"
mkdir -p "${OUTPUT_DIR}/ipa"

banner "Copying Frameworks/ to Dependencies"

declare -a FBFRAMEWORKS=("FBControlCore" "FBDeviceControl" "FBSimulatorControl" "XCTestBootstrap")

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
cp vendor-licenses/* "${OUTPUT_DIR}/Frameworks"

banner "Making iOSDeviceManager"

make clean
make build

cp "Products/${EXECUTABLE}" "${OUTPUT_DIR}/bin"
cp "CLI.json" "${OUTPUT_DIR}/bin"
cp "locate_sim_container.sh" "${OUTPUT_DIR}/bin"

info "Gathered dependencies in ${OUTPUT_DIR}"
