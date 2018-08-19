require 'date'
require 'fileutils'
require_relative 'config'

module MarkdownNotes

  class Note

    attr_reader :date, :title, :filename, :slug, :path, :content

    def initialize(title, date: DateTime.now, area: Config.load.active_area)
      @area = area
      @notes = @area[:markdown_notes]
      raise 'Markdown notes are not enabled for this area of responsibility' unless @notes

      @date = date
      @year = @date.strftime("%Y")
      @month = @date.strftime("%m")
      @week = @date.strftime("%V")
      @day = @date.strftime("%d")
      @title = title || 'Unnamed note'
      @filename = safe_filename(@title)
      @slug = create_slug(@filename)
      @path = construct_filename
      @content = merge_template(@notes[:file_template])
    end

    def create_file
      return @path if File.exist?(@path)
      directory = File.dirname(@path)
      FileUtils.mkdir_p directory
      File.open(@path, "w") do |file|
        file.puts @content
      end
      @path
    end

    private

    def safe_filename(string)
      string.gsub(/[\t\n"',;\.!@#\$%\^&*]/, '')
    end

    def construct_filename
      path = merge_template(@notes[:name_template], true)
      File.join(@area[:root], @notes[:path], path) + '.' + @notes[:extension]
    end

    def create_slug(string)
      string.downcase.gsub(/[ ]/, '-').gsub('--', '-')
    end

    def merge_template(template, escape_title = false)
      template
        .gsub('$year', @year)
        .gsub('$month', @month)
        .gsub('$week', @week)
        .gsub('$day', @day)
        .gsub('$title', escape_title ? @filename : @title)
        .gsub('$slug', @slug)
    end
  end
end
