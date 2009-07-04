#!/bin/env ruby

# Scans the README for the current version number.

require "enumerator"

file = (ARGV[0] or "README.rdoc")

regex = /version[^0-9]+([0-9](\.[0-9])*).*/i
matches = File.open(file){ |f|
  Enumerable::Enumerator.new(f, :each_line).grep(regex)[0] =~ regex
}

puts ($1 or "0")
