#!/usr/bin/env ruby
#
# Sets the name of the focused area in the BitBar
# <https://getbitbar.com>
#
# To include this plugin in BitBar, symlink to it from your BitBar plugins directory.
# DON'T COPY THIS FILE! If you do that, it will lose the path to the rest of the scripts.
#
# To make sure BitBar updates when you change the focus through Alfred, make sure to
# include "bitbar" in your actions configuration.

VPS_BITBAR_ROOT = File.dirname(File.realdirpath(__FILE__))
VPS_ROOT = File.expand_path('../lib', VPS_BITBAR_ROOT)

$LOAD_PATH.unshift VPS_ROOT

require 'vps'

area = Config.load.focused_area
bitbar = area[:bitbar]
label = unless bitbar.nil?
  bitbar[:label]
else
  area[:name]
end
puts label
