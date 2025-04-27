# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bolt11/version'

Gem::Specification.new do |spec|
  spec.name          = 'bolt11'
  spec.version       = Bolt11::VERSION
  spec.authors       = %w[marcw johnta0]
  spec.email         = ['marc@weistroff.net', 'j0hnta@protonmail.com']

  spec.summary       = 'Decode lightning network payment invoice.'
  spec.description   = 'Decode lightning network payment invoice.'
  spec.homepage      = 'https://github.com/marcw/bolt11-ruby'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.2'

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'bech32', '~> 1.4'
  spec.add_dependency 'bigdecimal', '~> 3.0'
  spec.add_dependency 'bitcoinrb', '~> 1.8.1'

  spec.add_development_dependency 'bundler', '~> 2.5'
  spec.add_development_dependency 'rake', '~> 13.1'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 1.61'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.27'
end
