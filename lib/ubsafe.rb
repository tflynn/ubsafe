module UBSafe
  
end

require 'rubygems'
gem 'fastthread','= 1.0.7'
require 'fastthread'
gem 'logging','= 0.9.4'
require 'logging'

unless defined?(::UBSAFE_ROOT)
  
  UBSAFE_ROOT = File.expand_path(File.join(File.dirname(__FILE__),'..')) 

  require File.expand_path(File.join(File.dirname(__FILE__), 'ubsafe','extensions', 'ubsafe_extensions'))
  require File.join_from_here('ubsafe','ubsafe_config')
  require File.join_from_here('ubsafe','ubsafe_commands','ubsafe_commands')
  
end


