#!/usr/bin/env bash

source bin/simctl.sh
ensure_valid_core_sim_service

set -e

source bin/log.sh

info "Use the DEVICE env variable to run specific rspec tests"
info "written for physical devices and test against connected one:"
info ""
info "DEVICE=1 make rspec"
info ""
info "By default, tests will be running against iOS simulator."

bundle update

tmpfile=$(mktemp)
Products/iOSDeviceManager >/dev/null 2>"${tmpfile}"
if [ -s "${tmpfile}" ]; then
  error "Expected iOSDeviceManager to output nothing on stderr"
  error "Output captured here: ${tmpfile}"
  exit 1
else
  info "iOSDeviceManager did not have unusual output"
  rm -f "${tmpfile}"
fi

banner "Rspec tests"

if [ "$DEVICE" == "1" ]; then
  bundle exec rspec --pattern "spec/*device*_spec.rb"
else
  bundle exec rspec --exclude-pattern "spec/*device*_spec.rb"
fi

