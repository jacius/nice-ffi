require 'spec_helper.rb'


class SimpleStruct < NiceFFI::Struct
  layout :a, :uint8, :b, :float
end

class AutoStruct < NiceFFI::Struct
  def self.release( ptr )
  end
  layout :a, :uint8, :b, :float
end

class ReadStruct < NiceFFI::Struct
  layout :x, :uint8, :reader, :uint16
  read_only :reader
end

class HidingStruct < NiceFFI::Struct
  layout :x, :uint8, :hidden, :uint16
  hidden :hidden
end

class ChildStruct < NiceFFI::Struct
  layout( :a, :uint8 )
end

class ParentStruct < NiceFFI::Struct
  layout( :child, ChildStruct.typed_pointer )
end



describe NiceFFI::Struct do

  it "should include AutoRelease module" do
    mods = NiceFFI::Struct.included_modules
    mods.should include(NiceFFI::AutoRelease)
  end


  # TYPED_POINTER

  it "should have typed_pointer" do
    SimpleStruct.should respond_to( :typed_pointer )
  end

  it "typed_pointer should give a TypedPointer" do
    tp = SimpleStruct.typed_pointer
    tp.should be_instance_of( NiceFFI::TypedPointer )
  end

  it "the typed_pointer should have the right type" do
    tp = SimpleStruct.typed_pointer
    tp.type.should == SimpleStruct
  end



  describe ".new" do

    # WITH POINTER

    describe "with a Pointer" do

      it "should not raise error" do
        ptr = FFI::Pointer.new(1)
        lambda{ SimpleStruct.new( ptr ) }.should_not raise_error
      end

      it "should use the given Pointer" do
        ptr = FFI::Pointer.new(1)
        struct = SimpleStruct.new( ptr )
        struct.pointer.should equal( ptr )
      end

      it "should create an AutoPointer if there is a 'release' class method" do
        ptr = FFI::Pointer.new(1)
        struct = AutoStruct.new( ptr )
        struct.pointer.should be_kind_of(FFI::AutoPointer)
      end

      it "should not create an AutoPointer if :autorelease is false" do
        ptr = FFI::Pointer.new(1)
        struct = AutoStruct.new( ptr, :autorelease => false )
        struct.pointer.should equal(ptr)
      end

    end


    # WITH AUTO POINTER

    describe "with an AutoPointer" do

      it "should not raise error" do
        ptr = FFI::AutoPointer.new( FFI::Pointer.new(1), proc{} )
        lambda{ SimpleStruct.new( ptr ) }.should_not raise_error
      end

      it "should use the given AutoPointer" do
        ptr = FFI::AutoPointer.new( FFI::Pointer.new(1), proc{} )
        struct = SimpleStruct.new( ptr )
        struct.pointer.should equal( ptr )
      end

    end


    # WITH BUFFER

    describe "with a Buffer" do

      it "should not raise error" do
        ptr = FFI::Buffer.new( SimpleStruct )
        lambda{ SimpleStruct.new( ptr ) }.should_not raise_error
      end

      it "should use the given Buffer" do
        ptr = FFI::Buffer.new( SimpleStruct )
        struct = SimpleStruct.new( ptr )
        struct.pointer.should equal( ptr )
      end

    end


    # WITH MEMORY POINTER

    describe "with a MemoryPointer" do

      it "should not raise error" do
        ptr = FFI::MemoryPointer.new( SimpleStruct )
        lambda{ SimpleStruct.new( ptr ) }.should_not raise_error
      end

      it "should use the given MemoryPointer" do
        ptr = FFI::MemoryPointer.new( SimpleStruct )
        struct = SimpleStruct.new( ptr )
        struct.pointer.should equal( ptr )
      end

    end


    # WITH NULL POINTER

    describe "with a null Pointer" do

      it "should not raise error" do
        ptr = FFI::Pointer.new(0)
        lambda{  SimpleStruct.new(ptr) }.should_not raise_error
      end

      it "should use the given null pointer" do
        ptr = FFI::Pointer.new(0)
        struct = SimpleStruct.new( ptr )
        struct.pointer.should equal( ptr )
      end

    end


    # WITH ANOTHER STRUCT

    describe "with another Struct" do

      it "should not raise error" do
        struct = SimpleStruct.new( :a => 1, :b => 2.0 )
        lambda{  SimpleStruct.new( struct)  }.should_not raise_error
      end

      it "should use the other Struct's pointer" do
        struct1 = SimpleStruct.new( :a => 1, :b => 2.0 )
        struct2 = SimpleStruct.new( struct1 )
        struct1.pointer.should equal( struct1.pointer )
      end

    end


    # WITH FULL ARRAY

    describe "with a full array" do

      it "should not raise error" do
        lambda{ SimpleStruct.new( [1, 2.0] ) }.should_not raise_error
      end

      it "should create a Buffer" do
        struct = SimpleStruct.new( [1, 2.0] )
        struct.pointer.should be_kind_of(FFI::Buffer)
      end

      it "should set the struct's members from the array" do
        struct = SimpleStruct.new( [1, 2.0] )
        struct[:a].should eql(1)
        struct[:b].should eql(2.0)
      end

    end


    # WITH FULL HASH

    describe "with a full hash" do

      it "should not raise error" do
        lambda{ SimpleStruct.new( :a => 1, :b => 2.0 ) }.should_not raise_error
      end

      it "should create a Buffer" do
        struct = SimpleStruct.new( :a => 1, :b => 2.0 )
        struct.pointer.should be_kind_of(FFI::Buffer)
      end

      it "should set the struct's members from the hash" do
        struct = SimpleStruct.new( :a => 1, :b => 2.0 )
        struct[:a].should eql(1)
        struct[:b].should eql(2.0)
      end

    end


    # WITH BYTESTRING

    describe "with a bytestring" do

      bytestring = SimpleStruct.new(:a => 1, :b => 2.0).
                     pointer.get_bytes(0, SimpleStruct.size)

      it "should not raise error" do
        lambda{ SimpleStruct.new( bytestring ) }.should_not raise_error
      end

      it "should create a Buffer" do
        struct = SimpleStruct.new( bytestring )
        struct.pointer.should be_kind_of(FFI::Buffer)
      end

      it "should initialize the struct from the bytestring" do
        struct = SimpleStruct.new( bytestring )
        struct[:a].should eql(1)
        struct[:b].should eql(2.0)
      end

    end


  end



  # POINTER

  it "should have a pointer reader" do
    buff = FFI::Buffer.new( SimpleStruct.size )
    struct = SimpleStruct.new( buff )
    struct.should respond_to( :pointer )
  end

  it "pointer should return the pointer" do
    buff = FFI::Buffer.new( SimpleStruct.size )
    struct = SimpleStruct.new( buff )
    struct.to_ptr.should equal( buff )
  end


  # TO_PTR

  it "should have a to_ptr method" do
    buff = FFI::Buffer.new( SimpleStruct.size )
    struct = SimpleStruct.new( buff )
    struct.should respond_to( :to_ptr )
  end

  it "to_ptr should return the pointer" do
    buff = FFI::Buffer.new( SimpleStruct.size )
    struct = SimpleStruct.new( buff )
    struct.to_ptr.should equal( buff )
  end



  # MEMBER ACCESSORS

  it "should have readers for all normal members" do
    struct = SimpleStruct.new( :a => 1, :b => 2.0 )
    lambda{ struct.a.should eql(1) }.should_not raise_error
    lambda{ struct.b.should eql(2.0) }.should_not raise_error
  end

  it "should have writers for all normal members" do
    struct = SimpleStruct.new( :a => 1, :b => 2.0 )
    lambda{ struct.a = 2 }.should_not raise_error
    lambda{ struct.b = 3.0 }.should_not raise_error
    struct.a.should eql(2)
    struct.b.should eql(3.0)
  end

  it "should have readers for read-only members" do
    struct = ReadStruct.new( :x => 1, :reader => 2 )
    lambda{ struct.reader.should eql(2) }.should_not raise_error
  end

  it "should not have writers for read-only members" do
    struct = ReadStruct.new( :x => 1, :reader => 2 )
    lambda{ struct.reader = 2 }.should raise_error(NoMethodError)
  end

  it "read-only members should be read_only?" do
    ReadStruct.read_only?(:reader).should be_true
  end

  it "should not have readers for hidden members" do
    struct = HidingStruct.new( :x => 1, :hidden => 2 )
    lambda{ struct.hidden }.should raise_error(NoMethodError)
  end

  it "should not have writers for hidden members" do
    struct = HidingStruct.new( :x => 1, :hidden => 2 )
    lambda{ struct.hidden = 2 }.should raise_error(NoMethodError)
  end

  it "hidden members should be hidden?" do
    HidingStruct.hidden?(:hidden).should be_true
  end



  # TO_ARY

  it "to_ary should return an array of member values in order" do
    struct = SimpleStruct.new( :a => 1, :b => 2.0 )
    struct.to_ary.should eql( [1, 2.0] )
  end

  # TO_HASH

  it "to_ary should return a hash of member names and values" do
    struct = SimpleStruct.new( :a => 1, :b => 2.0 )
    struct.to_hash.should eql( {:a => 1, :b => 2.0} )
  end

  # TO_BYTES

  it "to_bytes should return a bytestring of member values" do
    struct = SimpleStruct.new( :a => 1, :b => 2.0 )
    struct.to_bytes.should == struct.pointer.get_bytes(0, struct.size)
  end



  # NESTED STRUCT

  describe "with a child struct" do

    # Note: must use an actual pointer for these, FFI::Buffer won't
    # work because it has no memory address on JRuby.

    it ".new should accept the child struct as a member" do
      child = ChildStruct.new( FFI::MemoryPointer.new(ChildStruct) )
      lambda{ ParentStruct.new( :child => child ) }.should_not raise_error
    end

    it "should store a pointer to the child struct" do
      child = ChildStruct.new( FFI::MemoryPointer.new(ChildStruct) )
      parent = ParentStruct.new( :child => child )
      parent[:child].should be_kind_of(FFI::Pointer)
      parent[:child].address.should == child.pointer.address
    end

    it "reader should return an instance of the child struct" do
      child = ChildStruct.new( FFI::MemoryPointer.new(ChildStruct) )
      parent = ParentStruct.new( :child => child )
      parent.child.should be_instance_of(ChildStruct)
    end

  end


end
