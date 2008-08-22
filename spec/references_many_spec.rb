require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe RelaxDB do

  before(:each) do
    RelaxDB.configure(:host => "localhost", :port => 5984, :db => "relaxdb_spec_db")
    begin
      RelaxDB.db.delete
    rescue => e
      puts e
    end
    RelaxDB.db.put
  end

  describe "references many" do
  
    it "creating an object with a references_many relationshps set in the constructor is right out" do
      # hmm, not for the moment - its allowed but shouldn't be done
      # lambda { Photo.new(:tags => []) }.should raise_error
    end
      
    it "relationship should be set on both sides" do
      p = Photo.new(:name => "photo")
      t = Tag.new(:name => "tag")
      p.tags << t
    
      p.tags.size.should == 1
      p.tags[0].name.should == "tag"
    
      t.photos.size.should == 1
      t.photos[0].name.should == "photo"
    end


    it "relationship preserved when saved and loaded" do
      p = Photo.new
      t = Tag.new
      t.photos << p
    
      p = RelaxDB.load p._id
      p.tags.size.should == 1
      p.tags[0]._id.should == t._id

      t = RelaxDB.load t._id
      t.photos.size.should == 1
      t.photos[0]._id.should == p._id
    end
  
    it "resolution should happen transparently" do
      p = Photo.new(:name => "photo")
      t = Tag.new(:name => "tag")
      t.photos << p
    
      p = RelaxDB.load p._id
      p.tags[0].name.should == "tag"
    end
  
    it "deletion applied to both sides" do
      p = Photo.new
      t = Tag.new
      p.tags << t

      p.tags.delete(t)
      p.tags.should be_empty
      t.photos.should be_empty
    end
  
    it "a destroyed object does not remove its membership from its peers in memory" do
      # Documentating behaviour, not stating that this behaviour is desired
      p = Photo.new
      t = Tag.new
      p.tags << t
    
      p.destroy!
      t.photos.size.should == 1
    end

    it "an deleted object should remove its membership from its peers in CouchDB" do
      p = Photo.new
      t = Tag.new
      p.tags << t
    
      p.destroy!
      RelaxDB.load(t._id).photos.should be_empty
    end
  
    it "adding the same relationship to a references_many multiple times does not create duplicates" do
      p = Photo.new
      t = Tag.new
      p.tags << t
      p.tags << t
      p.tags.size.should == 1
    end
  
    it "adding the same relationship to a references_many multiple times from different sides does not create duplicates" do
      p = Photo.new
      t = Tag.new
      p.tags << t
      t.photos << p
      p.tags.size.should == 1
      t.photos.size.should == 1
    end
  
    
    # This test more complex than it needs to be to prove the point
    # It also serves as a proof of a self referential references_many, but there are better places for that
    # it "destroy_all should play nice with self referential references_many" do
    #   u1 = User.new(:name => "u1")
    #   u2 = User.new(:name => "u2")
    #   u3 = User.new(:name => "u3")
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
    #   User.destroy_all!
    #   User.all.should be_empty
    # end
    
    # Both of these are important - fundamental even to the operation of this library
    # but I've no idea how to *easily* test them
    it "ensure that the entire object graph isn't loaded"
    it "should only issue a single GET"
      
    it "destroy_all should play nice with references_many" do
      p = Photo.new
      t = Tag.new
      p.tags << t
      
      Photo.destroy_all!
      Tag.destroy_all!
    end
      
  end

  describe "a poor man's has many through" do
  
    # The join relationship I proprose for RelaxDB is like an inverted version of ARs has_many :through
    # In RelaxDB the has_many would refer to the join, and the through to the target of the join
    # This is done so that data can be retrieved with as few GETs as possible - just 3 for a photo, all its tags
    # and all the tag metadata (taggings).
    #
    # For example
    #
    # class Photo < RelaxDB::Document
    #   property :name
    #   references_many :tags, :class => "Tag", :known_as => :photos
    #   has_many :taggings, :through => :tags
    # end
    # class Tag < RelaxDB::Document
    #   property :name
    #   references_many :photos, :class => "Photo", :known_as => :tags
    #   has_many :taggings, :through => :photos
    # end
    #
    # This could be used like the following
    # 
    # mg = Photo.new(:name => "migration").save
    # wb = Tag.new(:name => "wildebeest").save
    # tagging = mg.tags << wb 
    # tagging.foo = bar
    # 
    # However, this is a lot of work and code complexity for relatively little gain so I propose creating the join
    # relationship manually and reevaluating the benefit of automating the tagging later
  
    it "join metadata should be available" do
      mg = Photo.new(:name => "migration").save
      wb = Tag.new(:name => "wildebeest").save
    
      t = Tagging.new(:photo => mg, :tag => wb).save
    
      mg.taggings[0].tag.name.should == "wildebeest"      
    end
  
    it "should retrieve all data with just 3 GETs" do
      mg = Photo.new(:name => "migration").save
      wb = Tag.new(:name => "wildebeest").save
      tz = Tag.new(:name => "tanzania").save
      mg.tags << wb
      mg.tags << tz
    
      Tagging.new(:photo => mg, :tag => wb, :relevance => 5).save
      Tagging.new(:photo => mg, :tag => tz, :relevance => 3).save
    
      # Force view creation for tags and taggings
      mg.tags.resolve
      mg.taggings
    
      # Begin the test
      RelaxDB.db.get_count = 0
      p = RelaxDB.load mg._id
      # Load the tags first
      p.tags.resolve
      data = {}
      p.taggings.each do |t|
        data[t.tag.name] = t.relevance
      end
      data.sort.should == [["tanzania", 3], ["wildebeest", 5]]
    
      # Waiting for the cache!
      # RelaxDB.db.get_count.should == 3
    end
  
    it "should offer an example where behaviour is different with caching enabled and caching disabled"
    # you have been warned!
  
  end

end
