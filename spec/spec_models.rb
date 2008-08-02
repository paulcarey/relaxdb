class Dullard < RelaxDB::Document
end

class Invite < RelaxDB::Document
  
  property :message
  
  belongs_to :sender
  belongs_to :recipient
    
end

class Item < RelaxDB::Document
  
  property :name
  belongs_to :player
  
end

class Rating < RelaxDB::Document
  
  property :shards
  belongs_to :player
  
end

class Player < RelaxDB::Document
  
  property :name 
  property :age
  
  has_one :rating

  has_many :items, :class => "Item"
  
  has_many :invites_received, :class => "Invite", :known_as => :recipient
  has_many :invites_sent, :class => "Invite", :known_as => :sender
  
end

class Post < RelaxDB::Document
  
  property :subject
  property :content
  property :created_at
  property :viewed_at
  
end

class Photo < RelaxDB::Document
  
  property :name
  references_many :tags, :class => "Tag", :known_as => :photos
  
  has_many :taggings, :class => "Tagging"

end

class Tag < RelaxDB::Document
  
  property :name
  references_many :photos, :class => "Photo", :known_as => :tags
  
  has_many :taggings, :class => "Tagging"
  
end

class Tagging < RelaxDB::Document

  belongs_to :photo
  belongs_to :tag
  property :relevance  

end
