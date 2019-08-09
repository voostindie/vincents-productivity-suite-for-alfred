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
require 'vps/bitbar'
require 'vps/wallpaper'
require 'vps/omnifocus'

# Old plugins, to be removed...
require 'vps/bear'
require 'vps/markdown_notes'
require 'vps/contacts'

# And finally, the plugin registry:
require 'vps/registry'



