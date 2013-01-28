# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "jruby-memcache-client"
  s.version = "1.7.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Abhi Yerra", "Ikai Lan", "Frederic Jean", "Lennon Day-Reynolds", "slyphon", "Brayn Helmkamp", "Travis Tilley", "Sudhindra Rao"]
  s.date = "2013-01-28"
  s.description = "A drop in replacement for Ruby's memcache-client."
  s.email = "fred@fredjean.net"
  s.extra_rdoc_files = [
    "README"
  ]
  s.files = [
    "Gemfile",
    "Gemfile.lock",
    "MIT-LICENSE",
    "README",
    "Rakefile",
    "VERSION.yml",
    "jruby-memcache-client.gemspec",
    "lib/java/java_memcached-release_2.5.1.jar",
    "lib/memcache.rb",
    "spec/jruby_memcache_spec.rb"
  ]
  s.homepage = "http://github.com/ikai/jruby-memcache-client"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.10"
  s.summary = "A drop in replacement for Ruby's memcache-client."

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end

