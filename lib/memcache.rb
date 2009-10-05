require 'java'

require File.dirname(__FILE__) + '/java/java_memcached-release_2.0.1.jar'

class MemCache
  include_class 'com.danga.MemCached.MemCachedClient'
  include_class 'com.danga.MemCached.SockIOPool'

  VERSION = '1.6.0'

  ##
  # Default options for the cache object.

  DEFAULT_OPTIONS = {
    :namespace   => nil,
    :readonly    => false,
    :multithread => true,
    :pool_initial_size => 5,
    :pool_min_size => 5,
    :pool_max_size => 250,
    :pool_max_idle => (1000 * 60 * 60 * 6),
    :pool_maintenance_thread_sleep => 30,
    :pool_use_nagle => false,
    :pool_socket_timeout => 3000,
    :pool_socket_connect_timeout => 3000,
    :pool_name => 'default'
  }

  ## CHARSET for Marshalling
  MARSHALLING_CHARSET = 'UTF-8'

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
  # The configured socket pool name for this client.
  attr_reader :pool_name

  ##
  # Configures the client
  def initialize(*args)
    @servers = []
    opts = {}

    case args.length
    when 0 then # NOP
    when 1 then
      arg = args.shift
      case arg
      when Hash   then opts = arg
      when Array  then @servers = arg
      when String then @servers = [arg]
      else raise ArgumentError, 'first argument must be Array, Hash or String'
      end
    when 2 then
      @servers, opts = args
      @servers = [@servers].flatten
    else
      raise ArgumentError, "wrong number of arguments (#{args.length} for 2)"
    end

    opts = DEFAULT_OPTIONS.merge opts

    @namespace = opts[:namespace] || opts["namespace"]
    @pool_name = opts[:pool_name] || opts["pool_name"]
    @readonly = opts[:readonly] || opts["readonly"]

    @client = MemCachedClient.new(@pool_name)

    @client.primitiveAsString = true
    @client.sanitizeKeys = false

    weights = Array.new(@servers.size, DEFAULT_WEIGHT)

    @pool = SockIOPool.getInstance(@pool_name)
    unless @pool.initialized?
      # // set the servers and the weights
      @pool.servers = @servers.to_java(:string)
      @pool.weights = weights.to_java(:Integer)

      # // set some basic pool settings
      # // 5 initial, 5 min, and 250 max conns
      # // and set the max idle time for a conn
      # // to 6 hours
      @pool.initConn = opts[:pool_initial_size]
      @pool.minConn = opts[:pool_min_size]
      @pool.maxConn = opts[:pool_max_size]
      @pool.maxIdle = opts[:pool_max_idle]

      # // set the sleep for the maint thread
      # // it will wake up every x seconds and
      # // maintain the pool size
      @pool.maintSleep = opts[:pool_maintenance_thread_sleep]
      #
      # // set some TCP settings
      # // disable nagle
      # // set the read timeout to 3 secs
      # // and don't set a connect timeout
      @pool.nagle = opts[:pool_use_nagle]
      @pool.socketTO = opts[:pool_socket_timeout]
      @pool.socketConnectTO = opts[:pool_socket_connect_timeout]
      @pool.aliveCheck = true
      @pool.initialize__method
    end
  end

  def reset
    @pool.shut_down
    @pool.initialize__method
  end

  ##
  # Returns the servers that the client has been configured to
  # use. Injects an alive? method into the string so it works with the
  # updated Rails MemCacheStore session store class.
  def servers
    @pool.servers.to_a.collect do |s|
      s.instance_eval(<<-EOIE)
      def alive?
        #{!!stats[s]}
      end
      EOIE
      s
    end rescue []
  end

  ##
  # Determines whether any of the connections to the servers is
  # alive. We are alive if it is the case.
  def alive?
    servers.to_a.any? { |s| s.alive? }
  end

  alias :active? :alive?

  ##
  # Retrieves a value associated with the key from the
  # cache. Retrieves the raw value if the raw parameter is set.
  def get(key, raw = false)
    value = @client.get(make_cache_key(key))
    return nil if value.nil?
    unless raw
      marshal_bytes = java.lang.String.new(value).getBytes(MARSHALLING_CHARSET)
      value = Marshal.load(String.from_java_bytes(marshal_bytes))
    end
    value
  end

  alias :[] :get

  ##
  # Retrieves the values associated with the keys parameter.
  def get_multi(keys, raw = false)
    keys = keys.map {|k| make_cache_key(k)}
    keys = keys.to_java :String
    values = {}
    values_j = @client.getMulti(keys)
    values_j.to_a.each {|kv|
      k,v = kv
      next if v.nil?
      unless raw
        marshal_bytes = java.lang.String.new(v).getBytes(MARSHALLING_CHARSET)
        v = Marshal.load(String.from_java_bytes(marshal_bytes))
      end
      values[k] = v
    }
    values
  end

  ##
  # Associates a value with a key in the cache. MemCached will expire
  # the value if an expiration is provided. The raw parameter allows
  # us to store a value without marshalling it first.
  def set(key, value, expiry = 0, raw = false)
    raise MemCacheError, "Update of readonly cache" if @readonly
    value = marshal_value(value) unless raw
    key = make_cache_key(key)
    if expiry == 0
      @client.set key, value
    else
      @client.set key, value, expiration(expiry)
    end
  end

  alias :[]= :set

  ##
  # Add a new value to the cache following the same conventions that
  # are used in the set method.
  def add(key, value, expiry = 0, raw = false)
    raise MemCacheError, "Update of readonly cache" if @readonly
    value = marshal_value(value) unless raw
    if expiry == 0
      @client.add make_cache_key(key), value
    else
      @client.add make_cache_key(key), value, expiration(expiry)
    end
  end

  ##
  # Removes the value associated with the key from the cache. This
  # will ignore values that are not already present in the cache,
  # which makes this safe to use without first checking for the
  # existance of the key in the cache first.
  def delete(key, expires = 0)
    raise MemCacheError, "Update of readonly cache" if @readonly
    @client.delete(make_cache_key(key))
  end

  ##
  # Replaces the value associated with a key in the cache if it
  # already is stored. It will not add the value to the cache if it
  # isn't already present.
  def replace(key, value, expiry = 0, raw = false)
    raise MemCacheError, "Update of readonly cache" if @readonly
    value = marshal_value(value) unless raw
    if expiry == 0
      @client.replace make_cache_key(key), value
    else
      @client.replace make_cache_key(key), value
    end
  end

  ##
  # Increments the value associated with the key by a certain amount.
  def incr(key, amount = 1)
    raise MemCacheError, "Update of readonly cache" if @readonly
    value = get(key) || 0
    value += amount
    set key, value
    value
  end

  ##
  # Decrements the value associated with the key by a certain amount.
  def decr(key, amount = 1)
    raise MemCacheError, "Update of readonly cache" if @readonly
    value = get(key) || 0
    value -= amount
    set key, value
    value
  end

  ##
  # Clears the cache.
  def flush_all
    @client.flush_all
  end

  ##
  # Reports statistics on the cache.
  def stats
    stats_hash = {}
    @client.stats.each do |server, stats|
      stats_hash[server] = Hash.new
      stats.each do |key, value|
        unless key == 'version'
          value = value.to_f
          value = value.to_i if value == value.ceil
        end
        stats_hash[server][key] = value
      end
    end
    stats_hash
  end

  class MemCacheError < RuntimeError; end

  protected
  def make_cache_key(key)
    if namespace.nil? then
      key
    else
      "#{@namespace}:#{key}"
    end
  end

  def expiration(expiry)
    java.util.Date.new((Time.now.to_i + expiry) * 1000)
  end

  def marshal_value(value)
    marshal_bytes = Marshal.dump(value).to_java_bytes
    java.lang.String.new(marshal_bytes, MARSHALLING_CHARSET)
  end
end

