class ViewCreator

  # I think Merb contains code for dealing smartly with case changing, camel case, donkey case etc.
  
  def initialize
    @map_template = <<-QUERY
    function(doc) {
      if(doc.class == "${target_class}")
        emit(doc.${relationship_to_client}_id, doc);
    }
    QUERY
  end
  
  def create(target_class, relationship_to_client)
    target_class = target_class.to_s.capitalize
    map_function = @map_template.sub("${target_class}", target_class)
    map_function.sub("${relationship_to_client}", relationship_to_client.to_s)
  end
  
  def all_view(target_class)
    map_template = <<-QUERY
    function(doc) {
      if(doc.class == "${target_class}")
        emit(null, doc);
    }
    QUERY
    map_template.sub!("${target_class}", target_class.to_s)
  end
  
  def has_many_through_view(target_class, peers)
    map_template = <<-MAP_FUNC
      function(doc) {
        if(doc.class == "${target_class}" && doc.${peers}) {
          var i;
          for(i = 0; i < doc.${peers}.length; i++) {
            emit(doc.${peers}[i], doc);
          }
        }
      }
    MAP_FUNC
    map_template.sub!("${target_class}", target_class).gsub!("${peers}", peers)
  end
    
end

# TODO: Integrate more closely with RelaxDB::Document - a little too much repitition, I think
class DesignDocument
  
  def initialize(client_class, data)
    @client_class = client_class
    @relationship_to_client = client_class.name.downcase
    @data = data
  end
  
  # Really a relationship_to_parent given the current implementation
  def add_view(view_name, target_class=view_name, relationship_to_client=@relationship_to_client)
    view_creator = ViewCreator.new
    map_function = view_creator.create(target_class, relationship_to_client)
    add_view_to_data(view_name, map_function)
  end
  
  def add_has_many_through_view(view_name, target_class, relationship_to_client)
    view_creator = ViewCreator.new
    map_function = view_creator.has_many_through_view(target_class, relationship_to_client.to_s) # TODO: .to_s - ugh
    add_view_to_data(view_name, map_function)    
  end

  def add_all_view
    map_function = ViewCreator.new.all_view(@client_class)
    add_view_to_data("all", map_function)
  end
  
  def add_view_to_data(view_name, map_function)
    @data["views"] ||= {}
    @data["views"][view_name] ||= {}
    @data["views"][view_name]["map"] = map_function
    self
  end
  
  def save
    database = RelaxDB::Database.std_db    
    resp = database.put("#{@data['_id']}", @data.to_json)
    @data["_rev"] = JSON.parse(resp.body)["rev"]
    self
  end
  
  def self.get(client_class)
    begin
      database = RelaxDB::Database.std_db
      resp = database.get("_design/#{client_class}")
      DesignDocument.new(client_class, JSON.parse(resp.body))
    rescue => e
      DesignDocument.new(client_class, {"_id" => "_design/#{client_class}"} )
    end
  end  
  
end
