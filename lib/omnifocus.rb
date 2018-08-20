require 'json'
require_relative 'config'
require_relative 'jxa'

module OmniFocus

  class << self

    def projects(area: Config.load.focused_area, runner: Jxa::Runner.new)
      omnifocus = area[:omnifocus]
      raise 'OmniFocus is not enabled for this area of responsibility' unless omnifocus
      folder = omnifocus[:folder]

      projects = runner.execute('omnifocus-projects', folder)
      projects.map do |project|
        {
          uid: project['id'],
          title: project['name'],
          arg: project['name']
        }
      end
    end

    private


  end
end