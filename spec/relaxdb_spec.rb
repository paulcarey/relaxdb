require File.dirname(__FILE__) + '/spec_helper.rb'
require File.dirname(__FILE__) + '/spec_models.rb'

describe RelaxDB do

  before(:each) do
    RelaxDB.configure(:host => "localhost", :port => 5984, :name => "relaxdb_spec_db")
    begin
      RelaxDB.db.delete
    rescue => e
      puts e
    end
    RelaxDB.db.put
  end
    
  describe "Primitive Attributes" do
    
    it "should throw a warning if a hash passed to the constructor contains an invalid key"
    
    it "should throw warnings if a class defines methods like has_many, properties etc. perhaps also if it redfines an existing method. maybe not. have to assume some intelligence somewhere."
        
    it "object can be saved and resaved" do
      p = Player.new :name => "paul"
      p.save
      p.save
    end

    it "should be a proper CouchDB document even it it specifies no properties" do
      d = Dullard.new
      d.save
      d.save
    end
    
    it "loaded object contains the attributes and values it was saved with" do
      p = Player.new :name => "paul", :age => 1812
      p.save
      p = RelaxDB.load(p._id)
      p.name.should == "paul"
      p.age.should == 1812
    end

    it "loaded object can be resaved" do
      p = Player.new :name => "paul", :shards => 101
      p.save
      p = RelaxDB.load(p._id)
      p.save
    end    

    it "a new object should be assigned an id" do
      p = Player.new
      p._id.should_not == nil
    end
    
    it "an unsaved object's revision should be nil" do
      p = Player.new
      p._rev.should == nil
    end    
    
    it "a saved object's revision should not be nil" do
      p = Player.new.save
      p._rev.should_not == nil
    end
    
    it "nil attributes should not be output in json" do
      Player.new.to_json.should_not include("rev")
    end
    
    it "created_at attribute is set automatically to creation date" do
      now = Time.now
      p = Post.new.save
      created_at = RelaxDB.load(p._id).created_at
      now.should be_close(created_at, 1)
    end
    
    it "created_at is not set on update" do
      back_then = Time.now - 100
      p = Post.new(:created_at => back_then, :_rev => "")
      p.set_created_at_if_new
      p.created_at.should be_close(back_then, 1)
    end
    
    it "attributes that end in _at are converted to dates on object initialisation" do
      now = Time.now
      p = Post.new(:viewed_at => now).save
      p = RelaxDB.load(p._id)
      p.viewed_at.class.should == Time
      p.viewed_at.should be_close(now, 1)
    end  
    
    it "a destroyed object cannot be resaved" do
      p = Photo.new.save
      p.destroy!
      lambda { p.save }.should raise_error
    end
    
    it "invoking destroy on an unsaved object results in undefined behaviour" do
      p = Photo.new
      p.destroy!
      
      d = Dullard.new
      lambda { d.destroy! }.should raise_error
    end
        
  end
  
  # Test organistion and naming is a mess. Revise.
  # Warnings should be provided when name collisions occur between properties and relationships
  describe "has_one and belongs_to" do
    
    describe "both objects created" do
    end
        
    describe "both objects loaded" do
      it "should be able to load the parent and reference itself via the child" do
        p = Player.new.save
        id = p._id
        r = Rating.new(:player => p).save
        p = RelaxDB.load(id)
        p.rating.player._id.should == id
      end
      
    end
        
    describe "parent loaded, child created" do
      it "assigning to a has_one relationship should create a reference from the child to the parent" do
        p = Player.new.save
        r = Rating.new
        p.rating = r
        r.player._id.should == p._id
      end
      
      it "assigning to a has_one relationship should save the assigned object" do
        p = Player.new.save
        r = Rating.new
        p.rating = r
        r._rev.should_not == nil
      end
      
      it "assigning nil to a has_one relationship should set the target to nil" do
        p = Player.new.save
        p.rating = nil
        p.rating.should == nil
      end
      
      it "assigning to a has_one relationship should nullify any existing relationship in the database" do
        p = Player.new.save
        r = Rating.new
        p.rating = r
        p.rating = nil
        r.player.should be_nil
        RelaxDB.load(r._id).player.should be_nil
      end
      
      it "assigning to a has_one relationship will not nullify any unknown in memory object" do
        p = Player.new.save
        r = Rating.new.save
        p.rating = r
        r_copy = RelaxDB.load(r._id)
        p.rating = nil
        r_copy.player.should_not be_nil
      end
      
      it "destroy! should nullify a has_one relationship" do
        p = Player.new.save
        r = Rating.new
        p.rating = r
        p.destroy!
        
        RelaxDB.load(r._id).player.should be_nil
      end
      
      
      it "should provide a warning if constructor hash key name doesn't map to existing property name"
      
      it "should provide a warning if property name or assocations clash"
      
      it "assigning to the parent should cause the parent to be saved"
      # or alternatively the child relationship shouldn't be saved
      # similarly for has_many? yes!
      # >> p = Player.new :name => "Dexter"
      # => #<Player:1724330, _id: 76278, name: Dexter>
      # >> p.rating = Rating.new(:shards => 1001)
      # => #<Rating:1651080, _id: 06704, _rev: 2339049119, shards: 1001, player_id: 76278>
      # >> p
      # => #<Player:1724330, _id: 76278, name: Dexter>      
      
      it "repeated invocations of a has_one relationship should return the same object" do
        p = Player.new.save
        r = Rating.new(:player => p).save
        p = RelaxDB.load(p._id)
        p.rating.object_id.should == p.rating.object_id
      end
      
      it "repeated invocations of a belongs_to relationship should return the same object" do
        p = Player.new.save
        r = Rating.new(:player => p).save
        r = RelaxDB.load(r._id)
        r.player.object_id.should == r.player.object_id
      end
      
      it "assigning to a belongs_to relationship establishes the relationship once the object is saved" do
        p = Player.new.save
        r = Rating.new
        r.player = p
        p.rating.should == nil # I'm not saying this is correct - merely codifying how things stand 
        r.save
        p.rating._id.should == r._id
      end
      
      it "accessing a has_one relationship that hasn't yet been created should return nil" do
        p = Player.new
        p.rating.should == nil
      end
      
      it "accessing a belongs_to relationship that hasn't yet been created should return nil" do
        r = Rating.new
        r.player.should == nil
      end

      it "should be able to load the child and access the parent" do
        p = Player.new.save
        r = Rating.new(:player => p).save
        r = RelaxDB.load r._id
        r.player._id.should == p._id
        
      end
      
      it "should be able to establish a belongs_to relationship via constructor attribute" do
        p = Player.new
        r = Rating.new :player => p
        r.player._id.should == p._id
      end
      
      it "should be able to establish a has_one relationship via a constructor attribute for unsaved" do
        r = Rating.new
        p = Player.new :rating => r
        p.rating.should == r
      end

      it "should be able to establish a has_one relationship via a constructor attribute for saved" do
        r = Rating.new.save
        p = Player.new :rating => r
        p.rating.should == r
      end
      
    end
    
    describe "has_many" do
      
      it "adding an item should link the added item to the parent" do
        p = Player.new
        p.items << Item.new
        p.items[0].player._id.should == p._id
      end
      
      it "creating a object with a has_many relationshps set in the constructor is right out" do
        lambda { Player.new(:items => []) }.should raise_error
      end
      
      it "should resolve a saved collection on access" do
        p = Player.new.save
        p.items << Item.new
        p = RelaxDB.load p._id
        p.items.size.should == 1
      end
      
      it "should return an enumarable collection" do
        p = Player.new.save
        p.items.is_a?(Enumerable).should be_true
      end
      
      it "should actually be enumerable" do
        p = Player.new.save
        p.items << Item.new(:name => "a")
        p.items << Item.new(:name => "b")
        names = p.items.inject("") { |memo, i| memo << i.name }
        names.length.should == 2
      end
      
      it "deleting an object should nullify the belongs_to relationship" do
        p = Player.new.save
        i = Item.new
        p.items << i
        p.items.delete i
        i.player.should be_nil 
        RelaxDB.load(i._id).player.should be_nil
      end
      
      it "clearing a collection should nullify all relationships and result in an empty collection" do
        p = Player.new.save
        i1, i2 = Item.new, Item.new
        p.items << i1
        p.items << i2
        p.items.clear
        i1.player.should be_nil
        i2.player.should be_nil
      end
      
    end
    
    describe "has_many, with extra bells" do
      
      it "adding an invite_received should set the recipient in an invite" do
        p = Player.new.save
        i = Invite.new
        p.invites_received << i
        i.recipient._id.should == p._id
      end
      
      it "removing an invite_received should nullify the recipient in an invite" do
        p = Player.new.save
        i = Invite.new
        p.invites_received << i
        p.invites_received.clear
        i.recipient.should be_nil
        RelaxDB.load(i._id).recipient.should be_nil
      end
      
    end
    
    describe "parent created, child loaded" do
      # should you be able to save the child without the parent - id not_null - depends
    end
    
    describe "common to all object states" do
      # Implicit in tests that pass as the db is deleted after each invocation - would be nice to confirm though
      # it "accessing has_one relationship should create the associated view if it doesn't exist"      
    end
    
    # split via relationship side e.g. belongs_to for saved and unsaved, has_many for saved and unsaved etc.
                
  end

  # Test database API too
  
  describe "destroy" do
    
    it "should nullify its child relationships in has_many" do
      p = Player.new.save
      p.items << Item.new
      p.items << Item.new
      
      p.destroy!
      Item.all_by(:player_id) { |q| q.key = p._id }.should be_empty
    end
    
    it "a destroyed document should not be retrievable" do
      p = Player.new.save
      p.destroy!
      lambda { RelaxDB.load(p._id) }.should raise_error       
    end
    
    it "destroy_all should delete from CouchDB all documents of the corresponding class" do
      p0 = Player.new.save
      p1 = Post.new.save
      p2 = Post.new.save
      Post.destroy_all!
      Post.all.should be_empty
      Player.all.size.should == 1
    end
    
  end
  
  describe "finders" do
    
    it "Document.all should return all instances of that class" do
      Player.new.save
      Post.new.save
      Post.new.save
      Post.all.size.should == 2      
    end
    
    it "Document.all should return an empty array when no instances exist" do
      Post.all.should be_an_instance_of(Array)
      Post.all.should be_empty
    end
    
    it "Document.all should sort ascending by default" do
      Post.new(:content => "a").save
      Post.new(:content => "b").save
      posts = Post.all_by(:content)
      posts[0].content.should == "a"
      posts[1].content.should == "b"
    end

    it "Document.all should sort desc when specified" do
      Post.new(:content => "a").save
      Post.new(:content => "b").save
      posts = Post.all_by(:content) { |q| q.desc = true }
      posts[0].content.should == "b"
      posts[1].content.should == "a"
    end
    
    it "date attributes may be sorted by specifying them lexicographically" do
      t = Time.new
      Post.new(:viewed_at => t, :content => "first").save
      Post.new(:viewed_at => t+1, :content => "second").save
      posts = Post.all_by(:viewed_at) { |q| q.desc = true }
      posts[0].content.should == "second"
      posts[1].content.should == "first"
    end
        
    it "result should be retrievable by exact criteria" do
      Post.new(:subject => "cleantech").save
      Post.new(:subject => "cleantech").save
      Post.new(:subject => "bigpharma").save
      Post.all_by(:subject) { |q| q.key = "cleantech" }.size.should == 2
    end
    
    it "result should be retrievable by relative criteria" do
      Rating.new(:shards => 101).save
      Rating.new(:shards => 150).save
      Rating.all_by(:shards) { |q| q.endkey = 125 }.size.should == 1
    end
    
    it "result should be retrievable by combined criteria" do
      Player.new(:name => "paul", :age => 28).save
      Player.new(:name => "paul", :age => 72).save
      Player.new(:name => "atlas", :age => 99).save
      Player.all_by(:name, :age) { |q| q.startkey = ["paul",0 ]; q.endkey = ["paul", 50] }.size.should == 1
    end

    it "result should be retrievable by combined criteria where not all docs contain all attributes" do
      Player.new(:name => "paul", :age => 28).save
      Player.new(:name => "paul", :age => 72).save
      Player.new(:name => "atlas").save
      Player.all_by(:name, :age) { |q| q.startkey = ["paul",0 ]; q.endkey = ["paul", 50] }.size.should == 1
    end
    
  end
  
  describe "bulk save" do
    
    it "should set the revision of each object saved" do
      t1 = Tag.new(:name => "t1")
      t2 = Tag.new(:name => "t2")
      RelaxDB.bulk_save(t1, t2)
      RelaxDB.bulk_save(t1, t2)
    end
    
    it "a bulk_save of zero documents should succeed" do
      # Simply documenting current behaviour - I don't really care too much if this fails
      # at some point in future
      RelaxDB.bulk_save
    end
    
  end

  describe "query api" do

    it "view name should match a single key attribute" do
      q = RelaxDB::Query.new("", :foo)
      q.view_name.should == "all_by_foo"
    end
    
    it "view name should match key attributes" do
      q = RelaxDB::Query.new("", :foo, :bar)
      q.view_name.should == "all_by_foo_and_bar"
    end
    
    it "view_path with params should be correct" do
      q = RelaxDB::Query.new("Zenith", :mount)
      q.view_path.should == "_view/Zenith/all_by_mount"
    end
    
    it "view_path should contain JSON encoded key if the key has been set" do
      q = RelaxDB::Query.new("Zenith", :mount)
      q.key = "olympus"
      q.view_path.should == "_view/Zenith/all_by_mount?key=\"olympus\""
    end
    
    it "view_path should represent startkey, endkey and count correctly" do
      q = RelaxDB::Query.new("Zenith", :name, :height)
      q.startkey = ["olympus"]
      q.endkey = ["vesuvius", 3600]
      q.count = 100
      q.view_path.should == "_view/Zenith/all_by_name_and_height?startkey=[\"olympus\"]&endkey=[\"vesuvius\",3600]&count=100"
    end
    
    it "if key set to nil - it should work as nil - i.e. be used and not return anything"
    
  end
  
  describe "references many" do
    
    it "creating an object with a references_many relationshps set in the constructor is right out" do
      lambda { Photo.new(:tags => []) }.should raise_error
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
      p.tags.size.should == 0
      t.photos.size.should == 0
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
    
    # Both of these are important - fundamental even to the operation of this library
    # but I've no idea how to *easily* test them
    it "ensure that the entire object graph isn't loaded"
    it "should only issue a single GET"
        
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
    
    it "should retrieve all data with just 3 GETs - keep your eye on the log sunshine :)"
    
  end
      
end
