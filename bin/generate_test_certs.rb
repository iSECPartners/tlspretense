#!/usr/bin/env ruby
$: << File.join(File.dirname(__FILE__),'..','lib')

require 'certmaker'
include CertMaker
run
