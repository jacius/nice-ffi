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


require 'rake'


#############
##   GEM   ##
#############

require 'rake/gempackagetask'

# Load nice-ffi.gemspec, which defines $gemspec.
load File.join( File.dirname(__FILE__), "nice-ffi.gemspec" )

Rake::GemPackageTask.new( $gemspec ) do |pkg|
  pkg.need_tar_bz2 = true
end


############
##  DOCS  ##
############

require 'rake/rdoctask'

Rake::RDocTask.new do |rd|
  rd.title = "Nice-FFI #{$gemspec.version} Docs"
  rd.main = "README.rdoc"
  rd.rdoc_files.include( "lib/**/*.rb", "*.rdoc" )
end


#########
# SPECS #
#########

begin
  require 'spec/rake/spectask'

  desc "Run all specs"
  Spec::Rake::SpecTask.new do |t|
    t.spec_files = FileList['spec/*_spec.rb']
  end

  namespace :spec do
    desc "Run all specs"
    Spec::Rake::SpecTask.new(:all) do |t|
      t.spec_files = FileList['spec/*_spec.rb']
    end

    desc "Run spec/[name]_spec.rb (e.g. 'color')"
    task :name do
      puts( "This is just a stand-in spec.",
            "Run rake spec:[name] where [name] is e.g. 'color', 'music'." )
    end
  end


rule(/spec:.+/) do |t|
  name = t.name.gsub("spec:","")

  path = File.join( File.dirname(__FILE__),'spec','%s_spec.rb'%name )

  if File.exist? path
    Spec::Rake::SpecTask.new(name) do |t|
      t.spec_files = [path]
    end

    puts "\nRunning spec/%s_spec.rb"%name

    Rake::Task[name].invoke
  else
    puts "File does not exist: %s"%path
  end

end

rescue LoadError

  error = "ERROR: RSpec is not installed?"

  task :spec do 
    puts error
  end

  rule( /spec:.*/ ) do
    puts error
  end

end


###############
##  VERSION  ##
###############

task :version do
  puts "%s-%s"%[$gemspec.name, $gemspec.version]
end
