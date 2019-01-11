require 'json'
require 'shellwords'

##
# Runs macOS JavaScript Automation scripts. Output is always assumed to be in JSON
# format, which is parsed and returned as the result.
#
# By default scripts are located in the same directory as the calling Ruby file is in,
# for easy co-location of related code.
#
# The code is NOT protected against escaping out of the 'jxa' folder. Don't use this code
# anywhere outside of the scope of this application!
require 'shellwords'

module Jxa

  class Runner

    ##
    # @param [String] relative_to the file relative to which JavaScript files must be located.
    #   Typically this is +__FILE__+.
    def initialize(relative_to)
      @root = File.dirname(relative_to)
    end

    ##
    # Runs a JavaScript automation script and returns its response.
    #
    # @param script [String] the name of the script to run, without the +.js+ extension.
    # @param args [Array<String>] the arguments to be passed to the JavaScript
    # @return [JSON] The output of the script, parsed as JSON.
    def execute(script, *args)
      script = File.join(@root, script) + '.js'
      raise "JXA script not found: #{script}" unless File.exist?(script)
      script = Shellwords.escape(script)
      args = args.map {|arg| Shellwords.escape(arg)}
      command = ([script] + args).join(' ')
      json = `#{command}`
      raise "JXA script execution failed: '#{command}'" unless $? == 0
      JSON.parse(json)
    end
  end
end