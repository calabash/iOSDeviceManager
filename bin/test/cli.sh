#!/usr/bin/env bash

set +e
source bin/simctl.sh
ensure_valid_core_sim_service
set -e

source bin/log.sh

make build
bundle exec rspec spec
