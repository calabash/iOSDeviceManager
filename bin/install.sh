#!/usr/bin/env bash

INSTALL_DIR=/usr/local/bin

cp build/Release/test-control "$INSTALL_DIR"
echo "Installed to $INSTALL_DIR"
