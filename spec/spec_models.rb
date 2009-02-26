#
# RSpec loads this file multiple times, thus breaking invocations like Document.has_one_rels
# The following clause ensures the tests pass, but perhaps Document should raise a warning 
# if it's loaded more than once...
#
# unless @spec_models_loaded

  class Atom < RelaxDB::Document
  end

  class Initiative < RelaxDB::Document
    property :x
    attr_reader :foo
    def initialize(data)
      data[:_id] = data[:x]
      super data
      @foo = :bar
    end
  end

  class Primitives < RelaxDB::Document
  
    property :str
    property :num
    property :true_bool
    property :false_bool
    property :created_at
    property :empty
    
    view_by :num
  
  end

  class BespokeReader < RelaxDB::Document
    property :val
    def val; @val + 5; end
  end

  class BespokeWriter < RelaxDB::Document
    property :val
    def val=(v); @val = v - 10; end
  end

  class Invite < RelaxDB::Document
  
    property :message
  
    belongs_to :sender
    belongs_to :recipient
    
  end

  class Item < RelaxDB::Document
  
    property :name
    belongs_to :user
    
    view_by :user_id
  
  end

  class User < RelaxDB::Document
  
    property :name, :default => "u" 
    property :age
  
    has_many :items, :class => "Item"
  
    has_many :invites_received, :class => "Invite", :known_as => :recipient
    has_many :invites_sent, :class => "Invite", :known_as => :sender
    
    view_by :name, :age
  
  end

  class Post < RelaxDB::Document
  
    property :subject
    property :content
    property :created_at
    property :viewed_at
    
    view_by :content
    view_by :subject
    view_by :viewed_at
  
  end

  class Rating < RelaxDB::Document

    property :stars, :default => 5
    belongs_to :photo
    
    view_by :stars

  end

  class Photo < RelaxDB::Document
  
    property :name
  
    has_one :rating
  
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
  
  class MultiWordClass < RelaxDB::Document
    has_one :multi_word_child
    has_many :multi_word_children, :class => "MultiWordChild"
  end

  class MultiWordChild < RelaxDB::Document
    belongs_to :multi_word_class
  end

  class TwitterUser < RelaxDB::Document
  
    property :name
    references_many :followers, :class => "User", :known_as => :leaders
    references_many :leaders, :class => "User", :known_as => :followers
  
  end

  class Dysfunctional < RelaxDB::Document
    has_one :failure
    has_many :failures, :class => "Failure"
  end

  class Failure < RelaxDB::Document
    property :pathological, :validator => lambda { false }
    belongs_to :dysfunctional
  end
  
  class Letter < RelaxDB::Document
    property :letter
    property :number
    view_by :letter, :number
    view_by :number
  end

  @spec_models_loaded = true

# end
