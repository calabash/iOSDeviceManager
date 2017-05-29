#!/usr/bin/env bash

if [ -z "${1}" ]; then
echo "FATAL:  you must pass the path to IDMVersionDefines.h"
exit 1
fi

VERSION_PATH="${1}"
gitpath=`which git`
GITREV=`$gitpath rev-parse --short HEAD`
GITBRANCH=`git rev-parse --abbrev-ref HEAD`
GITREMOTEORIGIN=`git config --get remote.origin.url`

echo "INFO: setting the GIT_SHORT_REVISION = ${GITREV} in ${VERSION_PATH}"
echo "#define IDM_GIT_SHORT_REVISION @\"${GITREV}\"" >> "${VERSION_PATH}"
echo "INFO: setting the GIT_BRANCH = ${GITBRANCH} in ${VERSION_PATH}"
echo "#define IDM_GIT_BRANCH @\"${GITBRANCH}\"" >> "${VERSION_PATH}"
echo "INFO: setting the GIT_REMOTE_ORIGIN = ${GITREMOTEORIGIN} in ${VERSION_PATH}"
echo "#define IDM_GIT_REMOTE_ORIGIN @\"${GITREMOTEORIGIN}\"" >> "${VERSION_PATH}"
