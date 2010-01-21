begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "jruby-memcache-client"
    gemspec.summary = "A drop in replacement for Ruby's memcache-client."
    gemspec.email = "fred@fredjean.net"
    gemspec.homepage = "http://github.com/ikai/jruby-memcache-client"
    gemspec.description = "A drop in replacement for Ruby's memcache-client."
    gemspec.authors = ["Abhi Yerra", "Ikai Lan", "Frederic Jean", "Lennon Day-Reynolds",
		"slyphon", "Brayn Helmkamp", "Travis Tilley"]
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

if RUBY_PLATFORM =~ /java/i
  begin
    require 'spec/rake/spectask'

    task :default => :spec

    desc "Run the specs for the jruby-memcache-client gem"
    Spec::Rake::SpecTask.new
  rescue LoadError
    puts "You must have rspec installed in order to run the tests."
  end
else
  puts "You must run rake under JRuby."
end
