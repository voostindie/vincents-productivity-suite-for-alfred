module VPS
  # Runs macOS JavaScript Automation scripts. Output is always assumed to be in JSON
  # format, which is parsed and returned as the result.
  #
  # All scripts are expected to live in a subdirectory of the 'jxa' directory.
  #
  # The code is NOT protected against escaping out of the 'jxa' directory. Don't use this code
  # anywhere outside of the scope of this application!
  class JxaRunner
    # @param directory [String] name of the directory within the 'jxa' directory.
    def initialize(directory)
      @root = File.join(File.dirname(__FILE__), '..', '..', 'jxa', directory)
    end

    # Runs a JavaScript automation script and returns its response.
    #
    # @param script [String] the name of the script to run, without the +.jxa+ extension.
    # @param args [Array<String>] the arguments to be passed to the JavaScript
    # @return [Hash] the output of the script, parsed as JSON.
    def execute(script, *args)
      script = "#{File.join(@root, script)}.js"
      raise "JXA script not found: #{script}" unless File.exist?(script)

      script = Shellwords.escape(script)
      args = args.map { |arg| Shellwords.escape(arg) }
      command = ([script] + args).join(' ')
      json = `#{command}`
      raise "JXA script execution failed: '#{command}'" unless $CHILD_STATUS == 0

      JSON.parse(json)
    end
  end
end
