module RelaxDB
  
  class Migration
                
    def self.run klass, limit = 1000
      query = lambda do |page_params|
        RelaxDB.paginate_view "#{klass}_all", :startkey => nil, :endkey => {}, :attributes => [:_id],
          :page_params => page_params, :limit => limit
      end
      
      objs = query.call({})
      until objs.empty?
        migrated = objs.map { |o| yield o }.flatten.reject { |o| o.nil? }
        RelaxDB.bulk_save! *migrated
        objs = objs.next_params ? query.call(objs.next_params) : []
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
