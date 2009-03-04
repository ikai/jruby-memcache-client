# Shamelessly borrowed from CGI::Session::MemCacheStore accounting for
# differences in implementation between MemCache and JMemCache

begin
  require 'j_mem_cache'

  class CGI
    class Session
      class JMemCacheStore < MemCacheStore
        def initialize(session, options={})
          id = session.session_id
          unless check_id(id)
            raise ArgumentError, "session_id '%s' is invalid" % id
          end
          @cache = options['cache'] || JMemCache.new(['localhost:11211'])
          @expires = options['expires'] || 0
          @session_key = "session:#{id}"
          @session_data = {}
          unless @cache.get(@session_key)
            @cache.add(@session_key, @session_data, @expires)
          end
        end
      end
    end
  end
rescue LoadError
  # JMemCache isn't available so we cannot load.
end
