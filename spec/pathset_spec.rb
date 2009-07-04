require 'need'
need { File.join("..", "lib", "nice-ffi") }



describe NiceFFI::PathSet do


  describe "by default" do
    
    before :each do
      @pathset = NiceFFI::PathSet.new()
    end

    it "should have no rules" do
      @pathset.rules.should == {}
    end


    ##########
    # APPEND #
    ##########

    describe "appending rules" do
      
      describe "in place" do
        it "should return self" do
          rules = { /a/ => ["b"], /c/ => ["d"] }
          @pathset.append!( rules ).should equal(@pathset)
        end

        it "should add them" do
          rules = { /a/ => ["b"], /c/ => ["d"] }
          @pathset.append!( rules )
          @pathset.rules.should == { /a/ => ["b"], /c/ => ["d"] }
        end
      end


      describe "in a dup" do
        before :each do
          @ps = @pathset.append( /a/ => ["b"], /c/ => ["d"] )
        end

        it "should return a dup" do
          @ps.should_not equal(@pathset)
        end

        it "should add them" do
          @ps.rules.should == { /a/ => ["b"], /c/ => ["d"] }
        end
      end

    end # appending


    ###########
    # PREPEND #
    ###########

    describe "prepending rules" do
      
      describe "in place" do
        it "should return self" do
          rules = { /a/ => ["b"], /c/ => ["d"] }
          @pathset.prepend!( rules ).should equal(@pathset)
        end

        it "should add them" do
          rules = { /a/ => ["b"], /c/ => ["d"] }
          @pathset.prepend!( rules )
          @pathset.rules.should == { /a/ => ["b"], /c/ => ["d"] }
        end
      end


      describe "in a dup" do
        before :each do
          @ps = @pathset.prepend( /a/ => ["b"], /c/ => ["d"] )
        end

        it "should return a dup" do
          @ps.should_not equal(@pathset)
        end

        it "should add them" do
          @ps.rules.should == { /a/ => ["b"], /c/ => ["d"] }
        end
      end

    end # prepending


    ###########
    # REPLACE #
    ###########

    describe "replacing rules" do

      describe "in place" do
        it "should return self" do
          rules = { /a/ => ["e"], /c/ => ["f"] }
          @pathset.replace!( rules ).should equal(@pathset)
        end

        it "should add the new rules" do
          rules = { /a/ => ["e"], /c/ => ["f"] }
          @pathset.replace!( rules )
          @pathset.rules.should == { /a/ => ["e"], /c/ => ["f"] }
        end
      end


      describe "in a dup" do
        before :each do
          @ps = @pathset.replace( /a/ => ["e"], /c/ => ["f"] )
        end

        it "should return a dup" do
          @ps.should_not equal(@pathset)
        end

        it "should add the new rules" do
          @ps.rules.should == { /a/ => ["e"], /c/ => ["f"] }
        end
      end

    end # replacing


    ##########
    # REMOVE #
    ##########

    describe "removing rules" do

      describe "in place" do
        it "should return self" do
          rules = { /a/ => ["b"], /c/ => ["f"] }
          @pathset.remove!( rules ).should equal(@pathset)
        end

        it "should have no effect" do
          rules = { /a/ => ["b"], /c/ => ["f"] }
          @pathset.remove!( rules )
          @pathset.rules.should == {}
        end
      end


      describe "in a dup" do
        before :each do
          @ps = @pathset.remove( /a/ => ["b"], /c/ => ["f"] )
        end

        it "should return a dup" do
          @ps.should_not equal(@pathset)
        end

        it "should have no effect" do
          @ps.rules.should == {}
        end
      end

    end # removing


    ##########
    # DELETE #
    ##########

    describe "deleting" do

      describe "in place" do
        it "should return self" do
          @pathset.delete!( /a/, /b/ ).should equal(@pathset)
        end

        it "should have no effect" do
          @pathset.delete!( /a/, /b/ )
          @pathset.rules.should == {}
        end
      end


      describe "in a dup" do
        before :each do
          @ps = @pathset.delete( /a/, /c/ )
        end

        it "should return a dup" do
          @ps.should_not equal(@pathset)
        end

        it "should have no effect" do
          @ps.rules.should == {}
        end
      end

    end # deleting

  end # by default



  describe "made with rules" do

    before :each do
      @pathset = NiceFFI::PathSet.new( /a/ => ["b"], /c/ => ["d"] )
    end

    it "should have those rules" do
      @pathset.rules.should == { /a/ => ["b"], /c/ => ["d"] }
    end

  end



  describe "with rules" do

    before :each do
      @pathset = NiceFFI::PathSet.new( /a/ => ["b"], /c/ => ["d"] )
    end


    ##########
    # APPEND #
    ##########

    describe "appending rules" do
      
      describe "in place" do
        it "should return self" do
          rules = { /a/ => ["e"], /c/ => ["f"] }
          @pathset.append!( rules ).should equal(@pathset)
        end

        it "should append-merge them" do
          rules = { /a/ => ["e"], /c/ => ["f"] }
          @pathset.append!( rules )
          @pathset.rules.should == { /a/ => ["b", "e"], /c/ => ["d", "f"] }
        end
      end


      describe "in a dup" do
        before :each do
          @ps = @pathset.append( /a/ => ["e"], /c/ => ["f"] )
        end

        it "should return a dup" do
          @ps.should_not equal(@pathset)
        end

        it "should append-merge them" do
          @ps.rules.should == { /a/ => ["b", "e"], /c/ => ["d", "f"] }
        end
      end

    end # appending


    ###########
    # PREPEND #
    ###########

    describe "prepending rules" do
      
      describe "in place" do
        it "should return self" do
          rules = { /a/ => ["e"], /c/ => ["f"] }
          @pathset.prepend!( rules ).should equal(@pathset)
        end

        it "should prepend-merge them" do
          rules = { /a/ => ["e"], /c/ => ["f"] }
          @pathset.prepend!( rules )
          @pathset.rules.should == { /a/ => ["e", "b"], /c/ => ["f", "d"] }
        end
      end


      describe "in a dup" do
        before :each do
          @ps = @pathset.prepend( /a/ => ["e"], /c/ => ["f"] )
        end

        it "should return a dup" do
          @ps.should_not equal(@pathset)
        end

        it "should prepend-merge them" do
          @ps.rules.should == { /a/ => ["e", "b"], /c/ => ["f", "d"] }
        end
      end

    end # prepending


    ###########
    # REPLACE #
    ###########

    describe "replacing rules" do

      describe "in place" do
        it "should return self" do
          rules = { /a/ => ["e"], /c/ => ["f"] }
          @pathset.replace!( rules ).should equal(@pathset)
        end

        it "should replace the old rules" do
          rules = { /a/ => ["e"], /c/ => ["f"] }
          @pathset.replace!( rules )
          @pathset.rules.should == { /a/ => ["e"], /c/ => ["f"] }
        end
      end


      describe "in a dup" do
        before :each do
          @ps = @pathset.replace( /a/ => ["e"], /c/ => ["f"] )
        end

        it "should return a dup" do
          @ps.should_not equal(@pathset)
        end

        it "should replace the old rules" do
          @ps.rules.should == { /a/ => ["e"], /c/ => ["f"] }
        end
      end

    end # replacing


    ##########
    # REMOVE #
    ##########

    describe "removing rules" do

      before :each do
        @pathset = NiceFFI::PathSet.new( /a/ => ["b", "e"],
                                         /c/ => ["d", "f"] )
      end

      describe "in place" do

        it "should return self" do
          rules = { /a/ => ["b"], /c/ => ["f"] }
          @pathset.remove!( rules ).should equal(@pathset)
        end

        it "should remove them" do
          rules = { /a/ => ["b"], /c/ => ["f"] }
          @pathset.remove!( rules )
          @pathset.rules.should == { /a/ => ["e"], /c/ => ["d"] }
        end

        it "should remove the key if no paths are left" do
          @pathset = NiceFFI::PathSet.new( /a/ => ["b"], /c/ => ["d"] )
          rules = { /a/ => ["b"] }
          @pathset.remove!( rules )
          @pathset.rules.should_not have_key(/a/)
        end
      end


      describe "in a dup" do
        before :each do
          @ps = @pathset.remove( /a/ => ["e"], /c/ => ["f"] )
        end

        it "should return a dup" do
          @ps.should_not equal(@pathset)
        end

        it "should remove them" do
          @ps.rules.should == { /a/ => ["b"], /c/ => ["d"] }
        end

        it "should remove the key if no paths are left" do
          @pathset = NiceFFI::PathSet.new( /a/ => ["b"], /c/ => ["d"] )
          @ps = @pathset.remove!( /a/ => ["b"] )
          @ps.rules.should == { /c/ => ["d"] }
        end
      end

    end # removing



    ##########
    # DELETE #
    ##########

    describe "deleting rules" do

      before :each do
        @pathset = NiceFFI::PathSet.new( /a/ => ["b"],
                                         /c/ => ["d"],
                                         /e/ => ["f"])
      end

      describe "in place" do
        it "should return self" do
          @pathset.delete!( /a/, /c/ ).should equal(@pathset)
        end

        it "should remove the keys" do
          @pathset.delete!( /a/, /c/ )
          @pathset.rules.should == { /e/ => ["f"] }
        end
      end


      describe "in a dup" do
        before :each do
          @ps = @pathset.delete( /a/, /c/ )
        end

        it "should return a dup" do
          @ps.should_not equal(@pathset)
        end

        it "should remove the keys" do
          @ps.rules.should == { /e/ => ["f"] }
        end
      end

    end # deleting


  end # with rules

end # NiceFFI::PathSet
