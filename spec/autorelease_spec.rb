require 'need'
need { File.join("..", "lib", "nice-ffi") }


# NOTE: When using $open_pointers, always use different pointer
# addresses than any other specs have used! Otherwise, a pointer from
# a previous spec might release itself during the current spec, and
# you may get wrong results.


$open_pointers = []


def do_gc
  if RUBY_PLATFORM =~ /java/
    java.lang.System.gc
  else
    GC.start
  end
end


class AutoReleaseThing
  include NiceFFI::AutoRelease

  def self.release( ptr )
    # Remove the pointer address
    $open_pointers -= [ptr.address]
  end

  def initialize( val, autorelease = true )
    @pointer = _make_autopointer( val, autorelease )
  end

  attr_reader :pointer
end


class AutoReleaseDisabled
  include NiceFFI::AutoRelease

  def self.release( ptr )
    # Remove the pointer address
    $open_pointers -= [ptr.address]
  end

  def initialize( val, autorelease = false )
    @pointer = _make_autopointer( val, autorelease )
  end

  attr_reader :pointer
end


class NoReleaseMethod
  include NiceFFI::AutoRelease

  # No self.release method. Autorelease behavior should be disabled.

  def initialize( val, options={:autorelease => true} )
    @pointer = _make_autopointer( val, options[:autorelease] )
  end

  attr_reader :pointer
end




describe NiceFFI::AutoRelease do

  before :each do
    $open_pointers = []
  end


  describe "with autorelease enabled" do
    it "should release pointers when GCed" do
      1.upto(50) do |i|
        $open_pointers << i
        AutoReleaseThing.new( FFI::Pointer.new(i) )
      end

      5.times{  do_gc;  sleep 0.05  }

      # Almost all of them should have been garbage collected by now
      $open_pointers.should have_at_most(3).items
    end


    it "should not release pointers with other references" do
      remembered_things = []
      101.upto(120) do |i|
        remembered_things << AutoReleaseThing.new( FFI::Pointer.new(i) )
      end

      101.upto(150) do |i|
        $open_pointers << i
        AutoReleaseThing.new( FFI::Pointer.new(i) )
      end

      5.times{  do_gc;  sleep 0.05  }

      remembered_things.each do |thing|
        $open_pointers.should include( thing.pointer.address )
      end

      # Almost all of the rest should have been garbage collected by now
      $open_pointers.should have_at_most(23).items
    end


    it "should wrap the pointer in an AutoPointer" do
      ptr = FFI::Pointer.new(1)
      thing = AutoReleaseThing.new( ptr )
      thing.pointer.should be_kind_of( FFI::AutoPointer )
      thing.pointer.address.should == ptr.address
    end
  end



  describe "with no self.release method" do
    it "should not release pointers when GCed" do
      NoReleaseMethod.should_not_receive :_release

      1001.upto(1050) do |i|
        NoReleaseMethod.new( FFI::Pointer.new(i) )
      end

      5.times{  do_gc;  sleep 0.05  }
    end


    it "should use the pointer as given" do
      ptr = FFI::Pointer.new(1)
      thing = NoReleaseMethod.new( ptr )
      thing.pointer.should equal(ptr)
    end
  end



  describe "with autorelease disabled" do
    it "should not release pointers when GCed" do
      AutoReleaseDisabled.should_not_receive :_release
      AutoReleaseDisabled.should_not_receive :release

      2001.upto(2050) do |i|
        AutoReleaseDisabled.new( FFI::Pointer.new(i) )
      end

      5.times{  do_gc;  sleep 0.05  }
    end


    it "should use the pointer as given" do
      ptr = FFI::Pointer.new(1)
      thing = AutoReleaseDisabled.new( ptr )
      thing.pointer.should equal(ptr)
    end
  end

end
