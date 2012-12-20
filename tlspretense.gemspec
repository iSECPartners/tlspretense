require './lib/tlspretense/version'

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
  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files spec`
  s.require_paths = ["lib"]
  s.extra_rdoc_files = [
    "LICENSE.txt",
    "README.rdoc",
  ] + `git ls-files doc`.split("\n")

  s.add_runtime_dependency("eventmachine", [">= 1.0.0"])
  s.add_runtime_dependency("ruby-termios", [">= 0.9.6"])
  s.add_development_dependency("rake", [">= 0.8.7"])
  s.add_development_dependency("rspec", ["~> 2.8.0"])
  s.add_development_dependency("rdoc", ["~> 3.12"])
  s.add_development_dependency("bundler", ["~> 1.0"])
  s.add_development_dependency("simplecov", ["~> 0.7"])
end

