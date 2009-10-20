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



#--
# Don't scan this module for RDoc/RI.


require 'thread' # for Mutex. JRuby doesn't load this by default.

# A mixin module to provide automatic memory management for C structs.
#
module NiceFFI::AutoRelease

  #  Sets up the class when this module is included. Adds the class
  #  methods and defines class instance variables.
  def self.included( klass )
    class << klass

      # Increment the reference count for this address.
      def _incr_refcount( address )
        @ptr_mutex ||= Mutex.new
        @ptr_mutex.synchronize {
          @ptr_refcounts ||= Hash.new(0)
          @ptr_refcounts[address] += 1
        }
        return nil
      end

      # Decrement the counter for this pointer's address, and free
      # the memory if the reference count falls below 1.
      #
      def _release( pointer )
        @ptr_mutex ||= Mutex.new
        @ptr_mutex.synchronize {
          _decr_refcount(pointer.address)
          if( @ptr_refcounts[pointer.address] < 1 )
            release( pointer )
          end
        }
      end

      private

      # Decrement the reference count for this address. If the count falls
      # below 1, the address is removed from Hash altogether.
      #
      # Note: this method does not have a Mutex lock by itself, but you
      # should use a lock in any methods that call it.
      # 
      def _decr_refcount( address )
        @ptr_refcounts ||= Hash.new(0)
        @ptr_refcounts[address] -= 1
        if( @ptr_refcounts[address] < 1 )
          @ptr_refcounts.delete(address)
        end
      end

    end
  end


  private


  def _make_autopointer( ptr, autorelease=true )
    if( autorelease and
        self.class.respond_to?(:release) and
        ptr.is_a?(FFI::Pointer) and
        not ptr.is_a?(FFI::MemoryPointer) and
        not ptr.is_a?(FFI::Buffer) )

      # Increment the reference count for this pointer address
      self.class._incr_refcount( ptr.address )

      # Wrap in an AutoPointer to call self.class._release when it's GC'd.
      return FFI::AutoPointer.new( ptr, self.class.method(:_release) )

    else
      return ptr
    end
  end


end
