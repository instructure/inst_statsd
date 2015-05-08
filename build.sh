#!/bin/bash

set -e

# build container
docker build -t canvas_statsd .

# run the tests
docker run --rm canvas_statsd bundle exec rspec spec
