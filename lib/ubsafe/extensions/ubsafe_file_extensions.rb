class File
  
  alias_class_method :join
  
  class << self
    
    # With thanks to the Mack framework

    ##
    # Join a list of paths as strings and/or arrays of strings
    #
    # @param args [Array] (Nested) list of paths to join
    # @return Joined list
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
