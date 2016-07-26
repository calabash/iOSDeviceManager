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
(cd "${CODE_SIGN_DIR}" && ios/import-profiles.sh)

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

bin/make/dependencies.sh
bin/test/sim

