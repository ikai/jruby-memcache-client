# Shamelessly borrowed from CGI::Session::MemCacheStore accounting for
# differences in implementation between MemCache and JMemCache
class CGI
  class Session
    class JMemCacheStore
      def initialize(session, options={})
        id = session.session_id
        unless check_id(id)
          raise ArgumentError, "session_id '%s' is invalid" % id
        end
        @cache = options['cache'] || JMemCache.new('localhost:11211')
        @expires = options['expires'] || 0
        @session_key = "session:#{id}"
        @session_data = {}
        unless @cache.get(@session_key)
          @cache.add(@session_key, @session_data, @expires)
        end
      end

      def check_id(id)
        /[^0-9a-zA-Z]+/ =~ id.to_s ? false : true
      end

      def close
        update
      end

      def data
        @session_data
      end

      def delete
        @cache.delete(@session_key)
        @session_data = {}
      end

      def restore
        @session_data = @cache[@session_key] || {}
      end

      def update
        @cache.set(@session_key, @session_data, @expires)
      end
    end
  end
end

