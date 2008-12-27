require 'parsedate'

module UBSafe

  module Commands
    
    class Backup
      
      ##
      # Create a new backup instance
      #
      # @param [Array] args Command-line arguments
      #
      def initialize(args)
        @config = UBSafe::Config.config
        @config.load(args)
        @backup_name = @config.options[:backup_name]
        @backup_options = @config.full_options(@backup_name)
        @log = @config.log
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
        backup_steps = [:before_source_backup,:create_source_backup,:after_source_backup,
          :before_rotate_destination_files, :rotate_destination_files, :after_rotate_destination_files,
          :before_copy_backup, :copy_backup, :after_copy_backup,
          :before_clean_source, :clean_source, :after_clean_source
          ]
        backup_steps.each do |backup_step|
          status = self.send(backup_step)
          if status == :failure
            @log.error("Backup #{@backup_name} backup step #{backup_step.to_s} failed.")
            return 1
          end
        end
        @log.info("Backup  #{@backup_name} succeeded")
        return 0
      end
      
      ##
      # Hook to allow customization before creating source backup
      #
      # @return [Symbol] :success or :failure
      #
      def before_source_backup
        return :success
      end

      ##
      # Hook to allow customization after creating source backup
      #
      # @return [Symbol] :success or :failure
      #
      def after_source_backup
        return :success
      end
      
      ##
      # Create source backup
      #
      # @param [Hash] backup_options
      # @param [String] backup_name
      # @return [Symbol] :success or :failure
      #
      def create_source_backup(backup_options = nil,backup_name = nil)

        backup_options ||= @backup_options
        backup_name ||= @backup_name
        
        # Fully qualify directories
        source_tree = File.expand_path(backup_options[:source_tree])
        tmp_dir = File.expand_path(backup_options[:temporary_directory])
          
        if backup_options[:backup_style] == :tar_gz
          status = nil
          # Run command somewhere sensible
          FileUtils.mkdir_p(tmp_dir)
          Dir.chdir(tmp_dir) do |dir|
            backup_cmd_tempate = "tar cfz %s -C %s ."
            full_cmd = sprintf(backup_cmd_tempate,get_backup_file_name,source_tree)
            @log.debug("create_source_backup #{full_cmd}")
            cmd_result = `#{full_cmd}`
            cmd_status = $?
            status = cmd_status == 0 ? :success : :failure
            if status == :success
              @log.info("Backup '#{backup_name}' succeeded")
            else
              @log.error("Backup '#{backup_name}' failed")
            end
          end
          return status
        end
        @log.error("Backup '#{backup_name}' - backup type specified is not supported")
        return :failure
      end
      
      ##
      # Hook to allow customization before rotating destination files
      #
      # @return [Symbol] :success or :failure
      #
      def before_rotate_destination_files
        return :success
      end

      ##
      # Hook to allow customization after rotating destination files
      #
      # @return [Symbol] :success or :failure
      #
      def after_rotate_destination_files
        return :success
      end
      
      ##
      # Rotate destination files. Check all the conditions
      #
      # @param [Hash] backup_options
      # @param [String] backup_name
      # @return [Symbol] :success or :failure
      #
      def rotate_destination_files(backup_options = nil,backup_name = nil)
        backup_options ||= @backup_options
        backup_name ||= @backup_name
        begin
          # Make sure remote directory exists
          remote_directory = File.join(backup_options[:base_backup_directory],backup_name)
          remote_cmd = "mkdir -p #{remote_directory}"
          cmd_status, cmd_output = ssh_cmd(remote_cmd)
          return :failure unless cmd_status == :success
          
          backup_file_name = get_backup_file_name(backup_options)
          remote_file_name = File.join(remote_directory,backup_file_name)
          remote_file_mtime = get_remote_modified_timestamp(remote_file_name,backup_options,backup_name)
          return_status = nil

          backup_frequency = backup_options[:backup_frequency]
          case backup_frequency
            when Integer
              # Explicit age
              if remote_file_mtime
                if (Time.now.utc - remote_file_mtime ) > backup_frequency
                  return_status = rotate_destination_files_unconditionally(backup_options,backup_name)
                end
              end
            when :daily
              if remote_file_mtime
                now = Time.now.utc
                if (now.day != remote_file_mtime.day) or (now - remote_file_mtime) > 1.day
                  return_status = rotate_destination_files_unconditionally(backup_options,backup_name)
                end
              end
            when :weekly
              if remote_file_mtime
                if (Time.now.utc - remote_file_mtime) > 1.week
                  return_status = rotate_destination_files_unconditionally(backup_options,backup_name)
                end
              end
            when :monthly
              if remote_file_mtime
                now = Time.now.utc
                if (now.month != remote_file_mtime.month) or (now - remote_file_mtime) > 1.month
                  return_status = rotate_destination_files_unconditionally(backup_options,backup_name)
                end
              end
          end
        rescue Exception => ex
          @log.error("Error detected while determining whether to rotate files")
          @log.error(ex.to_s)
          @log.error(ex.backtrace.join("\n"))
          return_status = :failure
        end
        
        return return_status
        
      end
      
      ##
      # Rotate destination files unconditionally. Assume someone else has checked whether this is needed.
      #
      # @param [Hash] backup_options
      # @param [String] backup_name
      # @return [Symbol] :success or :failure
      #
      def rotate_destination_files_unconditionally(backup_options = nil,backup_name = nil)
        # Assume that all checks have been performed before calling this method. 
        # This method will rotate files unconditionally

        backup_options ||= @backup_options
        backup_name ||= @backup_name
        
        return :failure unless backup_options[:backup_file_name_template] =~ /\%n/
        
        remote_directory_name = File.join(backup_options[:base_backup_directory],backup_name)
        remote_cmd = "mkdir -p #{remote_directory_name}"
        cmd_status, cmd_output = ssh_cmd(remote_cmd)
        return :failure unless cmd_status == :success
        remote_cmd = "ls -1t #{remote_directory_name}"
        cmd_status, cmd_output = ssh_cmd(remote_cmd)
        return :failure unless cmd_status == :success
        remote_backup_files = cmd_output.reject {|line| line =~ /^\.$/ or line =~ /^\.\.$/ }
        # Make sure we're initialized
        backup_options[:all_possible_file_names] = all_backup_names(backup_options)
        backups_to_retain = backup_options[:backups_to_retain]
        # If no entries don't rotate
        # If entries > 0 and entries < max, move all files down one position
        # If entries >= max, remove last entry, then move all files down one position
        unless remote_backup_files.empty?
          # if entries >= max, 
          if remote_backup_files.size >= backups_to_retain
            # .. remove last entry
            last_entry = remote_backup_files.pop
            remote_cmd = "rm -f #{File.join(remote_directory_name,last_entry)}"
            cmd_status, cmd_output = ssh_cmd(remote_cmd)
            return :failure unless cmd_status == :success
          end
          # Need to reverse order
          remote_backup_files.size.downto(1) do |current_generation|
            #puts "rotate_destination_files_unconditionally current_generation #{current_generation}"
            file_name_current_generation = remote_backup_files[current_generation - 1]
            #puts "rotate_destination_files_unconditionally file_name_current_generation #{file_name_current_generation}"
            file_name_previous_generation = backup_options[:all_possible_file_names][current_generation]
            #puts "rotate_destination_files_unconditionally file_name_previous_generation #{file_name_previous_generation}"
            remote_cmd = "mv #{File.join(remote_directory_name,file_name_current_generation)} #{File.join(remote_directory_name,file_name_previous_generation)}"
            cmd_status, cmd_output = ssh_cmd(remote_cmd)
            return :failure unless cmd_status == :success
          end
          
        end
          
        return :success

      end

      ##
      # Hook to allow customization before copying backup
      #
      # @return [Symbol] :success or :failure
      #
      def before_copy_backup
        return :success
      end

      ##
      # Hook to allow customization after copying backup
      #
      # @return [Symbol] :success or :failure
      #
      def after_copy_backup
        return :success
      end

      ##
      # Copy backup 
      #
      # @param [Hash] backup_options
      # @param [String] backup_name
      # @return [Symbol] :success or :failure
      #
      def copy_backup(backup_options = nil,backup_name = nil)
        backup_options ||= @backup_options
        backup_name ||= @backup_name
        # Fully qualify directories
        tmp_dir = File.expand_path(backup_options[:temporary_directory])
        backup_file_name = File.join(tmp_dir,get_backup_file_name(backup_options))
        remote_directory_name = File.join(backup_options[:base_backup_directory],backup_name)
        cmd_status, cmd_output = scp_cmd(backup_file_name,remote_directory_name,backup_options,backup_name)
        return :failure unless cmd_status == :success
        return :success
      end

      ##
      # Hook to allow customization before cleaning source
      #
      # @return [Symbol] :success or :failure
      #
      def before_clean_source
        return :success
      end

      ##
      # Hook to allow customization after cleaning source
      #
      # @return [Symbol] :success or :failure
      #
      def after_clean_source
        return :success
      end

      ##
      # Clean Source - remove (temporary) backup files from source
      #
      # @param [Hash] backup_options
      # @param [String] backup_name
      # @return [Symbol] :success or :failure
      #
      def clean_source
        backup_options ||= @backup_options
        backup_name ||= @backup_name
        # Fully qualify directories
        tmp_dir = File.expand_path(backup_options[:temporary_directory])
        backup_file_name = File.join(tmp_dir,get_backup_file_name(backup_options))
        cmd_output = `rm -f #{backup_file_name}`
        cmd_status = $?
        return cmd_status == 0 ? :success : :failure
      end


      
      ##
      # Get backup name - use the template defined in the configuration file
      #
      # @param [Hash] backup_options Backup options
      # @return [String] Unqualified name of backup file
      #
      def get_backup_file_name(backup_options = nil)
        backup_options ||= @backup_options
        return get_backup_file_name_with_generation(backup_options,0)
      end

      ##
      # Get ordered list of all possible backup names given the supplied configuration
      #
      # @param [Hash] backup_options Backup options
      # @return [Array] Ordered list of backup names - newest first
      #
      def all_backup_names(backup_options = nil)
        backup_options ||= @backup_options
        all_possible_file_names = []
        total_possible_file_names = backup_options[:backups_to_retain]
        total_possible_file_names.times do |current_generation|
          all_possible_file_names[current_generation] = get_backup_file_name_with_generation(backup_options,current_generation)
        end
        @backup_options[:all_possible_file_names] = all_possible_file_names
        return all_possible_file_names
      end
      
      ##
      # Get backup name with the specified generation- use the template defined in the configuration file
      #
      # @param [Hash] backup_options Backup options
      # @param [Integer] generation Generation number
      # @return [String] Unqualified name of backup file
      #
      def get_backup_file_name_with_generation(backup_options = nil, generation = 1)
        backup_options ||= @backup_options
        template = backup_options[:backup_file_name_template]
        file_name = backup_options[:backup_name]
        # The new backup is always 1
        file_number = generation
        # Get default time zone
        time_zone = (backup_options[:time_zone] || 'UTC').to_s.upcase
        current_time = time_zone == 'UTC' ? Time.now.utc : Time.now
        time_stamp = current_time.strftime(backup_options[:timestamp_format])
        date_stamp = current_time.strftime(backup_options[:date_format])
        # Translate the template to a sprintf format string
        # %f => file name
        # %n => backup_options[:number_format] for file number
        # %t => backup_options[:timestamp_format]
        # %d => backup_options[:date_format]
        sprintf_template = template.gsub(/\%f/,'%s')
        sprintf_template = sprintf_template.gsub(/\%n/,backup_options[:number_format])
        sprintf_template = sprintf_template.gsub(/\%t/,'%s')
        sprintf_template = sprintf_template.gsub(/\%d/,'%s')
        # Now, figure out the order for the sprintf call
        sprintf_fields = []
        template_size = template.size
        # We're matching a two-character placeholder string, so stop 2 chars from end
        0.upto(template_size - 2) do |pos|
          if template[pos,2] == '%f'
            sprintf_fields << file_name
          elsif template[pos,2] == '%n'
            sprintf_fields << file_number
          elsif template[pos,2] == '%t'
            sprintf_fields << time_stamp
          elsif template[pos,2] == '%d'
            sprintf_fields << date_stamp
          end
        end
        backup_file_name = sprintf(sprintf_template,*sprintf_fields)
        return backup_file_name
      end
      
      ##
      # Get the modified time stamp for a remote file
      #
      # @param [String] file_name Fully qualified file name
      # @param [Hash] backup_options
      # @param [String] backup_name
      # @return [Time] File modification time or nil if no file found remotely
      #
      def get_remote_modified_timestamp(file_name,backup_options = nil,backup_name = nil)
        backup_options ||= @backup_options
        backup_name ||= @backup_name
        remote_cmd = "ubsafe_file_mtime #{file_name}"
        cmd_status, cmd_output = ssh_cmd(remote_cmd,backup_options,backup_name)
        file_mtime = nil
        if cmd_status == :success and (not cmd_output.empty?) and (cmd_output[0] != '')
          #puts "get_remote_modified_timestamp file_name #{file_name} #{cmd_output[0]}"
          file_mtime = Time.utc(*ParseDate.parsedate(cmd_output[0]))
        end
        return file_mtime  
      end
      
      ##
      # Issue an ssh command
      #
      # @param [String] cmd Command to send
      # @param [Hash] backup_options
      # @param [String] backup_name
      # @return [Array] [command status, command output]
      #
      def ssh_cmd(cmd,backup_options = nil,backup_name = nil)
        backup_options ||= @backup_options
        backup_name ||= @backup_name
        ssh_user = backup_options[:user_name]
        ssh_host = backup_options[:hostname]
        ssh_password = backup_options[:password]
        if ssh_password
          # Need to use expect for the password if certs don't work
          cmd_exe = File.expand_path(File.join(::UBSAFE_ROOT, 'bin','ubsafe_ssh_cmd.expect'))
          full_cmd = "#{cmd_exe} #{ssh_user}@#{ssh_host} \"#{ssh_password}\" \"#{cmd}\""
          masked_full_cmd = "#{cmd_exe} #{ssh_user}@#{ssh_host} [PASSWORD] \"#{cmd}\""
        else
          # Certs assumed if no password
          full_cmd = "ssh #{ssh_user}@#{ssh_host} \"#{cmd}\""
          masked_full_cmd = full_cmd
        end
        #puts "About to issue \"#{full_cmd}\""
        cmd_output = `#{full_cmd}`
        cmd_status = $?
        @log.debug("Executed ssh status #{cmd_status} command \"#{masked_full_cmd}\"")
        cmd_output_lines = cmd_output.split("\n").reject {|line| line =~ /spawn/i or line =~ /password/i }
        cmd_output_cleaned = []
        cmd_output_lines.each do |cmd_output_line|
          cmd_output_cleaned << cmd_output_line.strip.chomp
        end
        cmd_status = cmd_status == 0 ? :success : :failure
        return [cmd_status,cmd_output_cleaned]
      end

      ##
      # Issue an scp command
      #
      # @param [String] source_file Fully qualified name of file to send
      # @param [String] destination_dir Destination directory on remote host
      # @param [Hash] backup_options
      # @param [String] backup_name
      # @return [Array] [command status, command output]
      #
      def scp_cmd(source_file,destination_dir,backup_options = nil,backup_name = nil)
        backup_options ||= @backup_options
        backup_name ||= @backup_name
        ssh_user = backup_options[:user_name]
        ssh_host = backup_options[:hostname]
        ssh_password = backup_options[:password]
        if ssh_password
          # Need to use expect for the password if certs don't work
          cmd_exe = File.expand_path(File.join(::UBSAFE_ROOT, 'bin','ubsafe_scp_cmd.expect'))
          full_cmd = "#{cmd_exe} #{ssh_user}@#{ssh_host} \"#{ssh_password}\" #{source_file} #{destination_dir}"
          masked_full_cmd = "#{cmd_exe} #{ssh_user}@#{ssh_host} [PASSWORD] #{source_file} #{destination_dir}"
        else
          # Certs assumed if no password
          full_cmd = "scp #{ssh_user}@#{ssh_host} #{source_file} #{destination_dir}"
          masked_full_cmd = full_cmd
        end
        #puts "About to issue \"#{full_cmd}\""
        cmd_output = `#{full_cmd}`
        cmd_status = $?
        @log.debug("Executed scp status #{cmd_status} command \"#{masked_full_cmd}\"")
        cmd_output_lines = cmd_output.split("\n").reject {|line| line =~ /spawn/i or line =~ /password/i }
        cmd_output_cleaned = []
        cmd_output_lines.each do |cmd_output_line|
          cmd_output_cleaned << cmd_output_line.strip.chomp
        end
        cmd_status = cmd_status == 0 ? :success : :failure
        return [cmd_status,cmd_output_cleaned]
      end
      
    end
    
  end
  
  
end
