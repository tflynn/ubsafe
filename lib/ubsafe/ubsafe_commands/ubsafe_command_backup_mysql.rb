require 'fileutils'

module UBSafe

  module Commands
    
    class MySqlBackup < UBSafe::Commands::Backup
   
      ##
      # Hook to allow customization before creating source backup
      #
      # @return [Symbol] :success or :failure
      #
      def before_source_backup
        tmp_dir = File.expand_path(@backup_options[:temporary_directory])
        mysql_tmp_dir = File.join(tmp_dir,'mysql')
        FileUtils.mkdir_p(mysql_tmp_dir)
        cmd = " mysqldump -u#{@backup_options[:mysql_username]} -p#{@backup_options[:mysql_password]} -h#{@backup_options[:mysql_host]} #{@backup_options[:mysql_database]} >#{mysql_tmp_dir}/#{@backup_options[:mysql_database]}.sql"
        @log.info("Backup #{@backup_name} \"mysqldump -u#{@backup_options[:mysql_username]} -p[PASSWORD] -h#{@backup_options[:mysql_host]} #{@backup_options[:mysql_database]} >#{mysql_tmp_dir}/#{@backup_options[:mysql_database]}.sql\"")
        cmd_output = `#{cmd}`
        cmd_status = $?
        cmd_status = cmd_status == 0 ? :success : :failure
        if cmd_status == :failure
          # cleanup
          cmd_output = `rm -rf #{mysql_tmp_dir}`
          @log.error("Backup #{@backup_name} before_source_backup failed during mysqldump. Output #{cmd_output}")
        end
        # Point source to directory with dump file in it so rest of the world works
        @backup_options[:source_tree] =  mysql_tmp_dir
        return cmd_status
      end
      
      ##
      # Hook to allow customization after cleaning source
      #
      # @return [Symbol] :success or :failure
      #
      def after_clean_source
        tmp_dir = File.expand_path(@backup_options[:temporary_directory])
        mysql_tmp_dir = File.join(tmp_dir,'mysql')
        cmd_output = `rm -rf #{mysql_tmp_dir}`
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
