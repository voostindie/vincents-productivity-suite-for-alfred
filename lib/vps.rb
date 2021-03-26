# == Vincent's Productivity Suite
#
# If you're looking at this code, then what you probably want to do is mess around with
# the existing plugins, or create a plugin of your own. For that, see the {VPS::Plugin} module.
#
# Just to warn you: I have a strong background in Java and other typed languages. That
# means I'm not very comfortable with the freedom and flexibility Ruby offers and as a result
# force myself into a fairly rigid structure. The code works, but it's definitely not the best Ruby
# you ever encountered. *Ye be warned!*
module VPS
end

# Libraries
require 'date'
require 'English'
require 'erb'
require 'fileutils'
require 'ice_cube'
require 'json'
require 'liquid'
require 'optparse'
require 'plist'
require 'shellwords'
require 'singleton'
require 'sqlite3'
require 'yaml'
require 'zaru'

# Core code
require_relative 'vps/output_formatter'
require_relative 'vps/shell'
require_relative 'vps/jxa'
require_relative 'vps/version'
require_relative 'vps/entity_type'
require_relative 'vps/registry'
require_relative 'vps/configuration'
require_relative 'vps/state'
require_relative 'vps/context'
require_relative 'vps/command_runner'
require_relative 'vps/cli'
require_relative 'vps/plugin'
require_relative 'vps/cache_support'
require_relative 'vps/note_support'
require_relative 'vps/xcall'

# String extensions
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

  # Source: https://stackoverflow.com/questions/22740252/how-to-generate-javas-string-hashcode-using-ruby#26063180
  def hash_code
    each_char.reduce(0) do |result, char|
      [((result << 5) - result) + char.ord].pack('L').unpack1('l')
    end
  end
end

# Plugins
files = Dir.glob(File.join(File.dirname(__FILE__), 'vps/plugins/**.rb')).sort
files.each { |f| require f }
