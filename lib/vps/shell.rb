module VPS
  # Exposes way to run external commands in a shell uniformly, in a testable manner.
  #
  # The trick is to inject an object of one of these classes with a default value
  # wherever you're calling out to the system. This allows you to stub out the system
  # calls easily. For example:
  #
  #   def run_a_system_command(runner = Shell::SystemRunner.instance)
  #     runner.execute(...)
  #   end
  module Shell
    # Executes a command using backticks
    class CaptureOutputRunner
      include Singleton
      # @return [String]
      def execute(command)
        `#{command}`
      end
    end

    # Execute a command using [Kernel::system]
    class SystemRunner
      include Singleton
      # @return [Boolean,nil]
      def execute(*args)
        system(*args)
      end
    end

    # Executes a command using [Kernel::exec], replacing the current process!
    class ReplaceProcessRunner
      include Singleton
      # @return [void]
      def execute(*args)
        exec(*args)
      end
    end
  end
end