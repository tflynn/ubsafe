
module UBSafe

  module Commands
    
    class << self
      
      ##
      # Run the specified backup
      #
      # @param [Array] args Command-line arguments
      # @return [Integer] Exit code 0 success, 1 otherwise
      #
      def backup(args)
        cmd = UBSafe::Commands::Backup.new(args)
        return cmd.backup
      end

    end

    class Backup
      
      ##
      # Create a new backup instance
      #
      # @param [Array] args Command-line arguments
      #
      def initialize(args)
        @config = UBSafe::Config.config
        config.load(args)
        @backup_name = config.options[:backup_name]
        @backup_options = config.full_options(backup_name)
      end
      
      ##
      # Perform backup
      #
      # @return [Integer] Exit code 0 success, 1 otherwise
      #
      def backup
        # Create backup file in source tree
        # Rotate destination files
        # Copy to destination
        # Remove from source tree
      end
      
      ##
      # Create source backup
      #
      # @return [Symbol] :success or :failure
      def create_source_backup
        
      end
      
    end
    
  end
  
  
end