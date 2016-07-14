#!/usr/bin/env bash

set -e

source bin/log_functions.sh

if [ -z "${FBSIMCONTROL_PATH}" ]; then
  error "Set FBSIMCONTROL_PATH=/path/to/FBSimulatorControl and rerun"
  exit 1
fi

rm -rf ./Frameworks/*.framework
HERE=$(pwd)

(cd "${FBSIMCONTROL_PATH}";
 make frameworks;
 mkdir -p "${HERE}/Frameworks"
 cp -r build/Release/* "${HERE}/Frameworks")

