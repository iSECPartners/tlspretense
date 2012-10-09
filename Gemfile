source "http://rubygems.org"
# Add dependencies required to use your gem here.
# Example:
#   gem "activesupport", ">= 2.3.5"

gem "packetthief", "~> 0.3.0"
gem "eventmachine", ">= 1.0.0"
gem "rake", ">= 0.8.7" # Even Rake is needed by other dependencies, Ruby 1.9.x comes with Rake and that causes problems unless it is specified here.
gem "ruby-termios", ">= 0.9.6"

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
group :development do
  gem "rspec", "~> 2.8.0"
  gem "rdoc", "~> 3.12"
  gem "bundler", "~> 1.0"
#  gem "jeweler", "~> 1.8.4"
  gem "rcov", ">= 0" if RUBY_VERSION == "1.8.7"
end

