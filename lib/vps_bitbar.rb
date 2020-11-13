module VPS
  ;
end

# Load just a subset of libraries, just enough for the code for BitBar to work.

# Libraries
require 'singleton'
require 'date'
require 'yaml'
require 'optparse'
require 'liquid'

# Core code
require 'vps/entity_type'
require 'vps/registry'
require 'vps/configuration'
require 'vps/state'
require 'vps/plugin'

require 'vps/plugins/alfred'
require 'vps/plugins/bitbar'
