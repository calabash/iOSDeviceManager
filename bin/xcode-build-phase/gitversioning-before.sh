#!/usr/bin/env bash

if [ -z "${1}" ]; then
echo "FATAL:  you must pass the path to IDMVersionDefines.h"
exit 1
fi

HEADER_FILE="${1}"
GITREV=`git rev-parse --short HEAD`
GITBRANCH=`git rev-parse --abbrev-ref HEAD`
GITREMOTEORIGIN=`git config --get remote.origin.url`

cat >"${HEADER_FILE}" <<EOF
/*
 Do Not Manually Edit This File
*/
#define IDM_GIT_SHORT_REVISION @"${GITREV}"
#define IDM_GIT_BRANCH @"${GITBRANCH}"
#define IDM_GIT_REMOTE_ORIGIN @"${GITREMOTEORIGIN}"
EOF
