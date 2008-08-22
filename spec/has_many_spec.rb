require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe RelaxDB::HasManyProxy do
  
  before(:all) do
    RelaxDB.configure(:host => "localhost", :port => 5984, :db => "relaxdb_spec_db")  
  end

  before(:each) do
    RelaxDB.db.delete
    RelaxDB.db.put
  end

  describe "has_many" do
    
    it "should be considered enumerable" do
      p = Player.new.save
      p.items.should be_a_kind_of( Enumerable)
    end
    
    it "should actually be enumerable" do
      p = Player.new.save
      p.items << Item.new(:name => "a")
      p.items << Item.new(:name => "b")
      names = p.items.inject("") { |memo, i| memo << i.name }
      names.should == "ab"
    end
    
    it "should preserve the collection across the load / save boundary" do
      p = Player.new.save
      p.items << Item.new
      p = RelaxDB.load p._id
      p.items.size.should == 1
    end    
    
    describe "#<<" do

      it "should link the added item to the parent" do
        p = Player.new
        p.items << Item.new
        p.items[0].player.should == p
      end
    
      it "should return self" do
        p = Player.new.save
        p.items << Item.new << Item.new
        p.items[0].player.should == p
        p.items[1].player.should == p
      end
      
      it "should not created duplicates when invoked with same object more than once" do
        p = Player.new.save
        i = Invite.new
        p.invites_received << i
        p.invites_received << i
        p.invites_received.size.should == 1
      end
              
    end
    
    describe "#=" do

      it "should fail" do
        # This may be implemented in future
        lambda { Player.new.items = [] }.should raise_error
      end
      
    end

    describe "#delete" do
    
      it "should nullify the belongs_to relationship" do
        p = Player.new.save
        i = Item.new
        p.items << i
        p.items.delete i
        i.player.should be_nil 
        RelaxDB.load(i._id).player.should be_nil
      end
    
    end
    
    describe "#clear" do
    
      it "should result in an empty collection" do
        p = Player.new.save
        p.items << Item.new << Item.new
        p.items.clear
        p.items.should be_empty
      end

      it "should nullify all child relationships" do
        p = Player.new.save
        i1, i2 = Item.new, Item.new
        p.items << i1
        p.items << i2
        p.items.clear

        i1.player.should be_nil
        i2.player.should be_nil
        RelaxDB.load(i1._id).player.should be_nil
        RelaxDB.load(i2._id).player.should be_nil
      end
    
    end
    
    describe "owner#destroy" do

      it "should nullify its child relationships" do
        p = Player.new.save
        p.items << Item.new << Item.new    
        p.destroy!
        Item.all_by(:player_id) { |q| q.key(p._id) }.should be_empty
      end

    end  
        
  end

end
