#!/usr/bin/env ruby

$:.unshift(File.dirname(__FILE__)+ '/../lib') unless $:.include?(File.dirname(__FILE__)+ '/../lib')
$:.unshift(File.dirname(__FILE__)+ '/../packetthief/lib') unless $:.include?(File.dirname(__FILE__)+ '/../packetthief/lib')

require 'ssl_test'

SSLTest::Runner.new(ARGV,$stdin,$stdout).run

