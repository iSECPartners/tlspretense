#!/usr/bin/env ruby
$: << File.join(File.dirname(__FILE__),'..','lib')

require 'certmaker'
require 'yaml'

y = YAML.load_file('config.yml')
CertMaker.make_certs y
