#!/usr/bin/env ruby -W0
#
# <bitbar.title>VPS focus</bitbar.title>
# <bitbar.version>v1.0</bitbar.version>
# <bitbar.author>Vincent Oostindie</bitbar.author>
# <bitbar.author.github>voostindie</bitbar.author.github>
# <bitbar.desc>Shows the active focus from VPS, and allows focus to be changed.</bitbar.desc>
# <bitbar.dependencies>ruby</bitbar.dependencies>
# <bitbar.abouturl>https://github.com/voostindie/vincents-productivity-suite-for-alfred</bitbar.abouturl>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
# <swiftbar.hideSwiftBar>true</swiftbar.hideSwiftBar>
#
# To include this plugin in BitBar, symlink to it from your BitBar plugins directory.
# DON'T COPY THIS FILE! If you do that, it will lose the path to the rest of the scripts.
#
# To make sure BitBar updates when you change the focus through Alfred, make sure to
# include "bitbar" in your actions configuration.
#
# Be aware: this script is run using the Ruby-version provided by MacOS, which is definitely
# not the latest...

VPS_BITBAR_ROOT = File.dirname(File.realdirpath(__FILE__))
VPS_ROOT = File.expand_path('../lib', VPS_BITBAR_ROOT)

$LOAD_PATH.unshift VPS_ROOT

require 'vps_bitbar'

$stderr.reopen(File.new('/dev/null', 'w'))
puts VPS::Plugins::BitBar::output
