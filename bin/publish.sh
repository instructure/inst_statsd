#!/bin/bash
# shellcheck shell=bash

set -e

current_version=$(ruby -e "require '$(pwd)/lib/inst_statsd/version.rb'; puts InstStatsd::VERSION;")
existing_versions=$(gem list --exact inst_statsd --remote --all | grep -o '\((.*)\)$' | tr -d '() ')

if [[ $existing_versions == *$current_version* ]]; then
  echo "Gem has already been published ... skipping ..."
else
  gem build ./inst_statsd.gemspec
  find inst_statsd-*.gem | xargs gem push
fi
