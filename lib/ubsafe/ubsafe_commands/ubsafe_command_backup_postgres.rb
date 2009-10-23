require 'fileutils'

module UBSafe

  module Commands
    
    class PostgresBackup < UBSafe::Commands::Backup
   
      ##
      # Hook to allow customization before creating source backup
      #
      # @return [Symbol] :success or :failure
      #
      def before_source_backup
        tmp_dir = File.expand_path(@backup_options[:temporary_directory])
        postgres_tmp_dir = File.join(tmp_dir,'postgres')
        FileUtils.mkdir_p(postgres_tmp_dir)
        cmd = "#{@backup_options[:postgres_bin_dir]}/pg_dump -U#{@backup_options[:postgres_username]} -h#{@backup_options[:postgres_host]} -p#{@backup_options[:postgres_port]} #{@backup_options[:postgres_database]} >#{postgres_tmp_dir}/#{@backup_options[:postgres_database]}.sql"
        @log.info("Backup #{@backup_name} \"pg_dump -U#{@backup_options[:postgres_username]} -h#{@backup_options[:postgres_host]} -p#{@backup_options[:postgres_port]} #{@backup_options[:postgres_database]} >#{postgres_tmp_dir}/#{@backup_options[:postgres_database]}.sql\"")
        cmd_output = `#{cmd}`
        cmd_status = $?
        cmd_status = cmd_status == 0 ? :success : :failure
        if cmd_status == :failure
          # cleanup
          cmd_output = `rm -rf #{postgres_tmp_dir}`
          @log.error("Backup #{@backup_name} before_source_backup failed during pg_dump. Output #{cmd_output}")
        end
        # Point source to directory with dump file in it so rest of the world works
        @backup_options[:source_tree] =  postgres_tmp_dir
        return cmd_status
      end
      
      ##
      # Hook to allow customization after cleaning source
      #
      # @return [Symbol] :success or :failure
      #
      def after_clean_source
        tmp_dir = File.expand_path(@backup_options[:temporary_directory])
        postgres_tmp_dir = File.join(tmp_dir,'postgres')
        cmd_output = `rm -rf #{postgres_tmp_dir}`
        cmd_status = $?
        cmd_status == 0 ? :success : :failure
        if cmd_status == :failure
          @log.error("Backup #{@backup_name} after_clean_source failed. Output #{cmd_output}")
        end
        return cmd_status
      end
      
      
    end
    
  end
end
