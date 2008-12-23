class Hash
  
  def dup_contents_1_level
    dup = Hash.new
    self.each do |key,val|
      begin
        dup[key] = val.dup
      rescue Exception => ex
        dup[key] = val
      end
    end
    return dup
  end
  
end
