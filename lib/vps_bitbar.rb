# See +vps_bitbar.rb+ for module documentation.
module VPS
end

# Load just a subset of libraries, just enough for the code for BitBar to work.

# Libraries
require 'singleton'
require 'date'
require 'yaml'
require 'optparse'

# Core code
require_relative 'vps/entity_type'
require_relative 'vps/registry'
require_relative 'vps/configuration'
require_relative 'vps/state'
require_relative 'vps/plugin'
require_relative 'vps/plugins/alfred'
require_relative 'vps/plugins/bitbar'
