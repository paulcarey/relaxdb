module RelaxDB

  #
  # UUIDs have a significant impact on CouchDB file size and performance
  # See https://issues.apache.org/jira/browse/COUCHDB-465 and
  # http://mail-archives.apache.org/mod_mbox/couchdb-dev/201001.mbox/%3chi57et$19n$1@ger.gmane.org%3e
  #
  # This approach uses the default CouchDB UUID generator (sequential) and 
  # reduces its size by converting to base 36. Converting to base 36 results
  # in a UUID 7 chars shorter than hex.
  #
  # The default size of 200 is arbitrary. Brian Candler's UUID generator in 
  # couchtiny may also be of interest.
  #
  # 
  class UuidGenerator
    
    @uuids = []
    @count = 200
  
    def self.uuid
      unless @length
        uuid = @uuids.pop
        if uuid.nil?
          refill
          uuid = @uuids.pop
        end
        uuid.hex.to_s(36)
      else
        rand.to_s[2, @length]
      end
    end
    
    def self.refill
      resp = RelaxDB.db.uuids(@count)
      @uuids = JSON.parse(resp.body)["uuids"]      
    end
    
    def self.count=(c)
      @count = c
    end
  
    # Convenience that helps relationship debuggging and model exploration
    def self.id_length=(length)
      @length = length
    end
    
    # To be invoked by tests, or clients after temp changes
    def self.reset
      @uuids = []
      @count = 200
      @length = nil
    end
  
  end

end
