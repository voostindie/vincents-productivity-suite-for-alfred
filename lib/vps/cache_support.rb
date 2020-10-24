module VPS
  ##
  # Adds support for caching plugin command output to disk for speedier invocations.
  #
  # This is a dumb cache; there's no logic to automatically refresh it or anything. Flushing the caching
  # must be done explicitly.
  #
  # Implementors - typically Repositories - have to do 3 things
  # 1. Include this module
  # 2. Override the `cache_enabled?` method
  # 3. Wrap the work that should be cached in a `cache` block, like so:
  #
  #   def do_stuff(context)
  #     cache(context) do
  #       # compute heavy output here
  #     end
  #   end
  module CacheSupport

    CACHE_PREFIX = '.vps.cache.'.freeze

    ##
    # Is the cache enabled? Override this method, or it never will be!
    def cache_enabled?(context)
      false
    end

    ##
    # Caches the output from the block, or returns it from cache if one is present, skipping the block completely.
    # If a cache needs to differ per entity, pass the entity ID as the first argument.
    def cache(context, id = nil, &block)
      if cache_enabled?(context) && cache_present?(context, id)
        from_cache(context, id)
      else
        data = yield block
        to_cache(context, id, data) if cache_enabled?(context)
      end
    end

    ##
    # Flushes *all* caches for *all* plugins in a single area
    def flush_plugin_cache(area_key)
      count = 0
      Dir.glob(File.join(Dir.home, CACHE_PREFIX + area_key + '-*')) do |f|
        File.delete(f)
        count += 1
      end
      count
    end

    private

    def cache_filename(context, id = nil)
      @cache_filename ||= File.join(Dir.home,
                                    CACHE_PREFIX +
                                      context.area_key +
                                      '-' +
                                      supported_entity_type.entity_type_name + '-' +
                                      (id.nil? ? 'all' : "-#{hash_code(id)}"))
    end

    ##
    # Source: https://stackoverflow.com/questions/22740252/how-to-generate-javas-string-hashcode-using-ruby#26063180
    def hash_code(string)
      string.each_char.reduce(0) do |result, char|
        [((result << 5) - result) + char.ord].pack('L').unpack('l').first
      end
    end

    def cache_present?(context, id)
      File.exist?(cache_filename(context, id))
    end

    def from_cache(context, id)
      YAML.load_file(cache_filename(context, id))
    end

    def to_cache(context, id, data)
      File.open(cache_filename(context, id), 'w') do |file|
        file.write data.to_yaml
      end
      data
    end
  end
end

