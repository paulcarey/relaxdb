module RelaxDB

  # Represents query parameters made against a view
  # This class performs no error checking 
  # It might be nice to have the writers return self so calls can be chained => q.startkey=(foo).endkey=(bar).count=2
  class Query
  
    # Simple attr_writer might not produce the desired behaviour. For example
    # Player.all_by(:username) { |q| q.key = params[:username] } 
    # would return all players if params[:username] is nil - almost certainly not wanted/expected behaviour
    attr_writer :key, :startkey, :endkey, :count, :desc 
  
    def initialize(design_doc, view_name)
      @design_doc = design_doc
      @view_name = view_name
    end
      
    def view_path
      uri = "_view/#{@design_doc}/#{@view_name}"

      # Scope for factoring this into a loop, but maybe it's as clear like this
      # TODO: CGI escape all key values?
      query = ""
      query << "&key=#{@key.to_json}" if @key
      query << "&startkey=#{@startkey.to_json}" if @startkey
      query << "&endkey=#{@endkey.to_json}" if @endkey
      query << "&count=#{@count.to_json}" if @count
      query << "&descending=true" if @desc
    
      uri << query.sub(/^&/, "?")
    end
      
  end

end
