#!/usr/bin/ruby

VPS_BITBAR_ROOT = File.dirname(File.realdirpath(__FILE__))
VPS_ROOT = File.expand_path('../lib', VPS_BITBAR_ROOT)

$LOAD_PATH.unshift VPS_ROOT

Encoding::default_internal = Encoding::UTF_8
Encoding::default_external = Encoding::UTF_8

require 'vps'

$stderr.reopen(File.new('/dev/null', 'w'))
print VPS::Plugins::IAWriter::preprocess_markdown(ENV['MARKED_PATH'], STDIN.read)
