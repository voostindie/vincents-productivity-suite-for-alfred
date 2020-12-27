module VPS
  # Very (!) simple wrapper around XCall: https://github.com/martinfinke/xcall,
  # for use in plugins for applications that use x-callback-urls, like Bear.
  #
  # This plugin assumes that the `xcall.app` is present in the same location as this script.
  class Xcall
    include Singleton

    def initialize
      @command = "#{File.dirname(__FILE__).gsub(' ', '\ ')}/xcall.app/Contents/MacOS/xcall"
    end

    # @param uri [String] x-callback-url to execute
    # @param runner [#execute] runner to execute shell commands against
    # @return [Hash] output of the callback, parsed from JSON to a Ruby hash
    def execute(uri, runner = Shell::CaptureOutputRunner.instance)
      JSON.parse(runner.execute("#{@command} -url \"#{uri}\""))
    end
  end
end
