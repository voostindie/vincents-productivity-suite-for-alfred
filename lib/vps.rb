module VPS
  ;
end

# Libraries
require 'singleton'
require 'date'
require 'yaml'
require 'json'
require 'fileutils'
require 'shellwords'
require 'erb'
require 'optparse'
require 'sqlite3'
require 'ice_cube'
require 'liquid'
require 'zaru'

# Core code
require 'vps/output_formatter'
require 'vps/filesystem'
require 'vps/shell'
require 'vps/jxa'
require 'vps/version'
require 'vps/entity_types'
require 'vps/registry'
require 'vps/configuration'
require 'vps/state'
require 'vps/context'
require 'vps/command_runner'
require 'vps/cli'
require 'vps/plugin'
require 'vps/cache_support'
require 'vps/note_support'
require 'vps/xcall'

# Extensions
class String
  def url_encode
    ERB::Util.url_encode(self)
  end

  def shell_escape
    Shellwords.escape(self)
  end

  def render_template(context)
    Liquid::Template.parse(self).render(context)
  end
end


# Plugins
files = Dir.glob(File.join(File.dirname(__FILE__), 'vps/plugins/**.rb')).sort
files.each {|f| require f}
