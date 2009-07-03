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


# PathSet represents a set of searchpaths for multiple operating systems.
class NiceFFI::PathSet


  def initialize( rules={} )
    @rules = rules
  end
  
  attr_reader :rules

  def dup
    self.class.new( @rules.dup )
  end


  def append!( *ruleses )
    ruleses.each do |rules|
      _modify( rules ) { |a,b|  a + b }
    end
    self
  end

  def append( *ruleses )
    self.dup.append!( *ruleses )
  end

  alias :+ :append



  def prepend!( *ruleses )
    ruleses.each do |rules|
      _modify( rules ) { |a,b|  b + a }
    end
    self
  end

  def prepend( *ruleses )
    self.dup.prepend!( *ruleses )
  end



  def replace!( *ruleses )
    ruleses.each do |rules|
      _modify( rules ) { |a,b|  b }
    end
    self
  end

  def replace( *ruleses )
    self.dup.replace!( *ruleses )
  end



  def remove!( *ruleses )
    ruleses.each do |rules|
      _modify( rules ) { |a,b|  a - b }
    end
    self
  end

  def remove( *ruleses )
    self.dup.remove!( *ruleses )
  end

  alias :- :remove



  def clear!( *regexs )
    @rules.delete_if { |regex, paths|  regexs.include? regex }
    self
  end

  def clear( *regexs )
    self.dup.clear!( *regexs )
  end



  private


  def _modify( rules, &block )  # :nodoc:
    raise "No block given!" unless block_given?

    case rules
    when self.class
      _modify( rules.rules, &block )
    when Hash
      rules.each do |regex, paths|
        _apply_modifier( regex, (@rules[regex] or []), paths, &block )
      end
    when Array
      @rules.each { |regex, paths|
        _apply_modifier( regex, paths, rules, &block )
      }
    end
  end


  def _apply_modifier( regex, a, b, &block ) # :nodoc:
    raise "No block given!" unless block_given?

    result = yield( a, b )

    if result == []
      @rules.delete( regex )
    else
      @rules[regex] = result
    end
  end

end
