#!/usr/bin/env bash

set -e

source bin/log_functions.sh

EXECUTABLE=iOSDeviceManager
OUTPUT_DIR=Distribution/dependencies

rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}/Frameworks"
mkdir -p "${OUTPUT_DIR}/bin"  
mkdir -p "${OUTPUT_DIR}/app"  
mkdir -p "${OUTPUT_DIR}/ipa"  

make build
cp "Products/${EXECUTABLE}" "${OUTPUT_DIR}/bin"

if [ -z "${FBSIMCONTROL_PATH}" ]; then
  error "Please specify path to FBSimulatorControl repo via FBSIMCONTROL_PATH=/path/to/fbsimctl"
  exit 1
fi

if [ ! -d "${FBSIMCONTROL_PATH}" ]; then
  error "${FBSIMCONTROL_PATH} does not exist"
  exit 2
fi

if [ -z "${DEVICEAGENT_PATH}" ]; then
  error "Please specify path to DeviceAgent.iOS repo via DEVICEAGENT_PATH=/path/to/deviceagent"
  exit 3
fi

if [ ! -d "${DEVICEAGENT_PATH}" ]; then
  error "${DEVICEAGENT_PATH} does not exist"
  exit 4
fi

HERE=$(pwd)

(cd "${FBSIMCONTROL_PATH}";
 make frameworks;
 cp -r build/Release/* "${HERE}/${OUTPUT_DIR}/Frameworks")

(cd "${DEVICEAGENT_PATH}";
 make app-agent;
 make ipa-agent;
 cp -r Products/ipa/DeviceAgent/CBX-Runner.app "${HERE}/${OUTPUT_DIR}/ipa";
 cp -r Products/app/DeviceAgent/CBX-Runner.app "${HERE}/${OUTPUT_DIR}/app")

info "Gathered dependencies in ${OUTPUT_DIR}"
