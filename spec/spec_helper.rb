require 'rubygems'
require 'rspec'

$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), ".."))
require 'lib/pas'

Dir["spec/shared/*.rb"].each {|f| require f}