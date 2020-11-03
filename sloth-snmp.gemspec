require_relative 'lib/sloth/snmp/version'

Gem::Specification.new do |spec|
  spec.name          = "sloth-snmp"
  spec.version       = Sloth::Snmp::VERSION
  spec.authors       = ["arimay"]
  spec.email         = ["arima.yasuhiro@gmail.com"]

  spec.summary       = %q{ Sloth Snmp Library. }
  spec.description   = %q{ Sloth::Snmp is yet another wrapper library for snmp. }
  spec.homepage      = "https://github.com/arimay/sloth-snmp"
  spec.license       = "MIT"

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "snmp"

  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
