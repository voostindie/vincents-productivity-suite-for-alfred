module VPS; end

# Libraries
require 'yaml'
require 'json'
require 'date'
require 'fileutils'
require 'shellwords'
require 'erb'
require 'optparse'

# Core code
require 'vps/output_formatter'
require 'vps/filesystem'
require 'vps/shell'
require 'vps/config'
require 'vps/jxa'
require 'vps/version'
require 'vps/configuration'
require 'vps/state'
require 'vps/cli'

# Plugins
require 'vps/plugin_support'
require 'vps/area'
require 'vps/bear'
require 'vps/bitbar'
require 'vps/contacts'
require 'vps/files'
require 'vps/omnifocus'
require 'vps/wallpaper'

# And finally, the plugin registry:
require 'vps/registry'



