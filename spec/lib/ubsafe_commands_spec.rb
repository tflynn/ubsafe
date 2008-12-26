require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))

require 'fileutils'

describe 'UBSafe::Commands' do

  before :each do
    FileUtils.rm_rf('./spec/tmp')
  end
  
  it 'should allow a template-driven specification of the backup file name' do
    config_file_name = './spec/test_data/ubsafe_config.yml'
    backup_name = 'git_repos'
    args = ['-c',config_file_name, '-n', backup_name]
    backup_cmd = UBSafe::Commands::Backup.new(args)
    config = UBSafe::Config.config
    # Default pattern from config - '%f.tar.gz.%n'
    backup_options = config.full_options(backup_name)
    backup_cmd.get_backup_file_name.should == "#{backup_options[:backup_name]}.tar.gz.0"
    backup_options[:backup_file_name_template] = '%f.%n.tar.gz'
    backup_cmd.get_backup_file_name(backup_options).should == "#{backup_options[:backup_name]}.0.tar.gz"
    backup_options[:backup_file_name_template] = '%f.%t.tar.gz'
    backup_file_name = "#{backup_options[:backup_name]}.#{Time.now.utc.strftime(backup_options[:timestamp_format])}.tar.gz"
    backup_cmd.get_backup_file_name(backup_options).should == backup_file_name
    backup_options[:backup_file_name_template] = '%f.%d.tar.gz'
    backup_file_name = "#{backup_options[:backup_name]}.#{Time.now.utc.strftime(backup_options[:date_format])}.tar.gz"
    backup_cmd.get_backup_file_name(backup_options).should == backup_file_name
  end
  
  
  it "should allow the issuing of a (remote) ssh command" do
    config_file_name = './spec/test_data/ubsafe_config.yml'
    backup_name = 'git_repos'
    args = ['-c',config_file_name, '-n', backup_name]
    backup_cmd = UBSafe::Commands::Backup.new(args)
    config = UBSafe::Config.config
    # Default pattern from config - '%f.tar.gz.%n'
    backup_options = config.full_options(backup_name)
    remote_directory = backup_options[:base_backup_directory]
    remote_cmd = "rm -rf #{remote_directory}"
    cmd_status, cmd_output = backup_cmd.ssh_cmd(remote_cmd)
    cmd_status.should == :success
    remote_cmd = "mkdir -p #{remote_directory}"
    cmd_status, cmd_output = backup_cmd.ssh_cmd(remote_cmd)
    cmd_status.should == :success
    remote_cmd = "ls -1a #{remote_directory}"
    cmd_status, cmd_output = backup_cmd.ssh_cmd(remote_cmd)
    cmd_status.should == :success
    cmd_output[0].should == '.'  
    cmd_output[1].should == '..'  
  end
  
  it 'should create a backup file in the specified location with the specified contents' do
    config_file_name = './spec/test_data/ubsafe_config.yml'
    backup_name = 'git_repos'
    args = ['-c',config_file_name, '-n', backup_name]
    backup_cmd = UBSafe::Commands::Backup.new(args)
    backup_cmd.backup
    config = UBSafe::Config.config
    # Default pattern from config - '%f.tar.gz.%n'
    backup_options = config.full_options(backup_name)
    backup_file_name = backup_cmd.get_backup_file_name
    source_tree = File.expand_path(backup_options[:source_tree])
    tmp_dir = File.expand_path(backup_options[:temporary_directory])
    full_backup_file_name = File.expand_path(File.join(tmp_dir,backup_file_name))
    unpack_dir = File.join(tmp_dir,'unpack')
    FileUtils.mkdir_p(unpack_dir)
    FileUtils.mv(full_backup_file_name,unpack_dir)
    Dir.chdir(unpack_dir) do |dir|
      cmd = "tar xzf #{backup_file_name}"
      `#{cmd}`
      File.exists?('README').should be_true
    end
  end
  
  it 'should roll backups according to settings' do
    config_file_name = './spec/test_data/ubsafe_config.yml'
    backup_name = 'git_repos'
    args = ['-c',config_file_name, '-n', backup_name]
    config = UBSafe::Config.config
    config.load(args)
    backup_options = config.full_options(backup_name)

    # General test setup - we can cheat a little, since everything is local - no ssh commands needed
    backup_options[:backups_to_retain] = 5
    backup_directory = File.join(backup_options[:base_backup_directory],backup_name)
    base_test_data_directory = File.expand_path('./spec/test_data/targets')
    FileUtils.mkdir_p(backup_directory)
    backup_cmd = UBSafe::Commands::Backup.new(args)
    
    # Test 1 - no entries
    FileUtils.rm_f(File.join(backup_directory,'*'))
    test_data_directory = File.join(base_test_data_directory,'empty')
    backup_cmd.rotate_destination_files(backup_options,backup_name)
    test_target_files_count = Dir.glob(File.join(test_data_directory,'*')).size
    backup_files_count = Dir.glob(File.join(backup_directory,'*')).size
    backup_files_count.should == test_target_files_count

    # Test 2 - 1 entry
    FileUtils.rm_f(File.join(backup_directory,'*'))
    test_data_directory = File.join(base_test_data_directory,'one_file')
    `cp #{File.join(test_data_directory,'*')} #{backup_directory}`
    backup_cmd.rotate_destination_files(backup_options,backup_name)
    test_target_files_count = Dir.glob(File.join(test_data_directory,'*')).size
    backup_files_count = Dir.glob(File.join(backup_directory,'*')).size
    backup_files_count.should == test_target_files_count

    # Test 3 - 2 entries
    FileUtils.rm_f(File.join(backup_directory,'*'))
    test_data_directory = File.join(base_test_data_directory,'two_files')
    `cp #{File.join(test_data_directory,'*')} #{backup_directory}`
    backup_cmd.rotate_destination_files(backup_options,backup_name)
    test_target_files_count = Dir.glob(File.join(test_data_directory,'*')).size
    backup_files_count = Dir.glob(File.join(backup_directory,'*')).size
    backup_files_count.should == test_target_files_count

    # Test 4 - 5 entries
    FileUtils.rm_f(File.join(backup_directory,'*'))
    test_data_directory = File.join(base_test_data_directory,'five_files')
    `cp #{File.join(test_data_directory,'*')} #{backup_directory}`
    backup_cmd.rotate_destination_files(backup_options,backup_name)
    test_target_files_count = Dir.glob(File.join(test_data_directory,'*')).size
    backup_files_count = Dir.glob(File.join(backup_directory,'*')).size
    backup_files_count.should == test_target_files_count - 1

  end

  after :each do
    FileUtils.rm_rf('./spec/tmp')
  end
  
end
