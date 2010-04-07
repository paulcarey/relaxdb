module RelaxDB
  
  class Migration
    
    def self.load_batch klass, startkey, limit
      skip = startkey.nil? ? 0 : 1
      result = RelaxDB.rf_view "#{klass}_all", :startkey => startkey, 
        :raw => true, :limit => limit, :skip => skip
      ids = result["rows"].map { |h| h["id"] }
      RelaxDB.load! ids      
    end
                
    def self.run klass, limit = 1000
      objs = load_batch klass, nil, limit
      until objs.empty?
        migrated = objs.map { |o| yield o }.flatten.compact
        RelaxDB.bulk_save! *migrated
        objs = load_batch klass, objs[-1]._id, limit
      end
    end
    
    #
    # Runs all outstanding migrations in a given directory
    #
    # ==== Example
    #   RelaxDB::Migration.run_all Dir["couchdb/migrations/**/*.rb"]
    #
    def self.run_all file_names, action = lambda { |fn| require fn }
      v = RelaxDB::MigrationVersion.version
      file_names.select { |fn| fv(fn) > v }.each do |fn|
        RelaxDB.logger.info "Applying #{fn}"
        action.call fn
        RelaxDB::MigrationVersion.update fv(fn)
      end
    end
    
    def self.fv file_name
      File.basename(file_name).split("_")[0].to_i
    end
    
  end
  
end
