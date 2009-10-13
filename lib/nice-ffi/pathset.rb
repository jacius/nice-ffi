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


# PathSet is a collection of directory paths and file name templates,
# used to help NiceFFI find library files. It allows per-operating
# system paths and file name templates, using regular expressions to
# match the OS name.
# 
# Each PathSet holds two hashes, @paths and @files.
# 
# * The keys for both hashes are regexps that match FFI::Platform::OS
#   for the operating system(s) that the paths or file templates
#   apply to.
# 
# * The values of @paths are Arrays of one or more strings describing
#   a directory for where a library might be found on this OS. So for
#   example, one pair in the hash might be { /linux|bsd/ =>
#   ["/usr/local/lib/", "/usr/lib/"] }, which means "For operating
#   systems that match /linux|bsd/ (e.g. linux, freebsd, and openbsd),
#   look first in /usr/local/lib/, then in /usr/lib/."
# 
# * The value of @files are Arrays of one or more strings describing
#   the possible formats of library names for that operating system.
#   These are templates -- they should include string "[NAME]",
#   which will be replaced with the library name. For example,
#   "lib[NAME].so" would become "libSDL_ttf.so" when searching for the
#   "SDL_ttf" library.
# 
# There are many methods to modify one or both of the hashes, such as
# #append!, #prepend!, #replace!, #remove!, and #delete!.
# 
# You can use #find to look for a file with a matching name.
# 
# NiceFFI::PathSet::DEFAULT is a pre-made PathSet with paths and file
# name templates for Linux/BSD, Mac (Darwin), and Windows. It is the
# default PathSet used by NiceFFI::Library.load_library, and you can
# also use it as a base for custom PathSets.
# 
class NiceFFI::PathSet


  def initialize( paths={}, files={} )
    @paths = {}
    @files = {}
    append_paths!( paths )
    append_files!( files )
  end
  
  attr_reader :paths, :files

  def dup
    self.class.new( @paths.dup, @files.dup )
  end


  # Append the new paths and/or files to this PathSet. If this PathSet
  # already has entries for a given regex, the new entries will be
  # added after the current entries.
  # 
  # pathsets:: One or more PathSets, Hashes, Arrays, or Strings,
  #            or any assortment of these types.
  # 
  # * If given a PathSet, its @paths and @files are appended to this
  #   PathSet's @paths and @files (respectively).
  # 
  # * If given a Hash, it is appended to this PathSet's @paths, but
  #   @files is not affected.
  # 
  # * If given an Array (which should contain only Strings), the array
  #   contents are appended to this PathSet's @paths.
  # 
  # * If given a String, the string is appended to this PathSet's
  #   @paths.
  # 
  # * If given multiple objects, they are handled in order according to
  #   the above rules.
  # 
  # See also #append_paths! and #append_files!.
  # 
  #--
  # Example (out of date):
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
  #++
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


  # Like #append!, but only affects @paths, and never affects @files.
  # See also #append_paths for a non-destructive version.
  def append_paths!( *paths )
    _modify_part( :paths, paths ) { |a,b|  a + b }
    self
  end

  # Like #append_paths!, but returns a copy instead of modifying the
  # original.
  def append_paths( *paths )
    self.dup.append_paths!( *paths )
  end


  # Like #append!, but affects @files, and never affects @paths.
  # See also #append_files for a non-destructive version.
  def append_files!( *files )
    _modify_part( :files, files ) { |a,b|  a + b }
    self
  end

  # Like #append_files!, but returns a copy instead of modifying the
  # original.
  def append_files( *files )
    self.dup.append_files!( *files )
  end



  # Prepend the new paths and/or files to this PathSet. If this PathSet
  # already has entries for a given regex, the new entries will be
  # added before the current entries.
  # 
  # pathsets:: One or more PathSets, Hashes, Arrays, or Strings,
  #            or any assortment of these types.
  # 
  # * If given a PathSet, its @paths and @files are prepended to this
  #   PathSet's @paths and @files (respectively).
  # 
  # * If given a Hash, it is prepended to this PathSet's @paths, but
  #   @files is not affected.
  # 
  # * If given an Array (which should contain only Strings), the array
  #   contents are prepended to this PathSet's @paths.
  # 
  # * If given a String, the string is prepended to this PathSet's
  #   @paths.
  # 
  # * If given multiple objects, they are handled in order according to
  #   the above rules.
  # 
  # See also #prepend_paths! and #prepend_files!.
  # 
  #--
  # Example (out of date):
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
  #++
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


  # Like #prepend!, but only affects @paths, and never affects @files.
  # See also #prepend_paths for a non-destructive version.
  def prepend_paths!( *paths )
    _modify_part( :paths, paths ) { |a,b|  b + a }
    self
  end

  # Like #prepend_paths!, but returns a copy instead of modifying the
  # original.
  def prepend_paths( *paths )
    self.dup.prepend_paths!( *paths )
  end


  # Like #prepend!, but affects @files, and never affects @paths.
  # See also #prepend_files for a non-destructive version.
  def prepend_files!( *files )
    _modify_part( :files, files ) { |a,b|  b + a }
    self
  end

  # Like #prepend_files!, but returns a copy instead of modifying the
  # original.
  def prepend_files( *files )
    self.dup.prepend_files!( *files )
  end



  # Override existing entries in this PathSet with the new entries.
  # If this PathSet already has entries for a regex in the new entries,
  # the old entries will be discarded and the new entries used instead.
  # 
  # pathsets:: One or more PathSets, Hashes, Arrays, or Strings,
  #            or any assortment of these types.
  # 
  # * If given a PathSet, its @paths and @files are prepended to this
  #   PathSet's @paths and @files (respectively). Old entries in this
  #   PathSet are kept if their regex doesn't appear in the given
  #   PathSet.
  # 
  # * If given a Hash, entries in this PathSet's @paths are replaced
  #   with the new entries, but @files is not affected. Old entries in
  #   this PathSet are kept if their regex doesn't appear in the given
  #   PathSet.
  # 
  # * If given an Array (which should contain only Strings), entries
  #   for every regex in this PathSet's @paths are replaced with the
  #   array contents.
  # 
  # * If given a String, all entries for every regex in this PathSet's
  #   @paths are replaced with the string.
  # 
  # * If given multiple objects, they are handled in order according to
  #   the above rules.
  # 
  # See also #replace_paths! and #replace_files!.
  # 
  #--
  # Example (out of date):
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
  #++
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


  # Like #replace!, but only affects @paths, and never affects @files.
  # See also #replace_paths for a non-destructive version.
  def replace_paths!( *paths )
    _modify_part( :paths, paths ) { |a,b|  b }
    self
  end

  # Like #replace_paths!, but returns a copy instead of modifying the
  # original.
  def replace_paths( *paths )
    self.dup.replace_paths!( *paths )
  end


  # Like #replace!, but affects @files, and never affects @paths.
  # See also #replace_files for a non-destructive version.
  def replace_files!( *files )
    _modify_part( :files, files ) { |a,b|  b }
    self
  end

  # Like #replace_files!, but returns a copy instead of modifying the
  # original.
  def replace_files( *files )
    self.dup.replace_files!( *files )
  end



  # Remove the given entries from the PathSet, if it has them. This
  # only removes the entries that are given, other entries for the
  # same regex are kept. Regexes with no entries left afterwards are
  # removed from the PathSet.
  # 
  # pathsets:: One or more PathSets, Hashes, Arrays, or Strings,
  #            or any assortment of these types.
  # 
  # * If given a PathSet, entries from its @paths and @files are
  #   removed from this PathSet's @paths and @files (respectively).
  # 
  # * If given a Hash, the given entries are removed from this
  #   PathSet's @paths, but @files is not affected.
  # 
  # * If given an Array (which should contain only Strings), the array
  #   contents are removed from the entries for every regex in this
  #   PathSet's @paths.
  # 
  # * If given a String, the string is removed from the entries for
  #   every regex in this PathSet's @paths.
  # 
  # * If given multiple objects, they are handled in order according to
  #   the above rules.
  # 
  # See also #remove_paths! and #remove_files!.
  # 
  #--
  # Example (out of date):
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
  #++
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


  # Like #remove!, but only affects @paths, and never affects @files.
  # See also #remove_paths for a non-destructive version.
  def remove_paths!( *paths )
    _modify_part( :paths, paths ) { |a,b|  a - b }
    self
  end

  # Like #remove_paths!, but returns a copy instead of modifying the
  # original.
  def remove_paths( *paths )
    self.dup.remove_paths!( *paths )
  end


  # Like #remove!, but affects @files, and never affects @paths.
  # See also #remove_files for a non-destructive version.
  def remove_files!( *files )
    _modify_part( :files, files ) { |a,b|  a - b }
    self
  end

  # Like #remove_files!, but returns a copy instead of modifying the
  # original.
  def remove_files( *files )
    self.dup.remove_files!( *files )
  end



  # Delete all entries for the given regex(es) from both @paths and
  # @files. Has no effect on entries for regexes that are not given.
  # 
  # See also #delete_paths! and #delete_files!.
  # 
  #--
  # Example (out of date):
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
  #++ 
  def delete!( *regexs )
    @paths.delete_if { |regex, paths|  regexs.include? regex }
    @files.delete_if { |regex, files|  regexs.include? regex }
    self
  end

  # Like #delete!, but returns a copy instead of modifying the original.
  def delete( *regexs )
    self.dup.delete!( *regexs )
  end


  # Like #delete!, but only affects @paths, and never affects @files.
  # See also #delete_paths for a non-destructive version.
  def delete_paths!( *regexs )
    @paths.delete_if { |regex, paths|  regexs.include? regex }
    self
  end

  # Like #delete_paths!, but returns a copy instead of modifying the original.
  def delete_paths( *regexs )
    self.dup.delete_paths!( *regexs )
  end


  # Like #delete!, but affects @files, and never affects @paths.
  # See also #delete_files for a non-destructive version.
  def delete_files!( *regexs )
    @files.delete_if { |regex, files|  regexs.include? regex }
    self
  end

  # Like #delete_files!, but returns a copy instead of modifying the original.
  def delete_files( *regexs )
    self.dup.delete_files!( *regexs )
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
  #--
  # Examples (out of date):
  # 
  #   ps = PathSet.new( /linux/ => ["/usr/lib/lib[NAME].so"],
  #                     /win32/ => ["C:\\windows\\system32\\[NAME].dll"] )
  #   
  #   ps.find( "SDL" )
  #   ps.find( "foo", "foo_alt_name" )
  #++
  def find( *names )
    os = FFI::Platform::OS

    # Fetch the paths and files for the matching OSes.
    paths = @paths.collect{ |regex,ps| regex =~ os ? ps : [] }.flatten
    files = @files.collect{ |regex,fs| regex =~ os ? fs : [] }.flatten

    # Drat, they are using an OS with no matches.
    if paths.empty? and files.empty?
      raise( LoadError, "Your OS (#{os}) is not supported yet.\n" +
             "Please report this and help us support more platforms." )
    end

    results = paths.collect do |path|
      files.collect do |file|
        names.collect do |name|
          # Concat path and file, fill in for [NAME], and expand.
          File.expand_path( (path+file).gsub("[NAME]", name) )
        end
      end
    end

    return results.flatten.select{ |r| File.exist? r }
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

  # This method does the work for #append_paths, #append_files,
  # #prepend_paths, etc.
  # 
  # * part is either :paths or :files. It indicates whether @paths or
  #   @files should be modified, and whether to get values from
  #   other.paths or other.files when other is a PathSet.
  # 
  # * others is an array which may contain one or more PathSets,
  #   Hashes, Arrays, Strings, or a mixture of those types. Each item
  #   is passed to #_modify_set. PathSets are changed into either
  #   other.paths or other.files first, though.
  #
  def _modify_part( part, others, &block ) # :nodoc:
    unless [:paths, :files].include? part
      raise( ArgumentError, "Invalid PathSet part #{part.inspect} " +
             "(expected :paths or :files)" )
    end

    ours = self.send(part)      # self.paths or self.files
    others.each do |other|
      if other.kind_of? self.class
        other = other.send(part)
      end
      _modify_set( ours, other, &block )
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
    when String
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



#--
# NOTE: If you update these defaults, update doc/usage.rdoc too.
#++

paths = {
  /linux|bsd/  => [ "/usr/local/lib/",
                    "/usr/lib/" ],

  /darwin/     => [ "/usr/local/lib/",
                    "/sw/lib/",
                    "/opt/local/lib/",
                    "~/Library/Frameworks/",
                    "/Library/Frameworks/" ],

  /win32/      => [ "C:\\windows\\system32\\",
                    "C:\\windows\\system\\" ]
}

files = {
  /linux|bsd/  => [ "lib[NAME].so" ],

  /darwin/     => [ "lib[NAME].dylib",
                    "[NAME].framework/[NAME]" ],

  /win32/      => [ "[NAME].dll" ]
}

# The default paths to look for libraries. See PathSet 
# and NiceFFI::Library.load_library.
# 
NiceFFI::PathSet::DEFAULT = NiceFFI::PathSet.new( paths, files )
