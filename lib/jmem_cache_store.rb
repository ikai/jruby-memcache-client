require 'jruby_memcache'
require 'active_support'

# Shamelessly copied from ActiveSupport::Cache::MemCacheStore.
# This makes use of the JRuby-MemCache-Client as a CacheStore. 
# The JRuby-MemCache-Client behaves slightly different from the standard MemCache
# client, so we have to design around it.
class JMemCacheStore < ActiveSupport::Cache::Store

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

  def read(key, options = nil) # :nodoc:
    super
    @data.get(key, raw?(options))
  end


  def write(key, value, options = nil)
    super
    method = options && options[:unless_exist] ? :add : :set

    value = value.to_s if raw?(options)
    @data.send(method, key, value, expires_in(options), raw?(options))
  rescue MemCache::MemCacheError => e
    logger.error("MemCacheError (#{e}): #{e.message}")
    false
  end

  def delete(key, options = nil) # :nodoc:
    super
    @data.delete(key, expires_in(options))
  rescue MemCache::MemCacheError => e
    logger.error("MemCacheError (#{e}): #{e.message}")
    false
  end

  def exist?(key, options = nil) # :nodoc:
    !read(key, options).nil?
  end

  def increment(key, amount = 1) # :nodoc:
    log("incrementing", key, amount)

    @data.incr(key, amount)
  rescue MemCache::MemCacheError
    nil
  end

  def decrement(key, amount = 1) # :nodoc:
    log("decrement", key, amount)

    @data.decr(key, amount)
  rescue MemCache::MemCacheError
    nil
  end

  def delete_matched(matcher, options = nil) # :nodoc:
    super
    raise "Not supported by Memcache"
  end

  def clear
    @data.flush_all
  end

  def stats
    @data.stats
  end

  private
    def expires_in(options)
      (options && options[:expires_in]) || 0
    end

    def raw?(options)
      options && options[:raw]
    end
end