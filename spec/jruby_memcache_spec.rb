require 'rubygems'
require 'spec'
require File.dirname(__FILE__) + '/../lib/jruby_memcache'

describe JMemCache do
  
  before(:each) do
    @client = JMemCache.new
  end
  
  after(:each) do
    @client.flush_all
  end
  
  it "should return nil for a non-existent key" do
    @client.get('non-existent-key').should be_nil
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
  end
      
end

# m = JMemCache.new
# m.set 'hi', 12345
# puts m.get 'hi'
# m.set 'hi', 12345, 0, true
# m.incr 'hi'
# puts m.get 'hi', true
# m.decr 'hi'
# puts m.get 'hi', true
# m.delete 'hi'
# puts m.get 'hi'
# m.set 'hi', 12345123
# m.flush_all
# puts m.get 'hi'
# puts m.stats
# 
# h = { :test => '123ha' }
# m.set 'test', h
# puts m.get 'test'
# puts m.get('test').class

