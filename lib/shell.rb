# Exposes way to run external commands in a shell uniformly, in a testable manner.
module Shell
  class CaptureOutputRunner
    def execute(command)
      `#{command}`
    end
  end

  class SystemRunner
    def execute(command)
      system(command)
    end
  end

  class ReplaceProcessRunner
    def execute(command)
      exec(command)
    end
  end
end