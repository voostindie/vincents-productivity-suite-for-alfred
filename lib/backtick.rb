# Runs executable commands.
#
# This module exists only to be able to stub out the backtickcommand.
module Backtick

  class Runner

    def execute(command)
      `#{command}`
    end
  end
end