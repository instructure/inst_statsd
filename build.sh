#!/bin/bash

set -e

# build container
docker build -t inst_statsd .

# run the tests

for f in Gemfile.*.lock
do
  docker run -e BUNDLE_LOCKFILE=$f --rm inst_statsd bin/rspec
done
