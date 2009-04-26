begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "jruby-memcache-client"
    gemspec.summary = "A drop in replacement for Ruby's memcache-client."
    gemspec.email = "abhi@traytwo.com"
    gemspec.homepage = "http://github.com/abhiyerra/jruby-memcache-client"
    gemspec.description = "A drop in replacement for Ruby's memcache-client."
    gemspec.authors = ["Abhi Yerra", "Ikai Lan", "Frederic Jean", "Lennon Day-Reynolds"]
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
    puts "You must have spec installed in order to run the tests."
  end
else
  puts "You must run rake under JRuby if you want to be able to run the specs."
end
