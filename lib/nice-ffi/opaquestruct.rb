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



# OpaqueStruct represents a Struct with an unknown layout.
# This is meant to be used when the C library designer has
# intentionally hidden the layout (e.g. to prevent user access).
#
# Because the size of an OpaqueStruct is unknown, you should
# only use methods provided by the C library to allocate, modify,
# or free the struct's memory.
#
class NiceFFI::OpaqueStruct < NiceFFI::Struct


  # Create a new instance of the struct, wrapping an FFI::Pointer.
  # You can pass another instance of this class to create a new
  # instance wrapping the same pointer.
  #
  def initialize( val )
    case val
    when FFI::Pointer
      send(:pointer=, val)
    when self.class
      send(:pointer=, val.pointer)
    else
      raise TypeError, "cannot create new #{self.class} from #{val.inspect}"
    end
  end


  # Raises ArgumentError. An OpaqueStruct has no members.
  def []( key )
    raise ArgumentError, "No such field '#{key}'"
  end


  # Raises ArgumentError. An OpaqueStruct has no members.
  def []=( key, value )
    raise ArgumentError, "No such field '#{key}'"
  end


  # Returns []. An OpaqueStruct has no members.
  def members
    []
  end

end
