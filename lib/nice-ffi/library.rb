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


# A module to be used in place of FFI::Library. It acts mostly
# like FFI::Library, but with some nice extra features and
# conveniences to make life easier:
# 
# * load_library method to help find and load libraries from common
#   (or custom) places for the current OS. Use it instead of ffi_lib.
# 
# * attach_function accepts TypedPointers as return type,
#   in which case it wraps the return value of the bound function
#   in the TypedPointer's type.
# 
# * Shorthand aliases to improve code readability:
#   * func = attach_function
#   * var  = attach_variable
# 
module NiceFFI::Library

  def self.extend_object( klass )
    klass.extend FFI::Library

    super

    class << klass
      alias :func :attach_function
      alias :var  :attach_variable
    end
  end


  # Try to find and load a library (e.g. "SDL_ttf") into an FFI
  # wrapper module (e.g. SDL::TTF). This method searches in
  # different locations depending on your OS. See PathSet.
  # 
  # Returns the path to the library that was loaded.
  # 
  # Raises LoadError if it could not find or load the library.
  # 
  def load_library( names, search_paths=NiceFFI::PathSet::DEFAULT_PATHS )

    names = [names] unless names.kind_of? Array

    paths = search_paths.find( *names )

    # Try just the plain library name(s), as last resort.
    paths += names

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

    if loaded.nil?
      # Oops, none of them worked.
      pretty_names = if names.size == 1
                       names[0]
                     else
                       names[0..-2].join(", ") + ", or " + names[-1]
                     end

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


  # Calls the given block, but rescues and prints a warning if
  # FFI::NotFoundError is raised. If warn_message is nil, the
  # error message is printed instead.
  # 
  # This is intended to be used around #attach_function for cases
  # where the function may not exist (e.g. because the user has an
  # old version of the library) and the library should continue loading
  # anyway (with the function missing).
  # 
  # 
  # Example:
  # 
  #   module Foo
  #     extend NiceFFI::Library
  #   
  #     load_library( "libfoo" )
  #     
  #     optional( "Warning: Your libfoo doesn't have opt_func()" ) do
  #       attach_function :opt_func, [], :int
  #     end
  #   end
  # 
  def optional( warn_message=nil, &block )
    raise LocalJumpError, "no block given" unless block_given?
    begin
      block.call()
    rescue FFI::NotFoundError => e
      if warn_message
        puts warn_message
      else
        puts "Warning: #{e.message}"
      end
    end
  end


  # Like #attach_function, but wrapped in #optional.
  def optional_function( *args )
    optional {  attach_function( *args )  }
  end

  alias :optfunc :optional_function


end
