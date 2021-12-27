module VPS
  # Adds support for caching serializable plugin data to disk for speedier invocations.
  #
  # This is a dumb cache; there's no logic to automatically refresh it or anything. Flushing the caching
  # must be done explicitly. There's a command for that: see {VPS::Plugins::Area::Flush}.
  #
  # Implementors - typically {VPS::Plugin::Repository} classes - have to do 3 things
  #
  # 1. Include this module
  # 2. Override the {#cache_enabled?} method
  # 3. Wrap the work that should be cached in a {#cache} block, like so:
  #
  # The result of the computation must be something that can be serialized to disk and back again, in YAML.
  #
  #   def do_stuff(context)
  #     cache(context) do
  #       # compute heavy output here
  #     end
  #   end
  module CacheSupport
    CACHE_PREFIX = File.join(Dir.home, '.vps', 'caches').freeze
    private_constant :CACHE_PREFIX

    # Is the cache enabled? Override this method, or it never will be!
    #
    # @param _context [RepositoryContext]
    # @return [Boolean]
    def cache_enabled?(_context)
      false
    end

    # Caches the output from the block, or returns it from cache if one is present, skipping the block completely.
    # If a cache needs to differ per entity, pass the entity ID as the first argument.
    #
    # @param context [RepositoryContext]
    # @param id [String] optional instance identifier.
    # @yieldparam block code to execute and cache the output of
    # @return [Object] the result of the block
    def cache(context, id = nil, &block)
      if cache_enabled?(context) && cache_present?(context, id)
        from_cache(context, id)
      else
        data = yield block
        to_cache(context, id, data) if cache_enabled?(context)
      end
    end

    # Flushes *all* caches for *all* plugins in a single area
    # @param area_key [String]
    # @return [Integer] the number of caches flushed
    def flush_plugin_cache(area_key)
      count = 0
      Dir.glob(File.join(CACHE_PREFIX, "#{area_key}-*")) do |f|
        File.delete(f)
        count += 1
      end
      count
    end

    private

    def cache_filename(context, id = nil)
      @cache_filename ||= File.join(
        CACHE_PREFIX,
        "#{context.area_key}-#{supported_entity_type.entity_type_name}-#{id.nil? ? 'all' : id.hash_code.to_s}"
      )
    end

    def cache_present?(context, id)
      File.exist?(cache_filename(context, id))
    end

    def from_cache(context, id)
      YAML.unsafe_load_file(cache_filename(context, id))
    end

    def to_cache(context, id, data)
      File.open(cache_filename(context, id), 'w') do |file|
        file.write data.to_yaml
      end
      data
    end
  end
end
