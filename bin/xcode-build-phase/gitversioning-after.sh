#!/usr/bin/env bash

if [ -z "${1}" ]; then
echo "FATAL:  you must pass the path to IDMVersionDefines.h"
exit 1
fi

HEADER_FILE="${1}"
echo "INFO: resetting content of ${HEADER_FILE}"
git checkout -- "${HEADER_FILE}"
