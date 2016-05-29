#!/usr/bin/env bash

DOT_DIR_FRAMEWORKS_DIR="${HOME}/.calabash/Frameworks"
mkdir -p "$DOT_DIR_FRAMEWORKS_DIR"
cp -r Frameworks/*.framework "$DOT_DIR_FRAMEWORKS_DIR"
