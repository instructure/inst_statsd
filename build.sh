#!/bin/bash

set -e

# build container
docker build -t inst_statsd .

# run the tests
docker run --rm inst_statsd bundle exec appraisal rspec spec
