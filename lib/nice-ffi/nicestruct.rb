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


# A class to be used as a baseclass where you would use FFI::Struct.
# It acts mostly like FFI::Struct, but with nice extra features:
# 
# * Automatically defines read and write accessor methods (e.g. #x,
#   #x=) for all struct members when you call #layout.
# 
# * Implements a nicer #new method which allows you to create a new
#   struct and set its data in one shot by passing an Array, Hash, or
#   another instance of the class (to copy data). You can also use it
#   to wrap a FFI::MemoryPointer just like you can with FFI::Struct.
#
# * Implements #to_ary and #to_hash to dump the struct data.
# 
# * Implements #to_s and #inspect for nice debugging output.
# 
class NiceStruct < FFI::Struct

  class << self

    # Same syntax as FFI::Struct#layout, but also defines nice
    # accessors for the attributes.
    # 
    # Example:
    # 
    #   class Rect < NiceStruct
    #     layout( :x, :int16,
    #             :y, :int16,
    #             :w, :uint16,
    #             :h, :uint16 )
    # 
    def layout( *spec )
      # Wrap the members.
      0.step(spec.size - 1, 2) { |index|
        member, type = spec[index, 2]
        wrap_member( member, type)
      }

      # Normal FFI::Struct behavior
      super
    end


    # Mark the given members as hidden, i.e. do not create accessors
    # for them in #layout, and do not print them out in #to_s, etc.
    # 
    # Note: This will remove the accessor methods (if they exist) for
    # the members! So if you're defining your own custom accessors, do
    # that *after* you have called this method.
    # 
    def hidden( *members )
      if defined?(@hidden_members)
        @hidden_members += members
      else
        @hidden_members = members 
      end

      members.each do |member|
        # Remove the accessors if they exist.
        [member, "#{member}=".to_sym].each { |m|
          remove_method( m )
        }
      end
    end


    # True if the member is hidden, false otherwise.
    def hidden?( member )
      return false unless defined?(@hidden_members)
      @hidden_members.include?( member )
    end


    # Mark the given members as read-only, so the won't have write
    # accessors.
    # 
    # Note: This will remove the writer method (if it exists) for
    # the members! So if you're defining your own custom writer, do
    # that *after* you have called this method.
    # 
    def read_only( *members )
      if defined?(@readonly_members)
        @readonly_members += members
      else
        @readonly_members = members 
      end

      members.each do |member|
        # Remove the write accessor if it exists.
        remove_method( "#{member}=".to_sym )
      end
    end

    # True if the member is read-only, false otherwise.
    def read_only?( member )
      return false unless defined?(@readonly_members)
      @readonly_members.include?( member )
    end


    private


    # Defines read and write accessors for the given struct member.
    # This is similar to attr_accessor, except these accessors read
    # and write the struct's members, instead of to instance
    # variables.
    # 
    # E.g. `wrap_member(:x, :int16)` defines #x and #x= read and write
    # to the struct's :x member, which is an int16.
    # 
    # Normally you don't need to call this method, because #layout
    # does this automatically.
    # 
    # Currently this method doesn't do anything with the type parameter,
    # but in the future it might perform some type checks in the write
    # accessor.
    # 
    def wrap_member( member, type )
      @hidden_members = [] unless defined?(@hidden_members)

      unless hidden?( member )
        _make_reader( member, type )
        unless read_only?( member )
          _make_writer( member, type )
        end
      end
    end


    def _make_reader( member, type ) # :nodoc:
      self.class_eval do
        define_method( member ) do
          self[member]
        end
      end
    end


    def _make_writer( member, type ) # :nodoc:
      self.class_eval do
        define_method( "#{member}=".to_sym ) do |val|
          self[member] = val
        end
      end
    end


  end


  # Create a new instance of the class, reading data from a Hash or
  # Array of attributes, copying from another instance of the class,
  # or wrapping (not copying!) a FFI::MemoryPointer.
  # 
  def initialize( val )
    case val

    when Hash
      super()                       # Create empty struct
      init_from_hash( val )         # Read the values from a Hash.

    # Note: plain "Array" would mean FFI::Struct::Array in this scope.
    when ::Array
      super()                       # Create empty struct
      init_from_array( val )        # Read the values from an Array.

    when self.class
      super()                       # Create empty struct
      init_from_array( val.to_ary ) # Read the values from another instance.

    when FFI::Pointer, FFI::MemoryPointer
      # Normal FFI::Struct behavior to wrap the pointer.
      super( val )

    else
      raise TypeError, "cannot create new #{self.class} from #{val.inspect}"

    end
  end


  def init_from_hash( val )   # :nodoc:
    members.each do |member|
      self[ member ] = val[ member ]
    end
  end
  private :init_from_hash


  def init_from_array( val )  # :nodoc:
    members.each_with_index do |member, i|
      self[ member ] = val[ i ]
    end
  end
  private :init_from_array



  # Dump this instance as an Array of its struct data.
  # The array contains only the data, not the member names.
  # 
  # Note: the order of data in the array always matches the
  # order of members given in #layout.
  # 
  # Example:
  # 
  #   Rect.new( :x=>1, :y=>2, :w=>3, :h=>4 ).to_ary
  #   # => [1,2,3,4]
  # 
  def to_ary
    members.collect{ |m| self[m] }
  end

  # Dump this instance as a Hash containing {member => data} pairs
  # for every member in the struct.
  # 
  # Example:
  # 
  #   Rect.new( :x=>1, :y=>2, :w=>3, :h=>4 ).to_ary
  #   # => {:h=>4, :w=>3, :x=>1, :y=>2}
  # 
  def to_hash
    Hash[ *(members.collect{ |m| [m, self[m]] }.flatten!) ]
  end


  def to_s
    mems = members.collect{ |m|
      unless self.class.hidden?( m )
        "@#{m}=#{self.send(m)}"
      end
    }.compact.join(", ")

    return "#<%s:%#.x %s>"%[self.class.name, self.object_id, mems]
  end
  alias :inspect :to_s

end
