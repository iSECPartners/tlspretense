#!/usr/bin/env ruby

$:.unshift(File.dirname(__FILE__)+ '/../lib') unless $:.include?(File.dirname(__FILE__)+ '/../lib')

require 'tlspretense'

TLSPretense::App.new(ARGV,$stdin,$stdout).run

