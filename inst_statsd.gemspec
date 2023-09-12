# frozen_string_literal: true

require_relative "lib/inst_statsd/version"

Gem::Specification.new do |spec|
  spec.name          = "inst_statsd"
  spec.version       = InstStatsd::VERSION
  spec.authors       = ["Nick Cloward", "Jason Madsen"]
  spec.email         = ["ncloward@instructure.com", "jmadsen@instructure.com"]
  spec.summary       = "Statsd for Instructure"
  spec.homepage      = "https://github.com/instructure/inst_statsd"
  spec.license       = "MIT"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w[test.sh]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.7"

  spec.add_dependency "aroi", ">= 0.0.7"
  spec.add_dependency "dogstatsd-ruby", ">= 4.2", "< 6.0", "!= 5.0.0" # need the #batch method that's not in 5.0.0
  spec.add_dependency "statsd-ruby", "~> 1.0"

  spec.add_development_dependency "bundler", ">= 1.5"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rubocop-inst"
  spec.add_development_dependency "rubocop-rake"
  spec.add_development_dependency "rubocop-rspec"
end
