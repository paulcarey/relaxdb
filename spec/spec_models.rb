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
  
  property :created_at
  
end
