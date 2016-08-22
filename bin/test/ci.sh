#!/usr/bin/env bash

set -e

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

(cd "${CODE_SIGN_DIR}" && ios/create-keychain.sh)

if [ -d FBSimulatorControl ]; then
	rm -rf FBSimulatorControl
fi
if [ -d DeviceAgent.iOS ]; then
	rm -rf DeviceAgent.iOS
fi

git clone git@github.com:calabash/FBSimulatorControl.git
git clone git@github.com:calabash/DeviceAgent.iOS.git

export FBSIMCONTROL_PATH=./FBSimulatorControl
export DEVICEAGENT_PATH=./DeviceAgent.iOS

make dependencies

set +e

pkill iOSDeviceManager
pkill Simulator

rm -rf reports/*.xml

make test-unit

# `start_test` fails on Jenkins
#make tests

EXIT_STATUS=$?

pkill iOSDeviceManager
pkill Simulator

if [ "${EXIT_STATUS}" = "0" ]; then
  echo "Tests passed"
  exit 0
else
  echo "Tests failed."
  exit 1
fi

# Disabling because they take too long to run.
#bin/test/sim

