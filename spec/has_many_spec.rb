require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe RelaxDB::HasManyProxy do
  
  before(:all) do
    setup_test_db
  end

  describe "has_many" do


    describe "target_class in the generated view" do
      it "should infer the class name from the relationship if not supplied" do
        view = mock(:view).as_null_object
        RelaxDB::ViewCreator.should_receive(:has_n).with(
          "",           # client_class
          :foo_bars,    # relationship          
          "FooBar",     # target_class
          ""            # relationship_to_client
        ).and_return view
        klass = Class.new(RelaxDB::Document) do
          has_many :foo_bars
        end
      end 

      it "should use the class name if supplied" do
        view = mock(:view).as_null_object
        RelaxDB::ViewCreator.should_receive(:has_n).with(
          "",         # client_class
          :foo_bars,  # relationship          
          "Bar",     # target_class
          ""          # relationship_to_client
        ).and_return view
        klass = Class.new(RelaxDB::Document) do
          has_many :foo_bars, :class => "Bar"
        end
      end 
    end    
    
    it "should be considered enumerable" do
      u = User.new.save
      u.items.should be_a_kind_of(Enumerable)
    end
    
    it "should actually be enumerable" do
      u = User.new.save
      u.items << Item.new(:name => "a")
      u.items << Item.new(:name => "b")
      names = u.items.inject("") { |memo, i| memo << i.name }
      names.should == "ab"
    end
    
    it "should preserve the collection across the load / save boundary" do
      u = User.new.save
      u.items << Item.new
      u = RelaxDB.load u._id
      u.items.size.should == 1
    end    
    
    it "should work with MultiWordClassNames" do
      c = MultiWordChild.new
      m = MultiWordClass.new.save
      m.multi_word_children << c
      m = RelaxDB.load m._id
      m.multi_word_children[0].should == c
    end    
            
    describe "#<<" do

      it "should link the added item to the parent" do
        u = User.new
        u.items << Item.new
        u.items[0].user.should == u
      end
    
      it "should return self" do
        u = User.new.save
        u.items << Item.new << Item.new
        u.items[0].user.should == u
        u.items[1].user.should == u
      end
      
      it "should not created duplicates when invoked with same object more than once" do
        u = User.new.save
        i = Item.new
        u.items << i << i
        u.items.size.should == 1
      end
      
      it "should return false when the child fails validation" do
        d = Dysfunctional.new
        r = (d.failures << Failure.new)
        r.should be_false
        d.failures.should be_empty
      end
              
    end
    
    describe "#=" do
      
      before(:each) do
        # Create the underlying views
        User.new(:items => [], :invites_received => [], :invites_sent => [])
      end
      
      it "should not attempt to save the child objects when the relationship is established" do
        RelaxDB.db.put_count = 0
        i1, i2 = Item.new(:name => "i1"), Item.new(:name => "i2")
        User.new(:items => [i1, i2])
        RelaxDB.db.put_count.should == 0
      end
      
      it "should preserve given relationships across save/load boundary" do
        i1, i2 = Item.new(:name => "i1"), Item.new(:name => "i2")
        u = User.new(:items => [i1, i2])
        RelaxDB.bulk_save u, *u.items
        u = RelaxDB.load u._id
        u.items.map { |i| i.name }.sort.join.should == "i1i2"
      end
      
      it "should invoke the derived properties writer" do
        RelaxDB.enable_view_creation
        class HmsdParent < RelaxDB::Document
          property :foo, :derived => [:zongs, lambda {|f, o| o.zongs.first.z / 2 }]
          has_many :zongs, :class => "HmsdChild"
        end
        class HmsdChild < RelaxDB::Document
          property :z
          belongs_to :hmsd_parent
        end
        RelaxDB::View.design_doc.save
        
        oz = HmsdChild.new(:z => 10)
        op = HmsdParent.new(:zongs => [oz])
        op.foo.should == 5
      end
      
    end

    describe "#delete" do
    
      it "should nullify the belongs_to relationship" do
        u = User.new.save
        i = Item.new
        u.items << i
        u.items.delete i
        i.user.should be_nil 
        RelaxDB.load(i._id).user.should be_nil
      end
    
    end
    
    describe "#clear" do
    
      it "should result in an empty collection" do
        u = User.new.save
        u.items << Item.new << Item.new
        u.items.clear
        u.items.should be_empty
      end

      it "should nullify all child relationships" do
        u = User.new.save
        i1, i2 = Item.new, Item.new
        u.items << i1
        u.items << i2
        u.items.clear

        i1.user.should be_nil
        i2.user.should be_nil
        RelaxDB.load(i1._id).user.should be_nil
        RelaxDB.load(i2._id).user.should be_nil
      end
    
    end
        
    describe "owner" do
    
      it "should be able to form multiple relationships with the same class of child" do
        u1, u2 = User.new.save, User.new.save
        i = Invite.new(:recipient => u2)
        u1.invites_sent << Invite.new
        RelaxDB.load(u1._id).invites_sent[0] == i
        RelaxDB.load(u2._id).invites_received[0] == i
      end
      
      describe "#destroy" do

        it "should nullify its child relationships" do
          Item.view_docs_by :user_id
          
          u = User.new.save
          u.items << Item.new << Item.new    
          u.destroy!
          Item.by_user_id(:key => u._id).should be_empty
        end

      end  
      
    end
              
  end

end
