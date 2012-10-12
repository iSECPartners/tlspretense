#!/usr/bin/env ruby

$:.unshift(File.dirname(__FILE__)+ '/../lib') unless $:.include?(File.dirname(__FILE__)+ '/../lib')

require 'ssl_test'

SSLTest::Runner.new(ARGV,$stdin,$stdout).run

