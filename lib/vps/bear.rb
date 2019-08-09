module VPS
  module Bear

    # Creates a new note in Bear according to templates
    class Note
      attr_reader :context, :path, :tags

      def initialize(title, date: DateTime.now, area: Config.load.focused_area)
        bear = area[:bear]
        raise 'Bear is not enabled for the focused area' unless bear

        title ||= ''
        @context = {
          year: date.strftime('%Y'),
          month: date.strftime('%m'),
          week: date.strftime('%V'),
          day: date.strftime('%d'),
          title: title,
        }
        @tags = bear[:tags].map { |t| merge_template(t) }
      end

      def create_file(runner = Shell::SystemRunner.new)
        title = ERB::Util.url_encode(@context[:title])
        tags = @tags.map { |t| ERB::Util.url_encode(t) }.join(',')
        callback = "bear://x-callback-url/create?title=#{title}&tags=#{tags}"
        runner.execute('open', callback)
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
end
