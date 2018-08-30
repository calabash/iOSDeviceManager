#!/usr/bin/env bash

set +e
source bin/simctl.sh
ensure_valid_core_sim_service
set -e

source bin/log.sh

export DEVELOPER_DIR="/Xcode/9.4.1/Xcode.app/Contents/Developer"

if [ -z "${JENKINS_HOME}" ]; then
  echo "FAIL: only run this script on Jenkins"
  exit 1
fi

set +e

rm -rf reports/*.xml

run-loop simctl manage-processes

make tests

EXIT_STATUS=$?

run-loop simctl manage-processes

if [ "${EXIT_STATUS}" = "0" ]; then
  echo "Tests passed"
  exit 0
else
  echo "Tests failed."
  exit 1
fi
