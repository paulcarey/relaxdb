class Errors < Hash
  alias_method :on, :[]
  alias_method :count, :size
end

class Time
  
  # Ensure that all Times are stored as UTC
  # Times in the following format may be passed directly to 
  # Date.new in a JavaScript runtime
  def to_json
    utc
    %Q("#{strftime "%Y/%m/%d %H:%M:%S +0000"}")
  end
  
end
