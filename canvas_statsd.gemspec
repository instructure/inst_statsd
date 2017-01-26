# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "canvas_statsd"
  spec.version       = "2.0.0"
  spec.authors       = ["Nick Cloward", "Jason Madsen"]
  spec.email         = ["ncloward@instructure.com", "jmadsen@instructure.com"]
  spec.summary       = %q{Statsd for Canvas}
  spec.homepage      = "https://github.com/instructure/canvas_statsd"
  spec.license       = "MIT"

  spec.files         = Dir.glob("{lib,spec}/**/*") + %w(test.sh)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "statsd-ruby", "~> 1.0"
  spec.add_dependency "aroi", "~> 0.0.4"

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "byebug"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
