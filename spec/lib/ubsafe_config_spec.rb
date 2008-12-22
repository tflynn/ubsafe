require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))

describe 'UBSafe::Config' do
  
  it 'should allow a configuration file to be specified from a environment parameter' 
  
  it 'should allow a configuration file to be specified from a parameter' do
    config_file_name = 'ubsafe_config.yml'
    args = ['-c',config_file_name]
    config = UBSafe::Config.config(args)
    puts config.options.inspect
  end
  
  
  
end