#!/usr/bin/env bash

# TODO: Make this a lot nicer
xcrun xcodebuild

mkdir -p Products
mv build/Release/iOSDeviceManager Products
