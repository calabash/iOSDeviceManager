#!/usr/bin/env bash

if [ -z "${FBSIMCONTROL_PATH}" ]; then
  error "Set FBSIMCONTROL_PATH=/path/to/FBSimulatorControl and rerun"
  exit 1
fi

set -e
source bin/log_functions.sh

rm -rf ./Frameworks/*.framework
HERE=$(pwd)

(cd "${FBSIMCONTROL_PATH}";
 make frameworks;
 cp -r build/Release/* "${HERE}/Frameworks")

