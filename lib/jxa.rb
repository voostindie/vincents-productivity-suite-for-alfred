require 'json'
require 'shellwords'

# Runs macOS JavaScript Automation scripts from the 'jxa' directory.
# Output is always assumed to be in JSON format, which is parsed and returned as the result.
#
# The code is NOT protected against escaping out of the 'jxa' folder. Don't use this code
# anywhere outside of the scope of this application!
module Jxa

  class Runner

    def initialize
      @root = File.join(File.dirname(__FILE__), 'jxa')
    end

    def execute(script, *args)
      script = File.join(@root, script) + '.js'
      raise "JXA script not found: #{script}" unless File.exist?(script)
      command = ([Shellwords.escape(script)] + args).join(' ')
      json = `#{command}`
      raise "JXA script execution failed: '#{command}'" unless $? == 0
      JSON.parse(json)
    end

  end
end