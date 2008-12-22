require 'optparse'

module UBSafe
  
  class Config
    
    attr_reader :options
    
    class << self

      ##
      # Get configuration values
      #
      # @param [Array] args Command-line arguments
      # @return [UBSafe::Config] Singleton instance of UBSafe::Config
      #
      def config(args = nil)
        @@config_instance = UBSafe::Config.new(args) unless defined?(@@config_instance)
        return @@config_instance
      end
      
    end
    
    ##
    # Create a new Config instance
    #
    # @param [Array] args Command-line arguments
    # @return [UBSafe::Config] Instance of UBSafe::Config
    #
    def initialize(args = nil)
      @config_values = {}
      @initial_args = args
      @options = parse_args(args)
    end
    
    private
    
    ##
    # Parse command-line arguments
    #
    # @param [Array] args Command-line arguments
    # @return [Hash] Parsed options. :remainder contains any options not part
    #
    def parse_args(args = nil)
      parsed_options = {}
      if args and args.kind_of?(Array)
        options = OptionParser.new
        options.on("-c","--config CONFIG_FILE", String) {|val| parsed_options[:config_file] = val}
        parsed_options[:remainder] = options.parse(*args)
      end
      return parsed_options
    end
      
  end
  
end
