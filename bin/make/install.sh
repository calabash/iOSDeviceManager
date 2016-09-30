#!/usr/bin/env bash
set -e

EXE_DIR=/usr/local/bin
SHIM=client/iOSDeviceManager
INSTALL_DIR=/usr/local/bin/iOSDeviceManagerServer
BIN_DIR=Distribution/dependencies/bin
FRAMEWORKS_DIR=Distribution/dependencies/Frameworks

if [ -d "${INSTALL_DIR}" ]; then
  rm -rf "${INSTALL_DIR}"
fi

mkdir -p "${INSTALL_DIR}"

cp -r "${BIN_DIR}" "${INSTALL_DIR}/bin"
cp -r "${FRAMEWORKS_DIR}" "${INSTALL_DIR}/Frameworks"
cp "${SHIM}" "${EXE_DIR}"
