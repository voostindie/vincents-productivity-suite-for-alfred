require 'spec_helper'

module VPS
  describe Registry, '#initialize' do

    registry = Registry.new

    it 'registers all plugins under the Plugins module' do
      pp registry.plugins
      expect(registry.plugins.size).to be(14)
    end

    it 'registers the Alfred plugin' do
      expect(registry.plugins).to include { |p| p.name == 'alfred' }
      expect(registry.plugins['alfred']).to be_truthy
    end

    it 'instantiates the repositories' do
      repositories = registry.plugins['obsidian'].repositories
      expect(repositories.size).to be(1)
      expect(repositories.all? {|r| r.is_a?(VPS::Plugin::BaseRepository)}).to be_truthy
    end

    it 'instantiates the commands' do
      commands = registry.plugins['alfred'].commands
      expect(commands.size).to be(3)
      expect(commands.all? {|c| c.is_a?(VPS::Plugin::BaseCommand)}).to be_truthy
    end
  end
end