# Shamelessly copied from ActiveSupport::Cache::MemCacheStore.
# This makes use of the JRuby-MemCache-Client as a CacheStore. 
# The JRuby-MemCache-Client behaves slightly different from the standard MemCache
# client, so we have to design around it.
module ActiveSupport
  module Cache
    class JMemCacheStore < MemCacheStore
  
      attr_reader :addresses
      
      # Creates a new MemCacheStore object, with the given memcached server
      # addresses. Each address is either a host name, or a host-with-port string
      # in the form of "host_name:port". For example:
      #
      #   JMemCacheStore.new("localhost", "server-downstairs.localnetwork:8229")
      #
      # If no addresses are specified, then MemCacheStore will connect to
      # localhost port 11211 (the default memcached port).
      def initialize(*addresses)
        addresses = addresses.flatten
        options = addresses.extract_options!
        addresses = ["localhost:11211"] if addresses.empty?
        @addresses = addresses
        @data = JMemCache.new(addresses, options)
      end
    end
  end
end

