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


# TypedPointer represents a :pointer (FFI type) that is a specific
# struct type. You can use TypedPointer( SomeStructClass ) instead
# of :pointer in these situations:
# 
# * As the type for NiceFFI::Struct#layout to create type-smart accessors.
# * As the return type for NiceFFI::Library#attach_function to
#   wrap the returned pointer.
# 
class NiceFFI::TypedPointer

  # Create a new TypedPointer whose type is the given struct class.
  # 
  # type must be a class (not an instance) which is a descendent of
  # FFI::Struct (or is FFI::Struct itself).
  # 
  def initialize( type )
    # unless type.is_a? Class and type.ancestors.include? FFI::Struct
    #   raise TypeError, "#{self.class} only wraps FFI::Struct and subclasses."
    # end
    @type = type
  end

  attr_reader :type


  # Wrap a FFI::Pointer or FFI::MemoryPointer in a new struct of this type.
  def wrap( pointer )
    unless pointer.is_a? FFI::Pointer or pointer.is_a? FFI::MemoryPointer
      raise TypeError, "#{self.class}[ #{@type} ] cannot wrap #{pointer.type}"
    end
    @type.new( pointer )
  end


  # Unwrap (i.e. extract the pointer) from a struct of this type.
  def unwrap( struct )
    unless struct.is_a? @type
      raise TypeError, "#{self.class}[ #{@type} ] cannot unwrap #{struct.type}"
    end
    struct.to_ptr
  end


  def to_s
    "#<#{self.class}[ #{@type} ]>"
  end
  alias :inspect :to_s

end


# Equivalent to TypedPointer.new( type )
def NiceFFI::TypedPointer( type )
  NiceFFI::TypedPointer.new( type )
end
