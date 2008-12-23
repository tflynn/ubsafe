module UBSafe
  
end

require 'rubygems'
gem 'logging','0.9.4'
require 'logging'

require File.expand_path(File.join(File.dirname(__FILE__), 'ubsafe','extensions', 'ubsafe_extensions'))
require File.join_from_here('ubsafe','ubsafe_config')
require File.join_from_here('ubsafe','ubsafe_commands')

