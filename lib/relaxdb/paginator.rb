module RelaxDB  

  class Paginator
    
    attr_reader :paginate_params

    def initialize(paginate_params, page_params)
      @paginate_params = paginate_params
      @orig_paginate_params = @paginate_params.clone
      
      page_params = page_params.is_a?(String) ? JSON.parse(page_params).to_mash : page_params
      # Where the magic happens - the original params are updated with the page specific params
      @paginate_params.update(page_params)
    end

    def total_doc_count(design_doc, view_name)
      result = RelaxDB.view(design_doc, view_name) do |q|
        q.group(true).group_level(0).reduce(true)
        q.startkey(@orig_paginate_params.startkey).endkey(@orig_paginate_params.endkey).descending(@orig_paginate_params.descending)  
      end
      
      total_docs = RelaxDB.reduce_result(result)
    end
    
    def add_next_and_prev(docs, design_doc, view_name, view_keys)
      unless docs.empty?
        no_docs = docs.size
        offset = docs.offset
        orig_offset = orig_offset(design_doc, view_name)
        total_doc_count = total_doc_count(design_doc, view_name)      
      
        next_exists = !@paginate_params.order_inverted? ? (offset - orig_offset + no_docs < total_doc_count) : true
        next_params = create_next(docs.last, view_keys) if next_exists
    
        prev_exists = @paginate_params.order_inverted? ? (offset - orig_offset + no_docs < total_doc_count) : 
          (offset - orig_offset == 0 ? false : true)
        prev_params = create_prev(docs.first, view_keys) if prev_exists
      else
        next_exists = prev_exists = false
      end
      
      docs.meta_class.instance_eval do        
        define_method(:next_params) { next_exists ? next_params : false }
        define_method(:next_query) { next_exists ? "page_params=#{::CGI::escape(next_params.to_json)}" : false }
        
        define_method(:prev_params) { prev_exists ? prev_params : false }
        define_method(:prev_query) { prev_exists ? "page_params=#{::CGI::escape(prev_params.to_json)}" : false }
      end      
    end
    
    def create_next(doc, view_keys)
      next_key = view_keys.map { |a| doc.send(a) }
      next_key = next_key.length == 1 ? next_key[0] : next_key
      next_key_docid = doc._id
      { :startkey => next_key, :startkey_docid => next_key_docid, :descending => @orig_paginate_params.descending }
    end
    
    def create_prev(doc, view_keys)
      prev_key = view_keys.map { |a| doc.send(a) }
      prev_key = prev_key.length == 1 ? prev_key[0] : prev_key
      prev_key_docid = doc._id
      prev_params = { :startkey => prev_key, :startkey_docid => prev_key_docid, :descending => !@orig_paginate_params.descending }
    end
    
    def orig_offset(design_doc, view_name)
      query = Query.new(design_doc, view_name)
      if @paginate_params.order_inverted?
        query.startkey(@orig_paginate_params.endkey).descending(!@orig_paginate_params.descending)
      else
        query.startkey(@orig_paginate_params.startkey).descending(@orig_paginate_params.descending)
      end
      query.reduce(false).count(1)
      RelaxDB.retrieve(query.view_path).offset
    end
    
  end
  
end
