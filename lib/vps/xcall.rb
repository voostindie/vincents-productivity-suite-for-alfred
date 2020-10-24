module VPS

  ##
  # Very (!) simple wrapper around XCall: <https://github.com/martinfinke/xcall>,
  # for use in plugins for applications that use x-callback-urls, like Bear.
  class Xcall
    include Singleton

    def initialize
      @command = File.dirname(__FILE__).gsub(' ', '\ ') + "/xcall.app/Contents/MacOS/xcall"
    end

    def execute(uri, runner = Shell::CaptureOutputRunner.new)
      JSON.parse(runner.execute("#{@command} -url \"#{uri}\""))
    end
  end
end