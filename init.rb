if RUBY_PLATFORM =~ /java/
  require 'java'
  require 'jruby'
  require "j_mem_cache"
  require "active_support/cache/j_mem_cache_store"
  require "cgi/session/j_mem_cache_store"
else
  RAILS_DEFAULT_LOGGER.info("JRuby Memcache is not loaded couse you are not running Jruby.")
end
