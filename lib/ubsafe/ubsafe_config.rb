require 'optparse'
require 'yaml'

module UBSafe
  
  class Config
    
    attr_reader :options
    
    class << self

      ##
      # Get configuration settings
      #
      # @return [UBSafe::Config] Singleton instance of UBSafe::Config
      #
      def config
        @@config_instance = UBSafe::Config.new unless defined?(@@config_instance)
        return @@config_instance
      end
      
    end

    ##
    # Load a Config instance
    #
    # @param [Array] args Command-line arguments
    #
    def load(args = nil)
      @options[:config_file] = ENV['UBSAFE_CONFIG_FILE'] unless ENV['UBSAFE_CONFIG_FILE'].nil?
      # puts "UBConfig.load After env check @options #{@options.inspect}"
      @options.merge!(parse_args(args))
      # puts "UBConfig.load After merge @options #{@options.inspect}"
      if @options[:config_file]
        @options.merge!(load_config_file(@options[:config_file]))
      end
    end

    private
    
    ##
    # Create a new Config instance
    #
    # @return [UBSafe::Config] Instance of UBSafe::Config
    #
    def initialize
      @options = {}
    end

    ##
    # Parse command-line arguments
    #
    # @param [Array] args Command-line arguments
    # @return [Hash] Parsed options. :remainder contains any options not part
    #
    def parse_args(args = nil)
      parsed_options = {:remainder => []}
      if args and args.kind_of?(Array)
        options = OptionParser.new
        options.on("-c","--config CONFIG_FILE", String, "Name of configuration file") {|val| parsed_options[:config_file] = val}
        parsed_options[:remainder] = options.parse(*args)
        parsed_options[:options_help_text] = options.to_s
      end
      return parsed_options
    end
      
    ##
    # Load config file
    #
    # @param [String] config_file_name Configuration file name
    # @return [Object] all the settings in the associated configuration file
    #
    def load_config_file(config_file_name)
      contents = nil
      begin
        contents = YAML.load_file(config_file_name)
      rescue Exception => ex
        puts "SEVERE - Unable to load configuration file '#{config_file_name}'"
        # puts ex.to_s
        # puts ex.backtrace.join("\n")
        contents = nil
      end
      return contents
    end
  end
  
end
