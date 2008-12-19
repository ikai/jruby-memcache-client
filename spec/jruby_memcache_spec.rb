require 'rubygems'
require 'spec'
require File.dirname(__FILE__) + '/../lib/jruby_memcache'

describe JMemCache do
  before(:all) do
    @server = "127.0.0.1:11211"
    @client = JMemCache.new @server
    @client.flush_all
  end
  
  after(:each) do
    @client.flush_all
  end
  
  it "should return nil for a non-existent key" do
    @client.get('non-existent-key').should be_nil
  end
  
  describe "setting servers" do
    it "should work if the instance is created with a single String argument" do
      @client = JMemCache.new @server
      @client.servers.should == [@server]
    end
    
    it "should work if the instance is created with an Array" do
      @client = JMemCache.new [ @server ]
      @client.servers.should == [ @server ]
    end
    
    it "should work if the instance is created with a Hash" do
      @client = JMemCache.new [ @server ], :namespace => 'test'
      @client.servers.should == [ @server ]
    end
  end
  
  describe "after setting a value to MemCache" do
    before(:each) do
      @client.set 'key', 'value'
    end
    
    it "should be able to retrieve the value" do
      @client.get('key').should == 'value'
    end
    
    it "should not be able to retrieve the value after deleting" do
      @client.delete('key')
      @client.get('key').should be_nil
    end
    
    it "should not be able to retrieve the value after flushing everything" do
      @client.flush_all
      @client.get("key").should be_nil
    end
    
  end
  
  describe "#stats" do
    it "should return a hash" do    
      @client.stats.should be_instance_of(Hash)
    end
    
    # it "should return 0 for curr_items" do
    #   @client.stats[@server]['curr_items'].should == 0
    # end
    
    it "should return a float for rusage_system and rusage_user" do
      @client.stats[@server]['rusage_system'].should be_instance_of(Float)
      @client.stats[@server]['rusage_user'].should be_instance_of(Float)
    end
    
    it "should return a String for version" do
      @client.stats[@server]['version'].should be_instance_of(String)
    end
  
  end
  
  describe "#incr" do
    
    it "should increment a value by 1 without a second parameter" do
      @client.set 'incr', 100, 0, true
      @client.incr 'incr'
      @client.get('incr', true).to_i.should == 101
    end
    
    it "should increment a value by a given second parameter" do
      @client.set 'incr', 100, 0, true
      @client.incr 'incr', 20
      @client.get('incr', true).to_i.should == 120
    end
  end
  
  describe "#decr" do
    
    it "should decrement a value by 1 without a second parameter" do
      @client.set 'decr', 100, 0, true
      @client.decr 'decr'
      @client.get('decr', true).to_i.should == 99
    end
    
    it "should decrement a value by a given second parameter" do
      @client.set 'decr', 100, 0, true
      @client.decr 'decr', 20
      @client.get('decr', true).to_i.should == 80
    end
  end
  
  describe "with Ruby Objects" do
    it "should be able to transparently set and get equivalent Ruby objects" do
      obj = { :test => :hi }
      @client.set('obj', obj)
      @client.get('obj').should == obj
    end
  end
end

