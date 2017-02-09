#!/usr/bin/env bash

export DEVELOPER_DIR=/Xcode/8.2.1/Xcode.app/Contents/Developer

set +e

# Force Xcode 8 CoreSimulator env to be loaded so xcodebuild does not fail.
for try in {1..4}; do
  xcrun simctl help &>/dev/null
  sleep 1.0
done

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

rm -rf DeviceAgent.iOS
git clone git@github.com:calabash/DeviceAgent.iOS.git
DEVICEAGENT_PATH=./DeviceAgent.iOS make dependencies

set +e

pkill iOSDeviceManager
pkill Simulator

rm -rf reports/*.xml

carthage bootstrap
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

