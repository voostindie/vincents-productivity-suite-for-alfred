require 'date'
require 'fileutils'
require_relative 'config'
require_relative 'shell'

module Markdown
  def self.edit_note(path, area: Config.load.focused_area, runner: Shell::ReplaceProcessRunner.new)
    raise 'File not found' unless File.exist?(path)
    command = "#{area[:markdown_notes][:editor]} \"#{path}\""
    runner.execute(command)
  end

  def self.search_notes(criteria, area: Config.load.focused_area, runner: Shell::CaptureOutputRunner.new)
    notes = area[:markdown_notes]
    raise 'Markdown notes are not enabled for the focused area' unless notes
    ext = notes[:extension]
    path = File.join(area[:root], notes[:path])
    command = "mdfind -onlyin \"#{path}\" #{criteria}"
    output = runner.execute(command)
    output.each_line
          .map(&:chomp)
          .select { |line| line.end_with?(ext) }
          .map do |file|
            {
              uid: file,
              title: File.basename(file, ".#{ext}"),
              type: 'file',
              arg: file
            }
          end
  end

  # Creates a Markdown note on disk according to templates
  class Note
    attr_reader :context, :path, :content

    def initialize(title, date: DateTime.now, area: Config.load.focused_area)
      notes = area[:markdown_notes]
      raise 'Markdown notes are not enabled for the focused area' unless notes

      title ||= 'Unnamed note'
      safe_title = title.gsub(/[\t\n"',;\.!@#\$%\^&*]/, '').gsub(/\//, '-')
      slug = safe_title.downcase.gsub(/[ ]/, '-').gsub('--', '-')
      @context = {
        year: date.strftime('%Y'),
        month: date.strftime('%m'),
        week: date.strftime('%V'),
        day: date.strftime('%d'),
        title: title,
        safe_title: safe_title,
        slug: slug
      }
      @path = File.join(
        area[:root],
        notes[:path],
        merge_template(notes[:name_template])
      ) +
              '.' + notes[:extension]
      @content = merge_template(notes[:file_template])
    end

    def create_file
      return @path if File.exist?(@path)
      directory = File.dirname(@path)
      FileUtils.mkdir_p directory
      File.open(@path, 'w') { |file| file.puts @content }
      @path
    end

    private

    def merge_template(template)
      result = template.dup
      @context.each_pair do |key, value|
        result.gsub!('$' + key.to_s, value)
      end
      result
    end
  end
end
