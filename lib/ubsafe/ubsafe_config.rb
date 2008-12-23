require 'optparse'
require 'yaml'
require 'erb'

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
      
      ## Get logger
      #
      # @return [Logging::Logger] Common logger instance
      #
      def log
        return defined?(@@logger) ? @@logger : nil
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
      #configure_logging
    end

    ## 
    # Get the full set of configuration options for the specified backup
    #
    # @param [Symbol] backup_name
    # @return [Hash] (Flattened?) hash with all the options for this backup. Nil if this backup is not present or enabled.
    #
    def full_options(backup_name)
      backup_options = {}
      # Get backup defaults
      backup_options.merge!(@options[:backup_defaults].dup_contents_1_level)
      # Get the specific backup definition
      backup_options.merge!(@options[:backups][backup_name.to_sym].dup_contents_1_level)
      return nil unless backup_options[:enabled]
      # Expand the backup host reference
      selected_host = backup_options[:backup_host]
      backup_options.merge!(@options[:backup_hosts][selected_host].dup_contents_1_level)
      # Expand the backup type reference
      selected_backup_type = backup_options[:backup_type]
      backup_options.merge!(@options[:backup_types][selected_backup_type].dup_contents_1_level)
      return backup_options
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
        options.on("-n","--name BACKUP_NAME", String, 'Backup Name') {|val| parsed_options[:backup_name] = val.downcase.to_sym}
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
        template = ERB.new(File.open(config_file_name).read)
        contents = YAML.load(template.result)
      rescue Exception => ex
        puts "SEVERE - Unable to load configuration file '#{config_file_name}'"
        # puts ex.to_s
        # puts ex.backtrace.join("\n")
        contents = nil
      end
      return contents
    end
    
    ##
    # Initialize logging
    #
    def configure_logging
      logger_configuration = @options[:logging]
      @@logger = Logging::Logger[logger_configuration[:log_identifier]]
      logger_layout = Logging::Layouts::UBSafeLoggerLayout.new(logger_configuration)
      qualified_logger_file_name = File.expand_path(File.join(logger_configuration[:log_directory],logger_configuration[:log_filename_pattern]))
      @@logger.add_appenders(
          Logging::Appenders::File.new(qualified_logger_file_name, :layout => logger_layout)
      )
      @@logger.level = logger_configuration[:log_level]
    end
    
    # Get the (cached) hostname for this machine
    def hostname
      unless defined?(@@hostname)
        @@hostname = `hostname`.chomp.strip.downcase
      end
      return @@hostname
    end
    
    
  end
  
end
