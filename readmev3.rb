# Shows most features in single_design_doc branch  - feature readme will be based 
# off of this example

require 'rubygems'
require 'relaxdb'

RelaxDB.configure :host => "localhost", :port => 5984, :design_doc => "app" #, :logger => Logger.new(STDOUT)
RelaxDB.delete_db "relaxdb_scratch" rescue :ok
RelaxDB.use_db "relaxdb_scratch"
RelaxDB.enable_view_creation # creates views when class definition is executed

class Invite < RelaxDB::Document
  
  property :created_at
  
  property :name
  
  property :state, :default => "awaiting_response",
    :validator => lambda { |s| %w(accepted rejected awaiting_response).include? s }
  
  references :sender, :validator => :required
  
  references :recipient, :validator => :required
  
  property :sender_name,
   :derived => [:sender, lambda { |p, o| o.sender.name } ]
  
  view_by :sender_name
  view_by :sender_id
  view_by :recipient_id, :created_at, :descending => true
  
  def on_update_conflict
    puts "conflict!"
  end
  
end

class User < RelaxDB::Document
  property :name
end

stewart = User.new(:name => "stewart").save!
cramer = User.new(:name => "cramer").save!

i = Invite.new :sender => stewart, :recipient => cramer, :name => "daily show"
idup = i.dup

i.save!
idup.save # conflict printed

ir = Invite.by_sender_name "stewart"
puts i == ir # true

ix = Invite.by_sender_name(:key => "stewart").first
puts i == ix # true

puts ix.sender_name # prints stewart, no requests to CouchDB made
puts ix.sender.name # prints stewart, a single CouchDB request made



