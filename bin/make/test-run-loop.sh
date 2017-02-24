#!/usr/bin/env bash

set -e

export IOS_DEVICE_MANAGER="${PWD}"
export DEVICEAGENT_PATH="${PWD}/DeviceAgent.iOS"

rm -rf run_loop
rm -rf DeviceAgent.iOS

git clone git@github.com:calabash/run_loop.git
git clone git@github.com:calabash/DeviceAgent.iOS.git

RUN_LOOP_DIR="${PWD}/run_loop"
(cd run_loop; rake device_agent:install)

cd Tests/cucumber

echo "
source 'https://rubygems.org'
gem 'calabash-cucumber'
gem 'run_loop', :path => \"${RUN_LOOP_DIR}\"
" > Gemfile

# run_loop/Rakefile and run_loop/lib both respond to
# IOS_DEVICE_MANAGER, so we have to unset this variable.
unset IOS_DEVICE_MANAGER
bundle install
APP="../Resources/sim/TestApp.app" bundle exec cucumber

