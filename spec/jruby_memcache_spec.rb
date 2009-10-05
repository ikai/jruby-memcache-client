require 'java'
require File.dirname(__FILE__) + '/../lib/memcache'

describe MemCache do
  before(:all) do
    @server = "127.0.0.1:11211"
    @client = MemCache.new @server
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
      @client = MemCache.new @server
      @client.servers.should == [@server]
    end

    it "should work if the instance is created with an Array" do
      @client = MemCache.new [ @server ]
      @client.servers.should == [ @server ]
    end

    it "should work if the instance is created with a Hash" do
      @client = MemCache.new [ @server ], :namespace => 'test'
      @client.servers.should == [ @server ]
    end

    it "should work with an explicit pool name" do
      @client = MemCache.new([@server], :pool_name => 'new_pool')
      @client.pool_name.should == 'new_pool'
    end
  end

  describe "namespacing" do
    before(:each) do
      @ns = 'namespace'
      @nsclient = MemCache.new [ @server ] , :namespace => @ns
      @nsclient.flush_all
      @nsclient.set "test", 333, 0
    end

    it "should set and get values transparently" do
      @nsclient.get("test").to_i.should == 333
    end

    it "should set values to the given namespace" do
      @client.get("#{@ns}:test").to_i.should == 333
    end

    it "should not set a value without the given namespace" do
      @client.get("test").to_i.should_not == 333
    end

    it "should delete values in the given namespace" do
      @nsclient.delete "test"
      @nsclient.get("test").should be_nil
    end

    it "should increment in the given namespace" do
      @nsclient.incr("test").to_i.should == 334
    end

    it "should decrement values in the given namespace" do
      @nsclient.decr("test").should == 332
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

    it "should work exactly the same if the []= operator were used" do
      @client['key'] = 'val'
      @client.get('key').should == 'val'
    end
  end

  describe "replacing values from the cache." do
    before :each do
      @client['key'] = 'value'
    end

    it "should be able to replace the stored value." do
      @client.replace('key', 'new value').should be_true
      @client['key'].should == 'new value'
    end

    it "should not replace values that are not in the cache." do
      @client.replace('notthere', 'value').should be_false
    end
  end

  describe "using the Hash notation" do
    before :each do
      @client['key'] = 'value'
    end

    it "should be able to retrieve the value using []" do
      @client['key'].should == 'value'
    end

    it "should be able to retrieve the value using get" do
      @client.get('key').should == 'value'
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
      @client.set 'incr', 100, 0
      @client.incr 'incr'
      @client.get('incr').to_i.should == 101
    end

    it "should increment a value by a given second parameter" do
      @client.set 'incr', 100, 0
      @client.incr 'incr', 20
      @client.get('incr').to_i.should == 120
    end
  end

  describe "#decr" do

    it "should decrement a value by 1 without a second parameter" do
      @client.set 'decr', 100, 0
      @client.decr 'decr'
      @client.get('decr').to_i.should == 99
    end

    it "should decrement a value by a given second parameter" do
      @client.set 'decr', 100, 0
      @client.decr 'decr', 20
      @client.get('decr').to_i.should == 80
    end
  end

  describe "with Ruby Objects" do
    it "should be able to transparently set and get equivalent Ruby objects" do
      obj = { :test => :hi }
      @client.set('obj', obj)
      @client.get('obj').should == obj
    end
  end

  describe "using set with an expiration" do
    it "should make a value unretrievable if the expiry is set to a negative value" do
      @client.set('key', 'val', -1)
      @client.get('key').should be_nil
    end

    it "should make a value retrievable for only the amount of time if a value is given" do
      @client.set('key', 'val', 2)
      @client.get('key').should == 'val'
      sleep(3)
      @client.get('key').should be_nil
    end
  end

  describe "#get_multi" do
    it "should get 2 keys" do
      @client.set('key', 'val')
      @client.set('key2', 'val2')
      @client.get_multi(%w/key key2/).should == {'key' => 'val', 'key2' => 'val2'}
    end

    it "should ignore nil values" do
      @client.set('key', 'val')
      @client.set('key2', 'val2')
      @client.get_multi(%w/key key2 key3/).should == {'key' => 'val', 'key2' => 'val2'}
    end

    it "should not marshall if requested" do
      @client.set('key', 'val', 0, true)
      @client.set('key2', 'val2', 0, true)
      @client.get_multi(%w/key key2/, true).should == {'key' => 'val', 'key2' => 'val2'}
    end
  end

  describe "aliveness of the MemCache server." do
    before :each do
      @servers = ["localhost:11211", "localhost:11212", {:pool_name => "test"}]
      @client = MemCache.new @servers
      @client.flush_all
    end

    it "should report the client as being alive." do
      @client.should be_alive
    end

    it "should report localhost:11211 as being alive." do
      servers = @client.servers
      servers.first.should be_alive
    end

    it "should report localhost:11212 as not being alive." do
      servers = @client.servers
      servers.find {|s| s.to_s == "localhost:11212"}.should be_nil
    end
  end
end

