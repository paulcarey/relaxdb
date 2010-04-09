module RelaxDB
  
  class ViewByDelegator < DelegateClass(Array)
    
    def load!
      RelaxDB.load! self.to_a
    end
            
  end
  
end
