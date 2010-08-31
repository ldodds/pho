$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'pho'
require 'test/unit'
require 'mocha'

class ContentboxTest < Test::Unit::TestCase
  
  def test_upload_item
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:post).with("http://api.talis.com/stores/testing/items", "data", {"Content-Type" => "text/plain"})
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    f = StringIO.new("data")
    resp = store.upload_item(f, "text/plain")    
  end
  
  def test_upload_item_to_uri
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:put).with("http://api.talis.com/stores/testing/items/1/2/3", "data", {"Content-Type" => "text/plain"})
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    f = StringIO.new("data")    
    resp = store.upload_item(f, "text/plain", "http://api.talis.com/stores/testing/items/1/2/3")
    
  end

  def test_upload_item_to_uri_with_relative
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:put).with("http://api.talis.com/stores/testing/items/1/2/3", "data", {"Content-Type" => "text/plain"})
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    f = StringIO.new("data")    
    resp = store.upload_item(f, "text/plain", "/1/2/3")
    
  end

  def test_upload_item_to_uri_with_relative_file
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:put).with("http://api.talis.com/stores/testing/items/a.txt", "data", {"Content-Type" => "text/plain"})
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    f = StringIO.new("data")    
    resp = store.upload_item(f, "text/plain", "/a.txt")
    
  end
    
  def test_upload_item_to_uri_with_relative2
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:put).with("http://api.talis.com/stores/testing/items/1/2/3", "data", {"Content-Type" => "text/plain"})
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    f = StringIO.new("data")    
    resp = store.upload_item(f, "text/plain", "1/2/3")
    
  end

  def test_upload_item_to_uri_with_relative_file2
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:put).with("http://api.talis.com/stores/testing/items/a.txt", "data", {"Content-Type" => "text/plain"})
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    f = StringIO.new("data")    
    resp = store.upload_item(f, "text/plain", "a.txt")
    
  end
  
            
  def test_delete
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:delete).with("http://api.talis.com/stores/testing/items/1/2/3")
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    store.delete_item("http://api.talis.com/stores/testing/items/1/2/3")
  end  

  def test_delete_with_relative_uri
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:delete).with("http://api.talis.com/stores/testing/items/1/2/3")
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    store.delete_item("/items/1/2/3")
  end  
    
  def test_get_item
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/items/1/2/3", anything, anything).returns( HTTP::Message.new_response("data") )
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    resp = store.get_item("/items/1/2/3")
    assert_equal(true, resp != nil)        
  end
  
  def test_get_item_with_conditional_get
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/items/1/2/3", nil, {"If-None-Match" => "abcdef"}).returns( HTTP::Message.new_response("data") )
    
    etags = Pho::Etags.new
    etags.add("http://api.talis.com/stores/testing/items/1/2/3", "abcdef")
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    resp = store.get_item("/items/1/2/3", etags)
    assert_equal(true, resp != nil)                
  end

  def test_get_item_with_if_match
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/items/1/2/3", nil, {"If-Match" => "abcdef"}).returns( HTTP::Message.new_response("data") )
    
    etags = Pho::Etags.new
    etags.add("http://api.talis.com/stores/testing/items/1/2/3", "abcdef")
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    resp = store.get_item("/items/1/2/3", etags, :ifmatch)
    assert_equal(true, resp != nil)     
               
  end
      
  def test_get_item_with_if_none_match_and_modified
    r = HTTP::Message.new_response("data")
    r.header["ETag"] = "zebra"
    
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/items/1/2/3", nil, {"If-None-Match" => "abcdef"}).returns( r )
    
    etags = Pho::Etags.new
    etags.add("http://api.talis.com/stores/testing/items/1/2/3", "abcdef")
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    resp = store.get_item("/items/1/2/3", etags)
    assert_equal(true, resp != nil)                
    assert_equal("zebra", etags.get("http://api.talis.com/stores/testing/items/1/2/3"))
  end
  
end
