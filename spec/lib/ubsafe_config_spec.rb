require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))

describe 'UBSafe::Config' do
  
  before :each do
    ENV['UBSAFE_CONFIG_FILE'] = nil
  end
  
  it 'should allow a configuration file to be specified from an environment parameter'  do
    config_file_name = './spec/test_data/ubsafe_config.yml'
    ENV['UBSAFE_CONFIG_FILE'] = config_file_name
    config = UBSafe::Config.config
    config.load
    config.options[:config_file].should == config_file_name
  end
  
  it 'should allow a configuration file to be specified from a parameter' do
    config_file_name = './spec/test_data/ubsafe_config.yml'
    args = ['-c',config_file_name]
    config = UBSafe::Config.config
    config.load(args)
    config.options[:config_file].should == config_file_name
    config.options[:remainder].should == []
  end
  
  it 'should override environment parameter with command-line parameter' do
    config_file_name = 'ubsafe_config.yml'
    ENV['UBSAFE_CONFIG_FILE'] = config_file_name
    config_file_name_2 = './spec/test_data/ubsafe_config.yml'
    args = ['-c',config_file_name_2]
    config = UBSafe::Config.config
    config.load(args)
    config.options[:config_file].should == config_file_name_2
  end
  
  it 'should load the configuration file and make the settings accessible' do
    config_file_name = './spec/test_data/ubsafe_config.yml'
    args = ['-c',config_file_name]
    config = UBSafe::Config.config
    config.load(args)
    config.options[:test_settings][:setting_one].should == '1'
  end
  
  
end