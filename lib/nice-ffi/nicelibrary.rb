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


# A module to be used in place of FFI::Library. It acts mostly
# like FFI::Library, but with some nice extra features and
# conveniences to make life easier:
# 
# * attach_function accepts TypedPointers as return type,
#   in which case it wraps the return value of the bound function
#   in the TypedPointer's type.
# 
module NiceLibrary

  def self.extend_object( klass )
    klass.extend FFI::Library
    super
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

    unless retrn_type.kind_of? TypedPointer
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
