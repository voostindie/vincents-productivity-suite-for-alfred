require 'spec_helper'

module VPS
  describe Registry, '#initialize' do
    registry = Registry.instance

    it 'registers all plugins under the Plugins module' do
      expect(registry.plugins.size).to be(19)
    end

    it 'registers the Alfred plugin' do
      expect(registry.plugins).to(include { |p| p.name == 'alfred' })
      expect(registry.plugins['alfred']).to be_truthy
    end

    it 'instantiates the repositories' do
      repositories = registry.plugins['obsidian'].repositories
      expect(repositories.size).to be(1)
      expect(repositories.all? { |r| r.is_a?(VPS::Plugin::Repository) }).to be_truthy
    end

    it 'instantiates the commands' do
      commands = registry.plugins['alfred'].commands
      expect(commands.size).to be(8)
      expect(commands.all? { |c| c.is_a?(VPS::Plugin::Command) }).to be_truthy
    end
  end
end
