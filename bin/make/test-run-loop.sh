#!/usr/bin/env bash

set -e

export IOS_DEVICE_MANAGER=`pwd` # For building run_loop

## Checkout the latest run_loop@develop
git clone git@github.com:calabash/run_loop.git 
git clone git@github.com:calabash/DeviceAgent.iOS.git
cd run_loop
RUN_LOOP_DIR=`pwd`
git checkout develop
git pull

# Build RunLoop
rake device_agent:build # Builds DeviceAgent/iOSDeviceManager
gem build run_loop.gemspec
gem uninstall *.gem
gem install *.gem 
GEM_FILE=`echo *.gem`
GEM_VERSION=`echo ${GEM_FILE%.*} | cut -d '-' -f2`

# Update the Gemfile in the cucumber dir
cd ../Tests/cucumber
sed -i '' -e '$ d' Gemfile # Delete existing gem 'run_loop' in Gemfile
echo "gem 'run_loop', '$GEM_VERSION'" >> Gemfile

# Run the tests
export IOS_DEVICE_MANAGER=""
bundle install
APP="../Resources/sim/TestApp.app" bundle exec cucumber

# Clean Up
cd ../..
rm -rf run_loop/
rm -rf DeviceAgent.iOS/
