#!/usr/bin/env bash

set -e
set -x

source bin/log_functions.sh

EXECUTABLE=iOSDeviceManager
GEM_DIR=Distribution/ruby-gem

rm -rf "${GEM_DIR}/Frameworks/*"
rm -rf "${GEM_DIR}/app/*"
rm -rf "${GEM_DIR}/ipa/*"
rm -rf "${GEM_DIR}/bin/native/*"


make build
cp "Products/${EXECUTABLE}" "${GEM_DIR}/bin/native"

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
 cp -r build/Release/* "${HERE}/${GEM_DIR}/Frameworks")

(cd "${DEVICEAGENT_PATH}";
 make app-agent;
 make ipa-agent;
 cp -r Products/ipa/DeviceAgent/CBX-Runner.app "${HERE}/${GEM_DIR}/ipa";
 cp -r Products/app/DeviceAgent/CBX-Runner.app "${HERE}/${GEM_DIR}/app")

cd "${GEM_DIR}"
gem build device-agent.gemspec

info "Built Gem to Distribution/ruby-gem"
