# Test ground for the README.textile code

require 'rubygems'
require 'relaxdb'

RelaxDB.configure :host => "localhost", :port => 5984
RelaxDB.use_db "relaxdb_spec"

class Writer < RelaxDB::Document
  property :name, :default => "anon"
  
  has_many :posts, :class => "Post"
  has_many :ratings, :class => "Post", :known_as => :critic
end

class Post < RelaxDB::Document
  property :created_at
  property :contents

  belongs_to :writer  
  has_many :ratings, :class => "Rating"
end

class Rating < RelaxDB::Document
  property :thumbs_up, :validator => lambda { |tu| tu >= 0 && tu < 3 }, :validation_msg => "No no"

  belongs_to :post
  belongs_to :critic
end

Writer.all.destroy!
Post.all.destroy!
Rating.all.destroy!

paul = Writer.new(:name => "paul").save

post = Post.new(:contents => "foo")
paul.posts << post                                          # post writer is set and post is saved
post.created_at                                             # right now
paul.ratings << Rating.new(:thumbs_up => 3, :post => post)  # returns false as rating fails validation
paul.ratings.size                                           # 0

# Simple views are auto created
Rating.by_thumbs_up :key => 2, :limit => 1 # query params map directly to CouchDB

view_params = {}
@user = Writer.by_name(:key => "paul").first
u_id = @user._id

@posts = Post.paginate_by(view_params, :writer_id, :created_at) do |p|
  p.startkey([u_id, {}]).endkey([u_id]).descending(true).limit(5)
end
