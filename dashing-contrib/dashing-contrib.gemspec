# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dashing-contrib/version'

Gem::Specification.new do |spec|
  spec.name          = "dashing-contrib"
  spec.version       = DashingContrib::VERSION
  spec.authors       = ["Jing Dong"]
  spec.email         = ["me@jing.io"]
  spec.description   = %q{ Dashing Contrib aims to make templates plugins easy to maintain and contribute }
  spec.summary       = %q{ An extension to Dashing that makes easier to maintaining, sharing widgets and test common tasks }
  spec.homepage      = 'https://github.com/QubitProducts/dashing-contrib'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']
  
  spec.add_dependency 'dotenv', '~> 0.11.1'
  spec.add_dependency 'thor', '~> 0.18.1'
  spec.add_dependency 'rest-client', '~> 1.6'
  spec.add_dependency 'multi_json', '~> 1.10'
  spec.add_dependency 'time_diff', '~> 0.3'
  spec.add_dependency 'sidekiq', '~> 3.0'
  spec.add_dependency 'activesupport', '~> 4.1'
  spec.add_dependency 'sinatra', '~> 1.4'
  spec.add_dependency 'dashing', '~> 1.3'
  spec.add_dependency 'nagiosharder', '~> 0'

  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
end
