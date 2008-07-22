class UuidGenerator
  
  def self.uuid
    # Algorithm with better distribution characteristics suggested :)
    # Might be nice to switch impl at runtime - relationships easier to examine with 4 digit ids
    rand.to_s[2,5]
  end
  
end