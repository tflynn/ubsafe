module UBSafe
  
end

require 'rubygems'
gem 'logging','0.9.4'
require 'logging'

# If we're in development mode - i.e running in the root of the gem source
current_dir = Dir.getwd
if File.exists?(File.expand_path(File.join(current_dir,'bin','/ubsafe_file_mtime')))
  unless defined?(::UBSAFE_ROOT)
    puts "ubsafe: WARNING operating in development mode"
    UBSAFE_ROOT = current_dir
    require File.expand_path(File.join(current_dir, 'lib', 'ubsafe','extensions', 'ubsafe_extensions'))
    require File.join_from_here('ubsafe','ubsafe_config')
    require File.join_from_here('ubsafe','ubsafe_commands','ubsafe_commands')
  end
end

unless defined?(::UBSAFE_ROOT)
  
  UBSAFE_ROOT = File.expand_path(File.join(File.dirname(__FILE__),'..')) 

  require File.expand_path(File.join(File.dirname(__FILE__), 'ubsafe','extensions', 'ubsafe_extensions'))
  require File.join_from_here('ubsafe','ubsafe_config')
  require File.join_from_here('ubsafe','ubsafe_commands','ubsafe_commands')
  
end

UBSafe::Commands::Backup.instance(ARGV).backup


