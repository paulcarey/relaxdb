module RelaxDB
  
  module Validators
   
    def validator_required(att, o)
      !att.blank?
    end
    
  end
  
end