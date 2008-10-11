module RelaxDB  

  class Paginator

    def initialize(paginate_params)
      @paginate_params = paginate_params
      @orig_paginate_params = @paginate_params.clone
    end

    def total_doc_count(design_doc, v)
      DesignDocument.get(design_doc).add_map_view(v.reduce_view_name, v.map_function).
        add_reduce_view(v.reduce_view_name, v.reduce_function).save
      
      total_docs = RelaxDB.reduce_result(RelaxDB.view(design_doc, v.reduce_view_name) do |q|
        q.group(true).group_level(0)
        q.startkey(@orig_paginate_params.startkey).endkey(@orig_paginate_params.endkey).descending(@orig_paginate_params.descending)  
      end)      
    end
    
    def add_next_and_prev(design_doc, docs, v, p, view_keys)
      orig_offset = orig_offset(p.order_inverted?, Query.new(design_doc, v.view_name), @orig_paginate_params, v)
      offset = docs.offset
      no_docs = docs.size
      
      total_doc_count = total_doc_count(design_doc, v)      
      
      following_key = view_keys.map { |a| docs.last.send(a) }
      
      next_params = { :startkey => following_key, :descending => @orig_paginate_params.descending }
      next_exists = !p.order_inverted? ? (offset - orig_offset + no_docs < total_doc_count) : true
      
      prev_params = { :startkey => following_key, :descending => !@orig_paginate_params.descending }
      prev_exists = p.order_inverted? ? (offset - orig_offset + no_docs < total_doc_count) : 
        (offset - orig_offset == 0 ? false : true)
      
      docs.meta_class.instance_eval do        
        define_method(:next_params) { next_exists ? next_params : false }
        define_method(:next_query) { next_exists ? "page_params=#{::CGI::escape(next_params.to_json)}" : false }
        
        define_method(:prev_params) { prev_exists ? prev_params : false }
        define_method(:prev_query) { prev_exists ? "page_params=#{::CGI::escape(prev_params.to_json)}" : false }
      end      
    end
    
    def orig_offset(inverted, query, orig_p, v)
      if inverted
        query.startkey(@orig_paginate_params.endkey).descending(!@orig_paginate_params.descending)
      else
        query.startkey(@orig_paginate_params.startkey).descending(@orig_paginate_params.descending)
      end
      query.count(1)
      RelaxDB.retrieve(query.view_path, self, v.view_name, v.map_function).offset
    end
    
  end
  
end
