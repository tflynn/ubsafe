class Integer
  
    def mins
      return self.to_i * 60
    end
    
    alias_method :min, :mins
    
    def hours
      return self.mins * 60
    end
    
    alias_method :hour, :hours
    
    def days
      return self.hours * 24
    end
    
    alias_method :day, :days
    
    def weeks
      return self.days * 7
    end

    alias_method :week, :weeks
    
    def months
      return self.weeks * 30
    end
    
    alias_method :month, :months
    
    def years
      return self.days * 365
    end
    
    alias_method :year, :years
    
end
