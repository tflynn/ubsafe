
module Kernel

  # With thanks to the Mack framework
  
  ##
  # Aliases a class method to a new name. It will only do the aliasing once, to prevent
  # issues with reloading a class and causing a StackLevel too deep error.
  # The method takes two arguments, the first is the original name of the method, the second,
  # optional, parameter is the new name of the method. If you don't specify a new method name
  # it will be generated with _original_<original_name>.
  # 
  # Example:
  #   class President
  #     alias_class_method :good
  #     alias_class_method :bad, :old_bad
  #     def self.good
  #       'Bill ' + _original_good
  #     end
  #     def self.bad
  #       "Either #{old_bad}"
  #     end
  #   end
  #
  # @param orig_name [String] The original class method to alias
  # @param new_name [String] The new alias. Defaults to '_ubsafe_original_[name]'
  #
  def alias_class_method(orig_name, new_name = "_ubsafe_original_#{orig_name}")
    eval(%{
      class << self
        alias_method :#{new_name}, :#{orig_name} unless method_defined?("#{new_name}")
      end
    })
  end
  
end

class File
  
  alias_class_method :join
  
  class << self
    
    # With thanks to the Mack framework

    ##
    # Join a list of paths as strings and/or arrays of strings
    #
    # @param args [Array] (Nested) list of paths to join
    # @returns
    # Join now works like it should! It calls .to_s on each of the args
    # pass in. It handles nested Arrays, etc...
    #
    def join(*args)
      fs = [args].flatten
      _ubsafe_original_join(fs.collect{|c| c.to_s})
    end
    
    ##
    # Perform a join relative to the current file. Fully qualify the path name.
    #
    # @param   args [Array] (Nested) list of paths to join
    #
    def join_from_here(*args)
      caller.first.match(/(.+):.+/)
      File.expand_path(File.expand_path(File.join(File.dirname($1), *args)))
    end
    
  end
  
end

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