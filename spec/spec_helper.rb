require 'rubygems'
gem 'rspec','1.1.8'
require 'spec'

$: << File.join(File.dirname(__FILE__), "..", "lib")

require File.expand_path(File.join(File.dirname(__FILE__), "..", "lib", "ubsafe"))
