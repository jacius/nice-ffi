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
# OpaqueStruct supports the same memory autorelease system as
# NiceStruct. Define MyClass.release( pointer ) to call the library
# function to free the struct, and pass an FFI::Pointer to #new. You
# can disable autorelease for an individual instance by providing
# {:autorelease => false} as an option to #new
#
class NiceFFI::OpaqueStruct

  class << self

    # Returns a NiceFFI::TypedPointer instance for this class.
    def typed_pointer
      @typed_pointer or
        (@typed_pointer = NiceFFI::TypedPointer.new(self))
    end


    # Calls the class's release method if it exists. Used for autorelease.
    def _release( pointer )       # :nodoc:
      if( respond_to?(:release) )
        release( pointer )
      end
    end

  end


  # Create a new instance of the class, wrapping (not copying!) a
  # FFI::Pointer. You can pass another instance of this class to
  # create a new instance wrapping the same pointer.
  # 
  # If val is an instance of FFI::Pointer and you have defined
  # MyClass.release, the pointer will be passed to MyClass.release 
  # when the instance is garbage collected. Use MyClass.release to
  # free the memory for the struct, as appropriate for your class.
  # To disable autorelease for this instance, set {:autorelease => false}
  # in +options+.
  # 
  # (Note: FFI::MemoryPointer and FFI::Buffer have built-in memory
  # management, so MyClass.release is never called for them.)
  # 
  def initialize( val, options={} )
    options = {:autorelease => true}.merge!( options )

    case val

    when self.class
      @pointer = initialize( val.pointer, options )

    when FFI::AutoPointer
      @pointer = val

    when FFI::NullPointer
      @pointer = val

    when FFI::Pointer
      if( val.instance_of? FFI::Pointer ) # not MemoryPointer or Buffer
        if( self.class.respond_to?(:release) and options[:autorelease] )
          # Wrap in an AutoPointer to call self.class._release when it's GC'd.
          @pointer = FFI::AutoPointer.new( val, self.class.method(:_release) )
        else
          @pointer = val
        end
      else
        raise TypeError, "unsupported pointer type #{val.class.name}"
      end


    else
      raise TypeError, "cannot create new #{self.class} from #{val.inspect}"

    end
  end


  attr_reader :pointer

  def to_ptr
    @pointer
  end


  def to_s
    "#<%s:%#.x>"%[self.class.name, self.object_id]
  end

  alias :inspect :to_s

end
