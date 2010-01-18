require 'spec_helper.rb'


class OpaqueThing < NiceFFI::OpaqueStruct
  def self.release( ptr )
  end
end


describe NiceFFI::OpaqueStruct do

  it "should include AutoRelease module" do
    mods = NiceFFI::OpaqueStruct.included_modules
    mods.should include(NiceFFI::AutoRelease)
  end



  it "should accept an AutoPointer" do
    ptr = FFI::AutoPointer.new( FFI::Pointer.new(1), proc{} )
    lambda{ OpaqueThing.new( ptr ) }.should_not raise_error
  end

  it "should use the given AutoPointer" do
    ptr = FFI::AutoPointer.new( FFI::Pointer.new(1), proc{} )
    op = OpaqueThing.new( ptr )
    op.pointer.should equal( ptr )
  end



  it "should accept a null pointer" do
    ptr = FFI::Pointer.new(0)
    lambda{ OpaqueThing.new( ptr ) }.should_not raise_error
  end

  it "should use the given null pointer" do
    ptr = FFI::Pointer.new(0)
    op = OpaqueThing.new( ptr )
    op.pointer.should equal( ptr )
  end



  it "should accept a Pointer" do
    ptr = FFI::Pointer.new(1)
    lambda{ OpaqueThing.new( ptr ) }.should_not raise_error
  end

  it "should wrap the given Pointer in an AutoPointer" do
    ptr = FFI::Pointer.new(1)
    op = OpaqueThing.new( ptr )
    op.pointer.should be_instance_of( FFI::AutoPointer )
  end



  it "should accept another OpaqueStruct" do
    op = OpaqueThing.new( FFI::Pointer.new(1) )
    lambda{ OpaqueThing.new( op )  }.should_not raise_error
  end

  it "should use the given OpaqueStruct's pointer" do
    op1 = OpaqueThing.new( FFI::Pointer.new(1) )
    op2 = OpaqueThing.new( op1 )
    op2.pointer.should equal( op1.pointer )
  end



  it "should not accept a MemoryPointer" do
    ptr = FFI::MemoryPointer.new( :int )
    lambda{ OpaqueThing.new( ptr ) }.should raise_error(TypeError)
  end

  it "should not accept a Buffer" do
    ptr = FFI::Buffer.new( :int )
    lambda{ OpaqueThing.new( ptr ) }.should raise_error(TypeError)
  end



  it "should have a pointer reader" do
    op = OpaqueThing.new( FFI::Pointer.new(1) )
    op.should respond_to( :pointer )
  end

  it "pointer should return the pointer" do
    op = OpaqueThing.new( FFI::Pointer.new(1) )
    op.to_ptr.should be_kind_of( FFI::AutoPointer )
  end



  it "should have a to_ptr method" do
    op = OpaqueThing.new( FFI::Pointer.new(1) )
    op.should respond_to( :to_ptr )
  end

  it "to_ptr should return the pointer" do
    op = OpaqueThing.new( FFI::Pointer.new(1) )
    op.to_ptr.should be_kind_of( FFI::AutoPointer )
  end



  it "should have typed_pointer" do
    OpaqueThing.should respond_to( :typed_pointer )
  end

  it "typed_pointer should give a TypedPointer" do
    tp = OpaqueThing.typed_pointer
    tp.should be_instance_of( NiceFFI::TypedPointer )
  end

  it "the typed_pointer should have the right type" do
    tp = OpaqueThing.typed_pointer
    tp.type.should == OpaqueThing
  end

end
