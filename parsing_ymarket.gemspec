# -*- encoding: utf-8 -*-
require File.expand_path('../lib/parsing_ymarket/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Misha"]
  gem.email         = ["mic_2000@ua.fm"]
  gem.description   = %q{TODO: Write a gem description}
  gem.summary       = %q{TODO: Write a gem summary}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "parsing_ymarket"
  gem.require_paths = ["lib"]
  gem.version       = ParsingYmarket::VERSION
  gem.add_development_dependency "rspec"
end
