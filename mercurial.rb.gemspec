# -*- encoding: utf-8 -*-
require File.expand_path('../lib/mercurial/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Stefan Huber"]
  gem.email         = ["MSNexploder@gmail.com"]
  gem.description   = 'mercurial wrapper for ruby'
  gem.summary       = 'mercurial.rb exposes the mercurial scm via embedded python'
  gem.homepage      = "http://github.com/msnexploder/mercurial.rb"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "mercurial.rb"
  gem.require_paths = ["lib"]
  gem.extensions    = ["ext/mercurial/extconf.rb"]
  gem.version       = Mercurial::VERSION
  
  gem.add_dependency 'posix-spawn', '~> 0.3.6'
  gem.add_development_dependency 'rake', '~> 0.9.2'
end
