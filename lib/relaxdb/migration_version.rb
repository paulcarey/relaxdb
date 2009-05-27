class RelaxDB::MigrationVersion < RelaxDB::Document
  
  DOC_ID = "relaxdb_migration_version"
  
  property :version, :default => 0
  
  def self.version
    retrieve.version
  end
      
  def self.update v
    mv = retrieve
    mv.version = v
    mv.save!
  end
    
  def self.retrieve
    (v = RelaxDB.load(DOC_ID)) ? v : new(:_id => DOC_ID).save!
  end
  
end
