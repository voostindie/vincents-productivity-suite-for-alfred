module VPS; end

# Libraries
require 'yaml'
require 'json'
require 'date'
require 'fileutils'
require 'shellwords'
require 'erb'
require 'optparse'
require 'sqlite3'
require 'ice_cube'

# Core code
require 'vps/output_formatter'
require 'vps/filesystem'
require 'vps/shell'
require 'vps/jxa'
require 'vps/version'
require 'vps/entities'
require 'vps/registry'
require 'vps/configuration'
require 'vps/state'
require 'vps/context'
require 'vps/cli'
require 'vps/plugin_support'

# Plugins
require 'vps/plugins/area'
require 'vps/plugins/bear'
require 'vps/plugins/bitbar'
require 'vps/plugins/calendar'
require 'vps/plugins/contacts'
require 'vps/plugins/files'
require 'vps/plugins/omnifocus'
require 'vps/plugins/paste'
require 'vps/plugins/wallpaper'
