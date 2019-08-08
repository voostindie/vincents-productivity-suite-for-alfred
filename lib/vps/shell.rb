# Exposes way to run external commands in a shell uniformly, in a testable manner.
module VPS
  module Shell
    class CaptureOutputRunner
      def execute(command)
        `#{command}`
      end
    end

    class SystemRunner
      def execute(*args)
        system(*args)
      end
    end

    class ReplaceProcessRunner
      def execute(*args)
        exec(*args)
      end
    end
  end
end