#!/usr/bin/env bash

set +e
source bin/simctl.sh
ensure_valid_core_sim_service
set -e

source bin/log.sh

export DEVELOPER_DIR="/Xcode/9.2/Xcode.app/Contents/Developer"

if [ -z "${JENKINS_HOME}" ]; then
  echo "FAIL: only run this script on Jenkins"
  exit 1
fi

mkdir -p "${HOME}/.calabash"

CODE_SIGN_DIR="${HOME}/.calabash/calabash-codesign"

rm -rf "${CODE_SIGN_DIR}"

if [ -e "${CODE_SIGN_DIR}" ]; then
  # Previous step or run checked out this file.
  (cd "${CODE_SIGN_DIR}" && git reset --hard)
  (cd "${CODE_SIGN_DIR}" && git checkout master)
  (cd "${CODE_SIGN_DIR}" && git pull)
else
  git clone \
    git@github.com:calabash/calabash-codesign.git \
    "${CODE_SIGN_DIR}"
fi

(cd "${CODE_SIGN_DIR}" && apple/create-keychain.sh)

rm -rf DeviceAgent.iOS
git clone git@github.com:calabash/DeviceAgent.iOS.git
DEVICEAGENT_PATH=./DeviceAgent.iOS make dependencies

set +e

pkill iOSDeviceManager
pkill Simulator

rm -rf reports/*.xml

make tests