#!/usr/bin/env bash

INSTALL_DIR=/usr/local/bin

cp build/Release/xctestctl "$INSTALL_DIR"
echo "Installed to $INSTALL_DIR"
