module UBSafe
  
end

require 'rubygems'
gem 'logging','0.9.4'
require 'logging'

UBSAFE_ROOT = File.expand_path(File.join(File.dirname(__FILE__),'..')) unless defined?(::UBSAFE_ROOT)

require File.expand_path(File.join(File.dirname(__FILE__), 'ubsafe','extensions', 'ubsafe_extensions'))
require File.join_from_here('ubsafe','ubsafe_config')
require File.join_from_here('ubsafe','ubsafe_commands','ubsafe_commands')
