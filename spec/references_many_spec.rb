require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe RelaxDB::ReferencesManyProxy do

  before(:all) do
    RelaxDB.configure(:host => "localhost", :port => 5984)  
  end

  before(:each) do
    RelaxDB.delete_db "relaxdb_spec_db" rescue "ok"
    RelaxDB.use_db "relaxdb_spec_db"
  end

  describe "references_many" do
        
    it "should preserve the relationships across the save / load boundary" do
      p = Photo.new
      t = Tag.new
      t.photos << p
    
      p = RelaxDB.load p._id
      p.tags.size.should == 1
      p.tags[0].should == t

      t = RelaxDB.load t._id
      t.photos.size.should == 1
      t.photos[0].should == p
    end
  
    describe "#=" do
      it "should not be invoked" do
      end
    end
      
    describe "#<<" do
      
      it "should set the relationship on both sides" do
        p = Photo.new(:name => "photo")
        t = Tag.new(:name => "tag")
        p.tags << t
    
        p.tags.size.should == 1
        p.tags[0].name.should == "tag"
    
        t.photos.size.should == 1
        t.photos[0].name.should == "photo"
      end
      
      it "should not create duplicates when the same object is added more than once" do
        p = Photo.new
        t = Tag.new
        p.tags << t << t
        p.tags.size.should == 1
      end      
      
      it "should not create duplicates when reciprocal objects are added from opposite sides" do
        p = Photo.new
        t = Tag.new
        p.tags << t
        t.photos << p
        p.tags.size.should == 1
        t.photos.size.should == 1
      end

    end

    describe "#delete" do

      it "should nullify relationship on both sides" do
        p = Photo.new
        t = Tag.new
        p.tags << t

        p.tags.delete(t)
        p.tags.should be_empty
        t.photos.should be_empty
      end
      
    end
    
    describe "owner#destroy" do
      
      it "will not remove its membership from its peers in memory" do
        # Documentating behaviour, not stating that this behaviour is desired
        p = Photo.new
        t = Tag.new
        p.tags << t

        p.destroy!
        t.photos.size.should == 1
      end

      it "should remove its membership from its peers in CouchDB" do
        p = Photo.new
        t = Tag.new
        p.tags << t

        p.destroy!
        RelaxDB.load(t._id).photos.should be_empty
      end
      
    end  
    
    # Leaving this test as a reminder of problems with all.destroy and a self referential 
    # references_many until references_many is removed
    #
    # This test more complex than it needs to be to prove the point
    # It also serves as a proof of a self referential references_many, but there are better places for that
    # it "all.destroy should play nice with self referential references_many" do
    #   u1 = TwitterUser.new(:name => "u1")
    #   u2 = TwitterUser.new(:name => "u2")
    #   u3 = TwitterUser.new(:name => "u3")
    #   
    #   u1.followers << u2
    #   u1.followers << u3
    #   u3.leaders << u2
    #   
    #   u1f = u1.followers.map { |u| u.name }
    #   u1f.sort.should == ["u2", "u3"]
    #   u1.leaders.should be_empty
    #   
    #   u2.leaders.size.should == 1
    #   u2.leaders[0].name.should == "u1"
    #   u2.followers.size.should == 1
    #   u2.followers[0].name.should == "u3"
    #   
    #   u3l = u3.leaders.map { |u| u.name }
    #   u3l.sort.should == ["u1", "u2"]
    #   u3.followers.should be_empty
    #   
    #   TwitterUser.all.destroy!
    #   TwitterUser.all.should be_empty
    # end
          
  end

end
