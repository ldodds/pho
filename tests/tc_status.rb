$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'pho'
require 'test/unit'

class StatusTest < Test::Unit::TestCase

  STATUS = <<-EOL
  {
    "http:\/\/api.talis.com\/stores\/testing\/config\/access-status" : {
      "http:\/\/schemas.talis.com\/2006\/bigfoot\/configuration#accessMode" : [ { "value" : "http:\/\/schemas.talis.com\/2006\/bigfoot\/statuses#read-write", "type" : "uri" } ],
      "http:\/\/schemas.talis.com\/2006\/bigfoot\/configuration#retryInterval" : [ { "value" : "0", "type" : "literal" } ],
      "http:\/\/schemas.talis.com\/2006\/bigfoot\/configuration#statusMessage" : [ { "value" : "message", "type" : "literal" } ]
    }
  }  
EOL
    
  def test_store_status
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/config/access-status", nil, {"Accept" => "application/json"}) 
   
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    
    store.get_status()
    
  end  
  
  def test_read_from_store
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/config/access-status", nil, {"Accept" => "application/json"}).returns( HTTP::Message.new_response(STATUS) ) 
   
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    
    status = Pho::Status.read_from_store(store)
    
    assert_equal(Pho::READ_WRITE, status.access_mode)
    assert_equal(0, status.retry_interval)
    assert_equal("message", status.status_message)
  end
  
  def test_read_write
    status = Pho::Status.new(0, "test", Pho::UNAVAILABLE)
    assert_equal(false, status.readable?)
    assert_equal(false, status.writeable?)
    
    status = Pho::Status.new(0, "test", Pho::READ_ONLY)
    assert_equal(true, status.readable?)
    assert_equal(false, status.writeable?)

    status = Pho::Status.new(0, "test", Pho::READ_WRITE)
    assert_equal(true, status.readable?)
    assert_equal(true, status.writeable?)
        
  end
end