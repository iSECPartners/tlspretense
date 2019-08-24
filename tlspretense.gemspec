lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tlspretense/version'

Gem::Specification.new do |s|
  s.name = "tlspretense"
  s.version = TLSPretense::VERSION
  s.authors = ["William (B.J.) Snow Orvis"]
  s.email = "bjorvis@isecpartners.com"
  s.date = Time.now.utc.strftime("%Y-%m-%d")
  s.homepage = "https://github.com/iSECPartners/tlspretense"
  s.licenses = ["MIT"]

  s.summary = "SSL/TLS client testing framework"
  s.description = <<-QUOTE
    TLSPretense provides a set of tools to test SSL/TLS certificate validation.
    It includes a library for generating certificates and a test framework for
    running tests against a client by intercepting client network traffic."
  QUOTE
  s.executables = ["tlspretense"]
  s.files = Dir['lib/**/*.rb'] + Dir['lib/*.rdoc'] + Dir['bin/*']
  s.files += Dir['packetthief_examples/**/*'] + Dir['spec/**/*.rb']
  s.files += ['tlspretense.gemspec', 'Rakefile', 'README.rdoc', 'LICENSE.txt']
  s.files += ['Gemfile', '.travis.yml', '.rspec', '.gitignore', '.document']
  s.test_files = s.files.grep(%r{^(spec)/})
  s.require_paths = ["lib"]
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc",
  ] + s.files.grep(%r{^(doc)/})

  s.add_runtime_dependency("eventmachine", [">= 1.0.0"])
  s.add_runtime_dependency("ruby-termios", [">= 0.9.6"])
  s.add_development_dependency("rake", ["~> 12.3"])
  s.add_development_dependency("rspec", ["~> 3.7"])
  s.add_development_dependency("rdoc", ["~> 3.12"])
  s.add_development_dependency("bundler", ["~> 2.0"])
  s.add_development_dependency("simplecov", ["~> 0.7"])
end

