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


require 'ffi'

need{ 'typedpointer' }
need{ 'pathset' }


# A module to be used in place of FFI::Library. It acts mostly
# like FFI::Library, but with some nice extra features and
# conveniences to make life easier:
# 
# * attach_function accepts TypedPointers as return type,
#   in which case it wraps the return value of the bound function
#   in the TypedPointer's type.
# 
module NiceFFI::Library

  def self.extend_object( klass )
    klass.extend FFI::Library
    super
  end


  # A Hash of { os_regex => path_templates } pairs describing
  # where to look for libraries on each operating system.
  # 
  # * os_regex is a regular expression that matches FFI::Platform::OS
  #   for the operating system(s) that the path templates are for.
  # 
  # * path_templates is be an Array of one or more strings
  #   describing a template for where a library might be found on this
  #   OS. The string [LIB] will be replaced with the library name.
  #   So "/usr/lib/lib[LIB].so" becomes e.g. "/usr/lib/libSDL_ttf.so".
  # 
  DEFAULT_PATHS = NiceFFI::PathSet.new(

    /linux|bsd/  => [ "/usr/local/lib/lib[LIB].so",
                      "/usr/lib/lib[LIB].so",
                      "[LIB]" ],

    /darwin/     => [ "/usr/local/lib/lib[LIB].dylib",
                      "/sw/lib/lib[LIB].dylib",
                      "/opt/local/lib/lib[LIB].dylib",
                      "~/Library/Frameworks/[LIB].framework/[LIB]",
                      "/Library/Frameworks/[LIB].framework/[LIB]",
                      "[LIB]" ],

    /win32/      => [ "C:\\windows\\system32\\[LIB].dll",
                      "C:\\windows\\system\\[LIB].dll",
                      "[LIB]" ]

  )


  # Try to find and load a library (e.g. "SDL_ttf") into an FFI
  # wrapper module (e.g. SDL::TTF). This method searches in
  # different locations depending on your OS. See DEFAULT_PATHS.
  # 
  # Returns the path to the library that was loaded.
  # 
  # Raises LoadError if it could not find or load the library.
  # 
  def load_library( lib_name, search_paths=DEFAULT_PATHS )

    paths = find_library( lib_name, search_paths )

    # Oops, couldn't find it anywhere.
    if paths.empty?
      raise LoadError, "Could not find library #{lib_name}. Is it installed?"
    end

    # Try loading each path until one works.
    loaded = paths.find { |path| 
      begin
        self.module_eval {
          ffi_lib path
        }
      rescue LoadError
        false
      else
        true
      end
    }

    # Oops, none of them worked.
    if loaded.nil?
      raise( LoadError, "Could not load library #{lib_name}." )
    else
      # Return the one that did work
      return loaded
    end
  end


  def find_library( lib_name, search_path=DEFAULT_PATHS )
    os = FFI::Platform::OS

    # Remember the paths that we found.
    found = []

    # Remember whether any of the search paths included our OS.
    os_supported = false

    # Find the regexs that matches our OS.
    os_matches = search_path.rules.keys.find_all{ |regex|  regex =~ os }

    os_matches.each do |os_match|
      # If our OS matched, then it's supported.
      os_supported = true 

      # Fetch the paths for the matching OS.
      paths = search_path.rules[os_match]

      # Fill in for [LIB] and expand the paths.
      paths = paths.collect { |path|
        File.expand_path( path.gsub("[LIB]", lib_name) )
      }

      # Delete all the paths that don't exist.
      paths.delete_if { |path| not File.exist?(path) }

      # Add what's left.
      found += paths
    end

    # Drat, not found, maybe because they are using an unsupported OS.
    if found.empty? and not os_supported
      raise( LoadError, "Your OS (#{os}) is not supported yet.\n" +
             "Please report this and help us support more platforms." )
    end

    return found
  end


  def attach_function( methname, arg1, arg2, arg3=nil )

    # To match the normal attach_function's weird syntax.
    # The arguments can be either:
    # 
    # 1. methname, args, retrn_type  (funcname = methname)
    # 2. methname, funcname, args, retrn_type
    # 
    funcname, args, retrn_type = if arg1.kind_of?(Array)
                                    [methname, arg1, arg2]
                                  else
                                    [arg1, arg2, arg3]
                                  end

    unless retrn_type.kind_of? NiceFFI::TypedPointer
      # Normal FFI::Library.attach_function behavior.
      super
    else

      # Create the raw FFI binding, which returns a pointer.
      # We call it __methname because it's not meant to be called
      # by users. We also make it private below.
      # 
      super( "__#{methname}".to_sym, funcname, args, :pointer )


      # CAUTION: Metaclass hackery ahead! Handle with care!

      metaklass = class << self; self; end
      metaklass.instance_eval {

        # Create the nice method, which calls __methname and wraps the
        # return value (a pointer) the appropriate class using
        # TypedPointer#wrap. This is the one that users should call,
        # so we don't prepend the name with _'s.
        # 
        define_method( methname ) do |*args|
          retrn_type.wrap( send("__#{methname}".to_sym, *args) )
        end

        # __methname is private.
        private "__#{methname}".to_sym

      }

    end

  end
end
