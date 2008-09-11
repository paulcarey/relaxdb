require 'rubygems'
require 'relaxdb'
require 'spec/spec_models'

# Configure RelaxDB
RelaxDB::UuidGenerator.id_length = 5
RelaxDB.configure :host => "localhost", :port => 5984
RelaxDB.delete_db "relaxdb_grapher_demo_db" rescue "ok"
RelaxDB.use_db "relaxdb_grapher_demo_db"

# Create the data
paul = User.new(:name => "paul").save
gromit = User.new(:name => "gromit", :age => 8).save

paul.items << Item.new(:name => "dog brush")
paul.items << Item.new(:name => "futon")

gromit.invites_sent << Invite.new(:message => "sheep herding", :recipient => paul)

# Create the graph
RelaxDB::GraphCreator.create
