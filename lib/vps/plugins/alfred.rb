module VPS
  module Plugins
    # Alfred plugin to allow easy access to files in the area: documents, reference material and per-project.
    #
    # It also contains an action to generate the Alfred workflow for VPS whenever the focus changes. This
    # action is still a little rough around the edges, but it works "good enough" for me at the moment.
    module Alfred
      include Plugin

      class AlfredConfigurator < Configurator
        def process_area_configuration(area, hash)
          {
            docs: File.join(area[:root], force(hash['documents'], String) || 'Documents', '/'),
            refs: File.join(area[:root], force(hash['reference material'], String) || 'Reference Material', '/')
          }
        end

        def process_action_configuration(hash)
          ruby = hash['ruby'] || ENV["RUBY"] || File.join(
            RbConfig::CONFIG["bindir"],
            RbConfig::CONFIG["ruby_install_name"] + RbConfig::CONFIG["EXEEXT"]).
            sub(/.*\s.*/m, '"\&"')
          root = File.expand_path('../../..', File.dirname(File.realdirpath(__FILE__)))
          script = File.join(root, 'exe', 'vps')
          {
            root: root,
            ruby: ruby,
            script: script,
            vps: "#{ruby} #{script} -a",
            notifications: hash['notifications'] == true
          }
        end
      end

      # Repository for areas; it doesn't actually do anything with files (yet).
      # This class is needed to make the commands on files show up. Since: if the supporting repository
      # isn't there, the command will be filtered out!
      class FileRepository < Repository
        def supported_entity_type
          EntityType::File
        end
      end

      module FileBrowser
        def supported_entity_type
          EntityType::File
        end

        def option_parser
          OptionParser.new do |parser|
            parser.banner = "Browse #{@description} in Alfred"
            parser.separator "Usage: file #{name}"
          end
        end

        def run(context, runner = JxaRunner.new('alfred'))
          path = context.configuration[@symbol]
          runner.execute('browse', path)
          "Opened Alfred for directory '#{path}'"
        end
      end

      class Documents < EntityTypeCommand
        include FileBrowser

        def initialize
          @description = "documents"
          @symbol = :docs
        end
      end

      class Reference < EntityTypeCommand
        include FileBrowser

        def initialize
          @description = 'reference material'
          @symbol = :refs
        end
      end

      class ProjectFiles < CollaborationCommand
        def name
          'files'
        end

        def enabled?(context, project)
          path = resolve_path(context, project)
          Dir.exist?(path)
        end

        def supported_entity_type
          EntityType::Project
        end

        def collaboration_entity_type
          EntityType::File
        end

        def option_parser
          OptionParser.new do |parser|
            parser.banner = 'Browse project files'
            parser.separator 'Usage: project files <projectId>'
            parser.separator ''
            parser.separator 'Where <projectId> is the ID of the project to browse'
          end
        end

        def run(context, runner = JxaRunner.new('alfred'))
          project = context.load_instance
          path = resolve_path(context, project)
          runner.execute('browse', path)
          "Opened Alfred for directory '#{path}'"
        end

        def resolve_path(context, project)
          folder = if project.config['alfred']
                     project.config['alfred']['folder'] || project.name
                   else
                     project.name
                   end
          File.join(context.configuration[:refs], folder) + '/'
        end
      end

      # Rebuild the Alfred workflow whenever the focus changes.
      #
      # This action is far from perfect. For one: it assumes too much. It assumes, for example:
      # - The entity hotkeys
      # - The entity keywords
      # - Every supported entity has a "list" command
      # - That if the 'note' repository exists, the 'today' action should be added
      # - ...and lots more.
      #
      # Code quality is also something to improve.
      #
      # On the other hand, this action does ensure that:
      # - Hotkeys and keywords are not registered if an entity is not supported
      # - Icons for lists are set to the correct application.
      #
      # It it kind of cool to suddenly see the icon switch from Obsidian to Bear and back again,
      # fully automatically, after switching focus!
      #
      # Plus, maintaining a workflow in actual code instead of a drag-and-drop UI suits me better.
      # I'm not a "low-code lover"...
      class RebuildWorkflow < Action
        def run(context, runner = JxaRunner.new('alfred'))
          @context = context
          @config = context.configuration.actions['alfred']
          @target_dir = File.join(Configuration::ROOT, 'alfred')
          @icons = {}
          prepare_target_directory
          create_workflow
          add_external_paste_trigger
          add_open_config
          add_notification
          add_flush_caches
          add_focus_area
          add_entity_actions
          unless context.configuration.plugins_for(context.area).select { |p| p.name == 'alfred' }.empty?
            add_file_browsers
          end
          write_plist
          link_plugin_icons
          runner.execute('reload', 'nl.ulso.vps')
        end

        private

        def prepare_target_directory
          Dir.mkdir(@target_dir) unless Dir.exist?(@target_dir)
          symlink = File.join(Dir.home, 'Library', 'Application Support', 'Alfred', 'Alfred.alfredpreferences', 'workflows', 'vps')
          File.delete(symlink) if File.exist?(symlink)
          File.symlink(@target_dir, symlink)
          Dir.glob(File.join(@target_dir, '*.png')) do |file|
            File.delete(file)
          end
          File.symlink(File.join(@config[:root], 'icons', 'vps.png'), File.join(@target_dir, 'icon.png'))
        end

        def create_workflow
          @workflow = Workflow.new(
            bundleid: 'nl.ulso.vps',
            name: 'Vincent\'s Productivity Suite',
            createdby: 'Vincent Oostindie',
            description: 'Companion workflow for VPS. Automatically generated. Do not edit!',
            category: 'Productivity',
            disabled: false,
            readme: 'Add the Alfred action to your VPS configuration to update this workflow automatically when the focus changes.',
            webaddress: 'https://github.com/voostindie/vincents-productivity-suite-for-alfred',
            version: 'GENERATED - ' + DateTime.now.to_s
          )
          @workflow.scope = @context.area[:key]
        end

        def add_external_paste_trigger
          trigger = @workflow.external_trigger('paste')
          paste = @workflow.clipboard('{query}', true)
          delay = @workflow.delay(1)
          reset = @workflow.clipboard('{clipboard:1}', false)
          @workflow.wire(trigger, paste, delay, reset)
        end

        def add_open_config
          @workflow.row
          @workflow.column
          config = @workflow.keyword('vps', 'Edit the VPS configuration')
          @workflow.column
          file = @workflow.open_file(Configuration::DEFAULT_FILE)
          @workflow.wire(config, file)
        end

        def add_notification
          if @config[:notifications]
            @workflow.row
            @workflow.column(5)
            @notification = @workflow.notification('{query}', 'Vincent\'s Productivity Suite')
          end
        end

        def add_flush_caches
          @workflow.row
          @workflow.column
          flush = @workflow.keyword('flush', 'Flush all caches for the active area')
          @workflow.column
          script = @workflow.script("#{@config[:vps]} area flush")
          @workflow.column
          @workflow.wire(flush, script, @notification)
        end

        def add_focus_area
          @workflow.row
          f = @workflow.hotkey('F')
          focus_list = @workflow.script_filter("#{@config[:vps]} area list", keyword: 'focus', title: 'Focus on area of responsibility {query}')
          @workflow.column
          focus_action = @workflow.script("#{@config[:vps]} area focus $*")
          @workflow.wire(f, focus_list, focus_action)
          @workflow.wire(focus_list, @notification)
        end

        def add_entity_actions
          types = @context.configuration.plugins_for(@context.area)
                          .map { |p| p.repositories }
                          .flatten
                          .map { |r| r.supported_entity_type.entity_type_name }
          %w(note project contact group event).each do |entity_type_name|
            if types.include?(entity_type_name)
              plugin_name = @context.configuration.plugins_for(@context.area).find do |p|
                !p.repositories.select do |r|
                  r.supported_entity_type.entity_type_name == entity_type_name
                end.empty?
              end.name
              add_actions_for_entity(entity_type_name, plugin_name)
              if entity_type_name == 'note'
                add_create_note(plugin_name)
                add_today_note(plugin_name)
              end
            end
          end
        end

        def add_actions_for_entity(entity_type_name, plugin_name)
          first = entity_type_name[0]
          single = entity_type_name
          plural = entity_type_name + 's'
          @workflow.row
          hotkey = @workflow.hotkey(first.upcase)
          list = @workflow.script_filter("#{@config[:vps]} #{single} list", keyword: "#{plural}", title: "Select #{single} {query}")
          commands = @workflow.script_filter("#{@config[:vps]} area commands #{single} $*", arguments_required: true)
          command = @workflow.script("#{@config[:vps]} $*")
          @workflow.wire(hotkey, list, commands, command, @notification)
          @icons[list] = plugin_name
          @icons[commands] = plugin_name
          @workflow.row
          snippet = @workflow.snippet(first)
          argument = @workflow.argument('TRIGGERED_AS_SNIPPET', true)
          list = @workflow.script_filter("#{@config[:vps]} #{single} list")
          paste = @workflow.script("#{@config[:vps]} #{single} paste $*")
          @workflow.wire(snippet, argument, list, paste)
          @icons[list] = plugin_name
        end

        def add_create_note(plugin_name)
          @workflow.row
          hotkey = @workflow.hotkey(',')
          keyword = @workflow.keyword('note', 'Create note {query}')
          @workflow.column
          script = @workflow.script("#{@config[:vps]} note create $*")
          @workflow.wire(hotkey, keyword, script, @notification)
          @icons[keyword] = plugin_name
        end

        def add_today_note(plugin_name)
          @workflow.row
          hotkey = @workflow.hotkey('T')
          @workflow.column(2)
          script = @workflow.script("#{@config[:vps]} note today")
          @workflow.wire(hotkey, script, @notification)
          @workflow.row
          @workflow.column
          keyword = @workflow.keyword('today', 'Open today\'s note')
          @workflow.wire(keyword, script)
          @icons[script] = plugin_name
        end

        def add_file_browsers
          [{ h: 'R', k: 'refs', c: 'reference' }, { h: 'D', k: 'docs', c: 'documents' }].each do |b|
            @workflow.row
            hotkey = @workflow.hotkey(b[:h])
            @workflow.column(2)
            script = @workflow.script_filter("#{@config[:vps]} file #{b[:c]}", keyword: b[:k])
            @workflow.wire(hotkey, script)
            @icons[script] = 'alfred'
          end
        end

        def write_plist
          File.open(File.join(@target_dir, 'info.plist'), 'w') do |file|
            file.puts(@workflow.to_plist)
          end
        end

        def link_plugin_icons
          @icons.each_pair do |uid, plugin_name|
            source = File.join(@config[:root], 'icons', "#{plugin_name}.png")
            target = File.join(@target_dir, "#{uid}.png")
            File.symlink(source, target)
          end
        end

        class Workflow
          attr_accessor :scope

          # Create a new workflow. Once setup, call +to_plist+ to convert it to a Plist file for
          # Alfred.
          #
          # @param info [Hash] global settings for the workflow
          def initialize(info)
            @info = info
            @count = 0
            @scope = 'none'
            @objects = []
            @connections = {}
            @uidata = {}
            @xpos = 30
            @ypos = 30
          end

          # Convert the workflow to Plist format.
          # @return [String] the workflow in Plist format.
          def to_plist
            workflow = @info
            workflow[:objects] = @objects
            workflow[:connections] = @connections
            workflow[:uidata] = @uidata
            workflow.to_plist
          end

          # Create connections between the UIDs passed in the array.
          # If the array is ['1', '2', '3'+, you'll get connections from +1+ to +2+ and from +2+ to +3+.
          # @return Void
          def wire(*uids)
            uids.compact!
            i = 0
            while i < uids.size - 1 do
              @connections[uids[i]] ||= []
              @connections[uids[i]] << {
                destinationuid: uids[i + 1],
                modifiers: 0,
                modifiersubtext: '',
                vitoclose: false
              }
              i += 1
            end
          end

          # Creates an Alfred object and plots it in the workflow diagram. You probably don't
          # want to call this method directly. Instead use one of the many helper methods!
          #
          # @param type [String] The Alfred type of the object
          # @param version [Integer] The Alfred version of the object
          # @param size [Symbol] The size of the Alfred object in the diagram either +:normal+ or +:small+
          # @param config [Hash] The Alfred configuration of the object.
          # @return [String] unique ID of the created object.
          def object(type, version, size, config)
            uid = "#{@scope}-#{@count}"
            @count += 1
            object = {
              uid: uid,
              type: type,
              version: version,
              config: config
            }
            @objects << object
            @uidata[object[:uid]] = {
              xpos: size == :normal ? @xpos : @xpos + 40,
              ypos: size == :normal ? @ypos : @ypos + 30
            }
            column
            uid
          end

          # Add an empty column in the current row of objects in the Workflow diagram
          def column(number = 1)
            @xpos += 180 * number
          end

          # Move the "cursor" to the next row of objects in the Workflow diagream
          def row
            @xpos = 30
            @ypos += 130
          end

          # No clue how this mapping came to be in Alfred, but I reverse engineered it:
          HOTKEYS = {
            'A' => 0, 'S' => 1, 'D' => 2, 'F' => 3, 'H' => 4, 'G' => 5, 'Z' => 6,
            'X' => 7, 'C' => 8, 'V' => 9, '§' => 10, 'B' => 11, 'Q' => 12, 'W' => 13,
            'E' => 14, 'R' => 15, 'Y' => 16, 'T' => 17, '1' => 18, '2' => 19, '3' => 20,
            '4' => 21, '6' => 22, '5' => 23, '=' => 24, '9' => 25, '7' => 26, '-' => 27,
            '8' => 28, '0' => 29, ']' => 30, 'O' => 31, 'U' => 32, '[' => 33, 'I' => 34,
            'P' => 35, 'L' => 37, 'J' => 38, '\'' => 39, 'K' => 40, ';' => 41, '\\' => 42,
            ',' => 43, '/' => 44, 'N' => 45, 'M' => 46, '.' => 47, ' ' => 49, '`' => 50,
          }

          # How did I get to all the configuration settings below? Simple: I created a workflow,
          # configured it the way I wanted it to be, and then watched what happened in the Alfred
          # workflow file.

          def hotkey(character)
            char = character.upcase
            object('alfred.workflow.trigger.hotkey', 2, :normal,
                   action: 0,
                   focusedappvariable: false,
                   focusedappvariablename: '',
                   hotkey: HOTKEYS[char],
                   hotmod: 1835008,
                   hotstring: char,
                   leftcursor: false,
                   modsmode: 2,
                   relatedAppsMode: 0
            )
          end

          def snippet(keyword)
            object('alfred.workflow.trigger.snippet', 1, :normal,
                   focusedappvariable: false,
                   focusedappvariablename: '',
                   keyword: keyword
            )
          end

          def external_trigger(triggerid)
            object('alfred.workflow.trigger.external', 1, :normal, triggerid: triggerid)
          end

          def script_filter(script, keyword: '', title: '', arguments_required: false)
            object('alfred.workflow.input.scriptfilter', 3, :normal,
                   alfredfiltersresults: arguments_required ? false : true,
                   alfredfiltersresultsmatchmode: 0,
                   argumenttreatemptyqueryasnil: false,
                   argumenttrimmode: 0,
                   argumenttype: arguments_required ? 0 : 1,
                   escaping: 0,
                   keyword: keyword,
                   queuedelaycustom: 3,
                   queuedelayimmediatelyinitially: true,
                   queuedelaymode: 0,
                   queuemode: 1,
                   runningsubtext: '',
                   script: script,
                   scriptargtype: 1,
                   scriptfile: '',
                   subtext: '',
                   title: title,
                   type: 0,
                   withspace: false
            )
          end

          def keyword(keyword, text)
            object('alfred.workflow.input.keyword', 1, :normal,
                   argumenttype: 2,
                   keyword: keyword,
                   subtext: '',
                   text: text,
                   scriptfile: '',
                   withspace: false
            )
          end

          def script(script)
            object('alfred.workflow.action.script', 2, :normal,
                   concurrently: false,
                   escaping: 102,
                   script: script,
                   scriptargtype: 1,
                   scriptfile: '',
                   type: 0
            )
          end

          def open_file(file, application = nil)
            object('alfred.workflow.action.openfile', 3, :normal,
                   openwith: application || '',
                   sourcefile: file
            )
          end

          def notification(text, title)
            object('alfred.workflow.output.notification', 1, :normal,
                   lastpathcomponent: false,
                   onlyshowifquerypopulated: true,
                   removeextension: false,
                   text: text,
                   title: title
            )
          end

          def clipboard(text, autopaste)
            object('alfred.workflow.output.clipboard', 3, :normal,
                   text: text,
                   autopaste: autopaste
            )
          end

          def argument(name, value)
            object('alfred.workflow.utility.argument', 1, :small,
                   argument: '{query}',
                   passthroughargument: false,
                   variables: {
                     name => value.to_s
                   }
            )
          end

          def delay(seconds)
            object('alfred.workflow.utility.delay', 1, :small,
                   seconds: seconds.to_s
            )
          end
        end
      end
    end
  end
end