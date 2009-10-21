#--
#
# This file is one part of:
#
# Nice-FFI - Convenience layer atop Ruby-FFI
#
# Copyright (c) 2009 John Croisant
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
#++


# Force create ChangeLog.txt if running from gem (build).
# This is done in Rakefile when running from rake.
if /gem/i =~ $0
  `ruby scripts/mkchangelog.rb ChangeLog.txt`
end


$gemspec = Gem::Specification.new do |s|

  s.name     = "nice-ffi"
  s.version  = "0.2"
  s.authors  = ["John Croisant"]
  s.email    = "jacius@gmail.com"
  s.homepage = "http://github.com/jacius/nice-ffi/"
  s.summary  = "Convenience layer atop Ruby-FFI"
  s.description = <<EOF
Nice-FFI is a layer on top of Ruby-FFI (and compatible FFI systems)
with features to ease development of FFI-based libraries.
EOF

  s.has_rdoc = true
  s.rubyforge_project = "nice-ffi"

  s.files = Dir["**/*.rdoc", "lib/**/*.rb"] + ["ChangeLog.txt"]
  s.require_paths = ["lib"]

  s.required_ruby_version = ">= 1.8"

  s.add_dependency( "ffi",  ">=0.5.0" )

end
