$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'pushwagner/version'

Gem::Specification.new do |s|
  s.name          = 'pushwagner'
  s.version       = Pushwagner::VERSION
  s.date          = Time.now.strftime("%Y-%m-%d")

  s.description   = "Simple remote automation wrapper."
  s.summary       = s.description

  s.authors       = ["Ole Christian Rynning"]
  s.email         = 'oc@rynning.no'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files spec`.split("\n")
  s.licenses      = ['MIT']
  s.homepage      = 'http://rubygems.org/gems/pushwagner'
  s.executables   = ['pw']
  s.require_paths = ['lib']

  s.required_rubygems_version = Gem::Requirement.new('>= 1.3.6')

  s.add_runtime_dependency 'net-ssh'
  s.add_runtime_dependency 'net-scp'
  s.add_runtime_dependency 'nokogiri', '~> 1.5'

  s.add_development_dependency 'bundler', '~> 1.0'
  s.add_development_dependency 'rake', '~> 0.9'
  s.add_development_dependency 'rspec', '~> 2.11'

end