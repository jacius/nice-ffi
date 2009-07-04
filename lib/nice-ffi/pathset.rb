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


# PathSet represents a set of searchpaths for multiple operating systems.
class NiceFFI::PathSet


  def initialize( rules={} )
    @rules = rules
  end
  
  attr_reader :rules

  def dup
    self.class.new( @rules.dup )
  end


  def append!( *ruleses )
    ruleses.each do |rules|
      _modify( rules ) { |a,b|  a + b }
    end
    self
  end

  def append( *ruleses )
    self.dup.append!( *ruleses )
  end

  alias :+ :append



  def prepend!( *ruleses )
    ruleses.each do |rules|
      _modify( rules ) { |a,b|  b + a }
    end
    self
  end

  def prepend( *ruleses )
    self.dup.prepend!( *ruleses )
  end



  def replace!( *ruleses )
    ruleses.each do |rules|
      _modify( rules ) { |a,b|  b }
    end
    self
  end

  def replace( *ruleses )
    self.dup.replace!( *ruleses )
  end



  def remove!( *ruleses )
    ruleses.each do |rules|
      _modify( rules ) { |a,b|  a - b }
    end
    self
  end

  def remove( *ruleses )
    self.dup.remove!( *ruleses )
  end

  alias :- :remove



  def clear!( *regexs )
    @rules.delete_if { |regex, paths|  regexs.include? regex }
    self
  end

  def clear( *regexs )
    self.dup.clear!( *regexs )
  end


  # Try to find a file based on the rules in this PathSet.
  # 
  # name: A string to substitute for [NAME] in the paths.
  # 
  # Returns an Array of the paths of matching files, or [] if
  # there were no matches.
  # 
  # Raises LoadError if the current operating system did not match
  # any of the regular expressions in the PathSet.
  # 
  def find( name )
    os = FFI::Platform::OS

    # Remember the paths that we found.
    found = []

    # Remember whether any of the search paths included our OS.
    os_supported = false

    # Find the regexs that matches our OS.
    os_matches = @rules.keys.find_all{ |regex|  regex =~ os }

    # Drat, they are using an unsupported OS.
    if os_matches.empty?
      raise( LoadError, "Your OS (#{os}) is not supported yet.\n" +
             "Please report this and help us support more platforms." )
    end

    os_matches.each do |os_match|
      # Fetch the paths for the matching OS.
      paths = @rules[os_match]

      # Fill in for [LIB] and expand the paths.
      paths = paths.collect { |path|
        File.expand_path( path.gsub("[LIB]", name) )
      }

      # Delete all the paths that don't exist.
      paths.delete_if { |path| not File.exist?(path) }

      # Add what's left.
      found += paths
    end

    return found
  end


  private


  def _modify( rules, &block )  # :nodoc:
    raise "No block given!" unless block_given?

    case rules
    when self.class
      _modify( rules.rules, &block )
    when Hash
      rules.each do |regex, paths|
        _apply_modifier( regex, (@rules[regex] or []), paths, &block )
      end
    when Array
      @rules.each { |regex, paths|
        _apply_modifier( regex, paths, rules, &block )
      }
    end
  end


  def _apply_modifier( regex, a, b, &block ) # :nodoc:
    raise "No block given!" unless block_given?

    result = yield( a, b )

    if result == []
      @rules.delete( regex )
    else
      @rules[regex] = result
    end
  end

end
