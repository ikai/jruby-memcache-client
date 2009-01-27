if RUBY_PLATFORM =~ /java/
  require 'java'
  require 'jruby'
  require "j_mem_cache"
  require "j_mem_cache_store"
else
  RAILS_DEFAULT_LOGGER.info("JRuby Memcache is not loaded couse you are not running Jruby.")
end