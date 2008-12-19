require 'java'
require File.dirname(__FILE__) + '/java_memcached-release_2.0.1.jar'

class JMemCache
  include_class 'com.danga.MemCached.MemCachedClient'
  include_class 'com.danga.MemCached.SockIOPool'
    
  VERSION = '1.5.0'

  ##
  # Default options for the cache object.

  DEFAULT_OPTIONS = {
    :namespace   => nil,
    :readonly    => false,
    :multithread => true,
  }

  ##
  # Default memcached port.

  DEFAULT_PORT = 11211

  ##
  # Default memcached server weight.

  DEFAULT_WEIGHT = 1
  
  attr_accessor :request_timeout

  ##
  # The namespace for this instance

  attr_reader :namespace

  ##
  # The multithread setting for this instance

  attr_reader :multithread

  ##
  # The servers this client talks to.  Play at your own peril.

  attr_reader :servers
  
  def initialize(*args)
    servers = []
    opts = {}

    case args.length
    when 0 then # NOP
    when 1 then
      arg = args.shift
      case arg
      when Hash   then opts = arg
      when Array  then servers = arg
      when String then servers = [arg]
      else raise ArgumentError, 'first argument must be Array, Hash or String'
      end
    when 2 then
      servers, opts = args
    else
      raise ArgumentError, "wrong number of arguments (#{args.length} for 2)"
    end

    opts = DEFAULT_OPTIONS.merge opts
    
    # DO STUFF HERE
    
    @namespace   = opts[:namespace]

    @client = MemCachedClient.new
    
    @client.primitiveAsString = true 
  	@client.sanitizeKeys = false 
  	
    servers = [
			  "127.0.0.1:11211"
      ]
    weights = [1,1,1]

		pool = SockIOPool.getInstance

    # // set the servers and the weights
    pool.servers = servers.to_java(:string)
    pool.weights = weights.to_java(:Integer)
    
    # 
    # // set some basic pool settings
    # // 5 initial, 5 min, and 250 max conns
    # // and set the max idle time for a conn
    # // to 6 hours
    pool.initConn = 5
    pool.minConn = 5 
    pool.maxConn = 250
    pool.maxIdle = 1000 * 60 * 60 * 6 

    # // set the sleep for the maint thread
    # // it will wake up every x seconds and
    # // maintain the pool size
    pool.maintSleep = 30 
    # 
    # // set some TCP settings
    # // disable nagle
    # // set the read timeout to 3 secs
    # // and don't set a connect timeout
    pool.nagle = false 
    pool.socketTO = 3000
    pool.socketConnectTO = 3000 
    pool.initialize__method
		
  end
  

  def get(key, raw = false)
    value = @client.get(key)
    return nil if value.nil?
    
    value = Marshal.load value unless raw
    value
  end
  
  def set(key, value, expiry = 0, raw = false)
    value = Marshal.dump value unless raw
    @client.set(key, value)
  end
  
  def add(key, value, expiry = 0, raw = false)
    @client.add(key, value)
  end
  
  def delete(key, expiry = 0)
    @client.delete(key)
  end
  
  def incr(key, amount = 1)
    @client.incr(key, amount)
  end
  
  def decr(key, amount = 1)
    @client.decr(key, amount)
  end
  
  def flush_all
    @client.flushAll
  end
  
  def stats
    stats_hash = {}
    @client.stats.each do |server, stats|
      stats_hash[server] = Hash.new
      stats.each do |key, value|
        stats_hash[server][key] = value
      end
    end
    stats_hash
  end
  
end

