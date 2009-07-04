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


  # The default paths to look for libraries. See PathSet 
  # and #load_library.
  # 
  DEFAULT_PATHS = NiceFFI::PathSet.new(

    /linux|bsd/  => [ "/usr/local/lib/lib[NAME].so",
                      "/usr/lib/lib[NAME].so",
                      "[NAME]" ],

    /darwin/     => [ "/usr/local/lib/lib[NAME].dylib",
                      "/sw/lib/lib[NAME].dylib",
                      "/opt/local/lib/lib[NAME].dylib",
                      "~/Library/Frameworks/[NAME].framework/[NAME]",
                      "/Library/Frameworks/[NAME].framework/[NAME]",
                      "[NAME]" ],

    /win32/      => [ "C:\\windows\\system32\\[NAME].dll",
                      "C:\\windows\\system\\[NAME].dll",
                      "[NAME]" ]

  )


  # Try to find and load a library (e.g. "SDL_ttf") into an FFI
  # wrapper module (e.g. SDL::TTF). This method searches in
  # different locations depending on your OS. See PathSet.
  # 
  # Returns the path to the library that was loaded.
  # 
  # Raises LoadError if it could not find or load the library.
  # 
  def load_library( names, search_paths=NiceFFI::Library::DEFAULT_PATHS )

    names = [names] unless names.kind_of? Array

    paths = search_paths.find( *names )

    pretty_names = if names.size == 1
                    names[0]
                  else
                    names[0..-2].join(", ") + ", or " + names[-1]
                  end

    # Oops, couldn't find it anywhere.
    if paths.empty?
      raise LoadError, "Could not find #{pretty_names}. Is it installed?"
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
      raise( LoadError, "Could not load #{pretty_names}." )
    else
      # Return the one that did work
      return loaded
    end
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
