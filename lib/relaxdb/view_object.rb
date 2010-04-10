module RelaxDB

  # An immuntable object typically used to display the results of a view
  class ViewObject
  
    def initialize(hash)
      hash.each do |k, v|

        if k.to_s =~ /_at$/
          v = Time.parse(v).utc rescue v
        end

        instance_variable_set("@#{k}", v)
        meta_class.instance_eval do
          define_method(k.to_sym) do
            instance_variable_get("@#{k}".to_sym)
          end
        end      
      end
    end
  
    def self.create(obj)
      if obj.instance_of? Array
        obj.inject([]) { |arr, o| arr << ViewObject.new(o) }
      elsif obj.instance_of? Hash
        ViewObject.new(obj)
      else
        obj
      end
    end
  
  end

end
