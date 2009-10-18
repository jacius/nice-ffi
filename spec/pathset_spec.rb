require 'spec_helper.rb'


describe NiceFFI::PathSet do


  describe "by default" do
    
    before :each do
      @pathset = NiceFFI::PathSet.new()
    end

    it "should have no paths" do
      @pathset.paths.should == {}
    end


    ##########
    # APPEND #
    ##########

    describe "appending paths" do
      
      describe "in place" do
        it "should return self" do
          paths = { /a/ => ["b"], /c/ => ["d"] }
          @pathset.append!( paths ).should equal(@pathset)
        end

        it "should add them" do
          paths = { /a/ => ["b"], /c/ => ["d"] }
          @pathset.append!( paths )
          @pathset.paths.should == { /a/ => ["b"], /c/ => ["d"] }
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
          @ps.paths.should == { /a/ => ["b"], /c/ => ["d"] }
        end
      end

    end # appending


    ###########
    # PREPEND #
    ###########

    describe "prepending paths" do
      
      describe "in place" do
        it "should return self" do
          paths = { /a/ => ["b"], /c/ => ["d"] }
          @pathset.prepend!( paths ).should equal(@pathset)
        end

        it "should add them" do
          paths = { /a/ => ["b"], /c/ => ["d"] }
          @pathset.prepend!( paths )
          @pathset.paths.should == { /a/ => ["b"], /c/ => ["d"] }
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
          @ps.paths.should == { /a/ => ["b"], /c/ => ["d"] }
        end
      end

    end # prepending


    ###########
    # REPLACE #
    ###########

    describe "replacing paths" do

      describe "in place" do
        it "should return self" do
          paths = { /a/ => ["e"], /c/ => ["f"] }
          @pathset.replace!( paths ).should equal(@pathset)
        end

        it "should add the new paths" do
          paths = { /a/ => ["e"], /c/ => ["f"] }
          @pathset.replace!( paths )
          @pathset.paths.should == { /a/ => ["e"], /c/ => ["f"] }
        end
      end


      describe "in a dup" do
        before :each do
          @ps = @pathset.replace( /a/ => ["e"], /c/ => ["f"] )
        end

        it "should return a dup" do
          @ps.should_not equal(@pathset)
        end

        it "should add the new paths" do
          @ps.paths.should == { /a/ => ["e"], /c/ => ["f"] }
        end
      end

    end # replacing


    ##########
    # REMOVE #
    ##########

    describe "removing paths" do

      describe "in place" do
        it "should return self" do
          paths = { /a/ => ["b"], /c/ => ["f"] }
          @pathset.remove!( paths ).should equal(@pathset)
        end

        it "should have no effect" do
          paths = { /a/ => ["b"], /c/ => ["f"] }
          @pathset.remove!( paths )
          @pathset.paths.should == {}
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
          @ps.paths.should == {}
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
          @pathset.paths.should == {}
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
          @ps.paths.should == {}
        end
      end

    end # deleting

  end # by default



  describe "made with paths" do

    before :each do
      @pathset = NiceFFI::PathSet.new( /a/ => ["b"], /c/ => ["d"] )
    end

    it "should have those paths" do
      @pathset.paths.should == { /a/ => ["b"], /c/ => ["d"] }
    end

  end



  describe "with paths" do

    before :each do
      @pathset = NiceFFI::PathSet.new( /a/ => ["b"], /c/ => ["d"] )
    end


    ##########
    # APPEND #
    ##########

    describe "appending paths" do
      
      describe "in place" do
        it "should return self" do
          paths = { /a/ => ["e"], /c/ => ["f"] }
          @pathset.append!( paths ).should equal(@pathset)
        end

        it "should append-merge them" do
          paths = { /a/ => ["e"], /c/ => ["f"] }
          @pathset.append!( paths )
          @pathset.paths.should == { /a/ => ["b", "e"], /c/ => ["d", "f"] }
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
          @ps.paths.should == { /a/ => ["b", "e"], /c/ => ["d", "f"] }
        end
      end

    end # appending


    ###########
    # PREPEND #
    ###########

    describe "prepending paths" do
      
      describe "in place" do
        it "should return self" do
          paths = { /a/ => ["e"], /c/ => ["f"] }
          @pathset.prepend!( paths ).should equal(@pathset)
        end

        it "should prepend-merge them" do
          paths = { /a/ => ["e"], /c/ => ["f"] }
          @pathset.prepend!( paths )
          @pathset.paths.should == { /a/ => ["e", "b"], /c/ => ["f", "d"] }
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
          @ps.paths.should == { /a/ => ["e", "b"], /c/ => ["f", "d"] }
        end
      end

    end # prepending


    ###########
    # REPLACE #
    ###########

    describe "replacing paths" do

      describe "in place" do
        it "should return self" do
          paths = { /a/ => ["e"], /c/ => ["f"] }
          @pathset.replace!( paths ).should equal(@pathset)
        end

        it "should replace the old paths" do
          paths = { /a/ => ["e"], /c/ => ["f"] }
          @pathset.replace!( paths )
          @pathset.paths.should == { /a/ => ["e"], /c/ => ["f"] }
        end
      end


      describe "in a dup" do
        before :each do
          @ps = @pathset.replace( /a/ => ["e"], /c/ => ["f"] )
        end

        it "should return a dup" do
          @ps.should_not equal(@pathset)
        end

        it "should replace the old paths" do
          @ps.paths.should == { /a/ => ["e"], /c/ => ["f"] }
        end
      end

    end # replacing


    ##########
    # REMOVE #
    ##########

    describe "removing paths" do

      before :each do
        @pathset = NiceFFI::PathSet.new( /a/ => ["b", "e"],
                                         /c/ => ["d", "f"] )
      end

      describe "in place" do

        it "should return self" do
          paths = { /a/ => ["b"], /c/ => ["f"] }
          @pathset.remove!( paths ).should equal(@pathset)
        end

        it "should remove them" do
          paths = { /a/ => ["b"], /c/ => ["f"] }
          @pathset.remove!( paths )
          @pathset.paths.should == { /a/ => ["e"], /c/ => ["d"] }
        end

        it "should remove the key if no paths are left" do
          @pathset = NiceFFI::PathSet.new( /a/ => ["b"], /c/ => ["d"] )
          paths = { /a/ => ["b"] }
          @pathset.remove!( paths )
          @pathset.paths.should_not have_key(/a/)
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
          @ps.paths.should == { /a/ => ["b"], /c/ => ["d"] }
        end

        it "should remove the key if no paths are left" do
          @pathset = NiceFFI::PathSet.new( /a/ => ["b"], /c/ => ["d"] )
          @ps = @pathset.remove!( /a/ => ["b"] )
          @ps.paths.should == { /c/ => ["d"] }
        end
      end

    end # removing



    ##########
    # DELETE #
    ##########

    describe "deleting paths" do

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
          @pathset.paths.should == { /e/ => ["f"] }
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
          @ps.paths.should == { /e/ => ["f"] }
        end
      end

    end # deleting


  end # with paths

end # NiceFFI::PathSet
