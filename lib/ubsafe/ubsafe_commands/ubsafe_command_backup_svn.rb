
module UBSafe

  module Commands
    
    class SVNBackup < UBSafe::Commands::Backup
   
      ##
      # Hook to allow customization before creating source backup
      #
      # @return [Symbol] :success or :failure
      #
      def before_source_backup
        source_tree = File.expand_path(@backup_options[:source_tree])
        tmp_dir = File.expand_path(@backup_options[:temporary_directory])
        svn_tmp_dir = File.join(tmp_dir,'svn')
        cmd = "svnadmin hotcopy #{source_tree} #{svn_tmp_dir}"
        cmd_output = `#{cmd}`
        cmd_status = $?
        cmd_status = cmd_status == 0 ? :success : :failure
        if cmd_status == :failure
          # cleanup
          cmd_output = `rm -rf #{svn_tmp_dir}`
          @log.error("Backup #{@backup_name} before_source_backup failed during hotcopy. Output #{cmd_output}")
        end
        # Point source to hotcopy so rest of the world works
        @backup_options[:source_tree] = svn_tmp_dir
        return cmd_status
      end
      
      ##
      # Hook to allow customization after cleaning source
      #
      # @return [Symbol] :success or :failure
      #
      def after_clean_source
        tmp_dir = File.expand_path(@backup_options[:temporary_directory])
        svn_tmp_dir = File.join(tmp_dir,'svn')
        cmd_output = `rm -rf #{svn_tmp_dir}`
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
