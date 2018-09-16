# Runs executable commands.
#
# This module exists only to be able to stub out the system command.
module System

  class Runner

    def execute(command)
      system(command)
    end
  end
end