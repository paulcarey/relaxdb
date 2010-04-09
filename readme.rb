# README code is extracted from this file (pagination code excepted).

require 'rubygems'
require 'lib/relaxdb'

RelaxDB.configure :host => "localhost", :port => 5984, :design_doc => "app" #, :logger => Logger.new(STDOUT)
RelaxDB.delete_db "relaxdb_scratch" rescue :ok
RelaxDB.use_db "relaxdb_scratch"
RelaxDB.enable_view_creation # creates views when class definition is executed

class User < RelaxDB::Document
  property :name
end

class Invite < RelaxDB::Document
  
  property :created_at
  
  property :event_name
  
  property :state, :default => "awaiting_response",
    :validator => lambda { |s| %w(accepted rejected awaiting_response).include? s }
  
  references :sender, :validator => :required
  
  references :recipient, :validator => :required
  
  property :sender_name,
   :derived => [:sender, lambda { |p, o| o.sender.name } ]
  
  view_docs_by :sender_name
  view_docs_by :sender_id
  view_docs_by :recipient_id, :created_at, :descending => true
  
  def on_update_conflict
    puts "conflict!"
  end
  
end

# Saving objects

sofa = User.new(:name => "sofa").save!
futon = User.new(:name => "futon").save!

i = Invite.new :sender => sofa, :recipient => futon, :event_name => "CouchCamp"
i.save!

# Loading and querying

il = RelaxDB.load i._id
puts i == il # true

ir = Invite.by_sender_name "sofa"
puts i == ir # true

ix = Invite.by_sender_name(:key => "sofa").first
puts i == ix # true

# Denormalization

puts ix.sender_name # prints sofa, no requests to CouchDB made
puts ix.sender.name # prints sofa, a single CouchDB request made

# Saving with conflicts

idup = i.dup
i.save!
idup.save     # conflict printed

# Saving with and without validations

i = Invite.new :sender => sofa, :event_name => "CouchCamp"

i.save! rescue :ok        # save! throws an exception on validation failure or conflict
i.save                    # returns false rather than throwing an exception
puts i.errors.inspect     # prints {:recipient=>"invalid:"}

i.validation_skip_list << :recipient  # Any and all validations may be skipped
i.save                                # succeeds
