class Errors < Hash
  alias_method :on, :[]
  alias_method :count, :size

  def full_messages
    full_messages = []
    each_key do |attr|
      full_messages << attr.to_s + ": " + self[attr]
    end
    full_messages
  end
end

class Time

  # Ensure that all Times are stored as UTC
  # Times in the following format may be passed directly to
  # Date.new in a JavaScript runtime
  def to_json(*args)
    utc
    %Q("#{strftime "%Y/%m/%d %H:%M:%S +0000"}")
  end

end

class Hash
  def to_obj
    RelaxDB.create_obj_from_doc(self)
  end
end