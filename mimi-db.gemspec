# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mimi/db/version'

Gem::Specification.new do |spec|
  spec.name          = 'mimi-db'
  spec.version       = Mimi::DB::VERSION
  spec.authors       = ['Alex Kukushkin']
  spec.email         = ['alex@kukushk.in']

  spec.summary       = 'Database module for mimi, microframework for microservices'
  spec.description   = 'Database module for mimi, microframework for microservices'
  spec.homepage      = 'https://github.com/kukushkin/mimi-db'
  spec.license       = 'MIT'

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org/'
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'mimi-core', '~> 0.1'
  spec.add_dependency 'activerecord', '~> 4.2'
  spec.add_dependency 'mini_record', '~> 0.4'
  spec.add_dependency 'with_advisory_lock', '~> 3.0'

  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'pry', '~> 0.10'
end
