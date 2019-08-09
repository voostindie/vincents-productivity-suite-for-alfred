module VPS; end

# Libraries
require 'yaml'
require 'json'
require 'date'
require 'fileutils'
require 'shellwords'
require 'erb'
require 'optparse'

# Support code
require 'vps/output_formatter'
require 'vps/filesystem'
require 'vps/shell'
require 'vps/config'
require 'vps/jxa'

# Plugins
require 'vps/bitbar'
require 'vps/wallpaper'

# Old plugins, to be removed...
require 'vps/focus_plugin'
require 'vps/bear'
require 'vps/markdown_notes'
require 'vps/contacts'
require 'vps/omnifocus'

# Main classes
require 'vps/version'
require 'vps/area'
require 'vps/registry'
require 'vps/configuration'
require 'vps/state'
require 'vps/cli'
