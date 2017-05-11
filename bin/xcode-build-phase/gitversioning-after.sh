#!/bin/sh

if [ -z "${1}" ]; then
echo "FATAL:  you must pass the path to IDMVersionDefines.h"
exit 1
fi

VERSION_PATH="${1}"
gitpath=`which git`

echo "INFO: resetting content of ${VERSION_PATH}"
`$gitpath checkout -- ${VERSION_PATH}`
