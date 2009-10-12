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


# PathSet is essentially a Hash of { os_regex => path_templates } pairs,
# paths describing where to look for files (libraries) on each
# operating system.
# 
# * os_regex is a regular expression that matches FFI::Platform::OS
#   for the operating system(s) that the path templates are for.
# 
# * path_templates is an Array of one or more strings describing
#   a template for where a library might be found on this OS.
#   The string [NAME] will be replaced with the library name.
#   So "/usr/lib/lib[NAME].so" becomes e.g. "/usr/lib/libSDL_ttf.so".
# 
# You can use #append!, #prepend!, #replace!, #remove!, and #clear!
# to modify the paths, and #find to look for a file with a matching
# name.
# 
class NiceFFI::PathSet


  def initialize( paths={}, files={} )
    @paths = paths
    @files = files
  end
  
  attr_reader :paths, :files

  def dup
    self.class.new( @paths.dup, @files.dup )
  end


  # Append the new paths to this PathSet. If this PathSet already
  # has paths for a regex in the new paths, the new paths will be
  # added after the current paths.
  # 
  # The given paths can be Hashes or existing PathSets; or
  # Arrays to append the given paths to every existing regex.
  # 
  # 
  # Example:
  # 
  #   ps = PathSet.new( /a/ => ["liba"],
  #                     /b/ => ["libb"] )
  #   
  #   ps.append!( /a/ => ["newliba"],
  #               /c/ => ["libc"] )
  #   
  #   ps.paths
  #   # => { /a/ => ["liba",
  #   #              "newliba"],        # added in back
  #   #      /b/ => ["libb"],           # not affected
  #   #      /c/ => ["libc"] }          # added
  # 
  def append!( *pathsets )
    pathsets.each do |pathset|
      _modify( pathset ) { |a,b|  a + b }
    end
    self
  end

  # Like #append!, but returns a copy instead of modifying the original.
  def append( *pathsets )
    self.dup.append!( *pathsets )
  end

  alias :+  :append
  #alias :<< :append



  # Prepend the new paths to this PathSet. If this PathSet already
  # has paths for a regex in the new paths, the new paths will be
  # added before the current paths.
  # 
  # The given paths can be Hashes or existing PathSets; or
  # Arrays to prepend the given paths to every existing regex.
  # 
  # 
  # Example:
  # 
  #   ps = PathSet.new( /a/ => ["liba"],
  #                     /b/ => ["libb"] )
  #   
  #   ps.prepend!( /a/ => ["newliba"],
  #                /c/ => ["libc"] )
  #   
  #   ps.paths
  #   # => { /a/ => ["newliba",         # added in front
  #   #              "liba"],
  #   #      /b/ => ["libb"],           # not affected                
  #   #      /c/ => ["libc"] }          # added
  # 
  def prepend!( *pathsets )
    pathsets.each do |pathset|
      _modify( pathset ) { |a,b|  b + a }
    end
    self
  end

  # Like #prepend!, but returns a copy instead of modifying the original.
  def prepend( *pathsets )
    self.dup.prepend!( *pathsets )
  end

  #alias :>> :prepend



  # Override existing paths with the new paths to this PathSet.
  # If this PathSet already has paths for a regex in the new paths,
  # the old paths will be discarded and the new paths used instead.
  # Old paths are kept if their regex doesn't appear in the new paths.
  # 
  # The given paths can be Hashes or existing PathSets; or
  # Arrays to replace the given paths for every existing regex.
  # 
  # 
  # Example:
  # 
  #   ps = PathSet.new( /a/ => ["liba"],
  #                     /b/ => ["libb"] )
  #   
  #   ps.replace!( /a/ => ["newliba"],
  #                /c/ => ["libc"] )
  #   
  #   ps.paths
  #   # => { /a/ => ["newliba"],        # replaced
  #   #      /b/ => ["libb"],           # not affected
  #   #      /c/ => ["libc"] }          # added
  # 
  def replace!( *pathsets )
    pathsets.each do |pathset|
      _modify( pathset ) { |a,b|  b }
    end
    self
  end

  # Like #replace!, but returns a copy instead of modifying the original.
  def replace( *pathsets )
    self.dup.replace!( *pathsets )
  end



  # Remove the given paths from the PathSet, if it has them.
  # This only removes the paths that are given, other paths
  # for the same regex are kept.
  # 
  # The given paths can be Hashes or existing PathSets; or
  # Arrays to remove the given paths from every existing regex.
  # 
  # Regexes with no paths left are pruned.
  # 
  # 
  # Example:
  # 
  #   ps = PathSet.new( /a/ => ["liba", "badliba"],
  #                     /b/ => ["libb"] )
  #   
  #   ps.remove!( /a/ => ["badliba"],
  #               /b/ => ["libb"] )
  #               /c/ => ["libc"] )
  #   
  #   ps.paths
  #   # => { /a/ => ["liba"] }          # removed only "badliba".
  #   #    # /b/ paths were all removed.
  #   #    # /c/ not affected because it had no old paths anyway.
  # 
  def remove!( *pathsets )
    pathsets.each do |pathset|
      _modify( pathset ) { |a,b|  a - b }
    end
    self
  end

  # Like #remove!, but returns a copy instead of modifying the original.
  def remove( *pathsets )
    self.dup.remove!( *pathsets )
  end

  alias :- :remove



  # Remove all paths for the given regex(es). Has no effect on
  # regexes that are not given.
  # 
  # 
  # Example:
  # 
  #   ps = PathSet.new( /a/ => ["liba"],
  #                     /b/ => ["libb"] )
  #   
  #   ps.delete!( /b/, /c/ )
  #   
  #   ps.paths
  #   # => { /a/  => ["liba"] }  # not affected
  #   #    # /b/ and all paths removed.
  #   #    # /c/ not affected because it had no paths anyway.
  # 
  def delete!( *regexs )
    @paths.delete_if { |regex, paths|  regexs.include? regex }
    self
  end

  # Like #delete!, but returns a copy instead of modifying the original.
  def delete( *regexs )
    self.dup.delete!( *regexs )
  end


  # Try to find a file based on the paths in this PathSet.
  # 
  # *names:: Strings to try substituting for [NAME] in the paths.
  # 
  # Returns an Array of the paths of matching files, or [] if
  # there were no matches.
  # 
  # Raises LoadError if the current operating system did not match
  # any of the regular expressions in the PathSet.
  # 
  # Examples:
  # 
  #   ps = PathSet.new( /linux/ => ["/usr/lib/lib[NAME].so"],
  #                     /win32/ => ["C:\\windows\\system32\\[NAME].dll"] )
  #   
  #   ps.find( "SDL" )
  #   ps.find( "foo", "foo_alt_name" )
  # 
  def find( *names )

    os = FFI::Platform::OS

    # Remember the paths that we found.
    found = []

    # Remember whether any of the search paths included our OS.
    os_supported = false

    # Find the regexs that matches our OS.
    os_matches = @paths.keys.find_all{ |regex|  regex =~ os }

    # Drat, they are using an unsupported OS.
    if os_matches.empty?
      raise( LoadError, "Your OS (#{os}) is not supported yet.\n" +
             "Please report this and help us support more platforms." )
    end

    os_matches.each do |os_match|
      # Fetch the paths for the matching OS.
      paths = @paths[os_match]

      # Fill in for [NAME] and expand the paths.
      paths = names.collect { |name|
        paths.collect { |path|
          File.expand_path( path.gsub("[NAME]", name) )
        }
      }.flatten!

      # Delete all the paths that don't exist.
      paths.delete_if { |path| not File.exist?(path) }

      # Add what's left.
      found += paths
    end

    return found
  end


  private


  def _modify( other, &block )  # :nodoc:
    if other.kind_of? self.class
      # Other is a PathSet, so apply both its paths and its files to ours.
      _modify_set( @paths, other.paths, &block )
      _modify_set( @files, other.files, &block )
    else
      # Not a PathSet, so apply other to our paths.
      _modify_set( @paths, other, &block )
    end
  end


  def _modify_set( ours, other, &block )  # :nodoc:
    raise "No block given!" unless block_given?

    case other
    when Hash
      # Apply each of the regexs in `other` to the same regex in `ours`
      other.each do |regex, paths|
        _apply_modifier( ours, regex, (ours[regex] or []), paths, &block )
      end
    when Array
      # Apply `other` to each of the regexs in `ours`
      ours.each { |regex, paths|
        _apply_modifier( ours, regex, paths, other, &block )
      }
    when Regexp, String
      # Apply an Array holding `other` to each of the regexs in `ours`
      ours.each { |regex, paths|
        _apply_modifier( ours, regex, paths, [other], &block )
      }
    end
  end


  def _apply_modifier( ours, regex, a, b, &block ) # :nodoc:
    raise "No block given!" unless block_given?

    result = yield( a, b )

    if result == []
      ours.delete( regex )
    else
      ours[regex] = result
    end
  end

end
