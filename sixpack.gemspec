# -*- encoding: utf-8 -*-
require File.expand_path('../lib/sixpack/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["SeatGeek"]
  gem.email         = ["hi@seatgeek.com"]
  gem.description   = %q{Ruby library for interacting with SeatGeek's sixpack.}
  gem.summary       = %q{Ruby library for interacting with SeatGeek's sixpack.}
  gem.homepage      = "http://www.seatgeek.com"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "sixpack-client"
  gem.require_paths = ["lib"]
  gem.version       = Sixpack::VERSION

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'redis'
  gem.add_development_dependency 'json'

  gem.add_runtime_dependency 'uuid'
  gem.add_runtime_dependency 'addressable'
end
