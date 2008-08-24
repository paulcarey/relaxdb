require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe RelaxDB::HasManyProxy do
  
  before(:all) do
    RelaxDB.configure(:host => "localhost", :port => 5984)  
  end

  before(:each) do
    RelaxDB.delete_db "relaxdb_spec_db" rescue "ok"
    RelaxDB.use_db "relaxdb_spec_db"
  end

  describe "has_many" do
    
    it "should be considered enumerable" do
      u = User.new.save
      u.items.should be_a_kind_of( Enumerable)
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
              
    end
    
    describe "#=" do

      it "should fail" do
        # This may be implemented in future
        lambda { User.new.items = [] }.should raise_error
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
          u = User.new.save
          u.items << Item.new << Item.new    
          u.destroy!
          Item.all.sorted_by(:user_id) { |q| q.key(u._id) }.should be_empty
        end

      end  
      
    end
              
  end

end
