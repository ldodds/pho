$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'pho'
require 'test/unit'
require 'mocha'

class MetaboxTest < Test::Unit::TestCase

  def test_constructor
      mc = mock()
      mc.expects(:set_auth).with("http://api.talis.com/stores/testing", "user", "pass")
      store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
      assert_equal(mc, store.client)
      assert_equal("http://api.talis.com/stores/testing", store.storeuri)
      assert_equal("user", store.username)
  end  
  
  def test_store_data
     mc = mock()
     mc.expects(:set_auth)
     mc.expects(:post).with("http://api.talis.com/stores/testing/meta", "data", {"Content-Type" => "application/rdf+xml"} )
     store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
     store.store_data("data")
  end

  def test_store_data_as_turtle
     mc = mock()
     mc.expects(:set_auth)
     mc.expects(:post).with("http://api.talis.com/stores/testing/meta", "data", {"Content-Type" => "text/turtle"} )
     store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
     store.store_data("data", nil, "text/turtle")
  end

  def test_store_data_as_ntriples
     mc = mock()
     mc.expects(:set_auth)
     mc.expects(:post).with("http://api.talis.com/stores/testing/meta", "data", {"Content-Type" => "text/turtle"} )
     store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
     store.store_data("data", nil, "text/plain")
  end
  
      
  def test_store_data_in_graph
     mc = mock()
     mc.expects(:set_auth)
     mc.expects(:post).with("http://api.talis.com/stores/testing/meta/graphs/1", "data", {"Content-Type" => "application/rdf+xml"} )
     store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
     store.store_data("data", "1")     
  end
      
  def test_store_file
     mc = mock()
     mc.expects(:set_auth)
     mc.expects(:post).with("http://api.talis.com/stores/testing/meta", "data", {"Content-Type" => "application/rdf+xml"} )
     
     store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
     io = StringIO.new("data")
     store.store_file( io )
     assert_equal(true, io.closed?)     
  end

  def test_store_file_turtle
     mc = mock()
     mc.expects(:set_auth)
     mc.expects(:post).with("http://api.talis.com/stores/testing/meta", "data", {"Content-Type" => "text/turtle"} )
     
     store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
     io = StringIO.new("data")
     store.store_file( io, nil, "text/turtle" )
     assert_equal(true, io.closed?)     
  end
    
  def test_store_url
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://www.example.org", nil, {"Accept" => "application/rdf+xml"}).returns( HTTP::Message.new_response("data") )
    mc.expects(:post).with("http://api.talis.com/stores/testing/meta", "data", {"Content-Type" => "application/rdf+xml"} )  
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    store.store_url( "http://www.example.org" )
  end

  def test_store_url_in_graph
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://www.example.org", nil, {"Accept" => "application/rdf+xml"}).returns( HTTP::Message.new_response("data") )
    mc.expects(:post).with("http://api.talis.com/stores/testing/meta/graphs/1", "data", {"Content-Type" => "application/rdf+xml"} )  
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    store.store_url( "http://www.example.org", nil, "1" )
  end
      
  def test_describe_with_default_mimetype
     mc = mock()
     mc.expects(:set_auth)
     mc.expects(:get).with("http://api.talis.com/stores/testing/meta", {"about" => "http://www.example.org"}, {"Accept" => "application/rdf+xml"}).returns(
       HTTP::Message.new_response("description") )
       
     store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
     response = store.describe("http://www.example.org")
     assert_equal("description", response.content)
  end

  def test_describe_with_json    
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/meta", {"about" => "http://www.example.org"}, {"Accept" => "application/json"}).returns(
    HTTP::Message.new_response("description"))
      
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    response = store.describe("http://www.example.org", "application/json")
    assert_equal("description", response.content)
  end
  
  def test_describe_with_conditional_get
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/meta", {"about" => "http://www.example.org"}, 
      {"Accept" => "application/rdf+xml", "If-None-Match" => "1234"}).returns( HTTP::Message.new_response("description") )
    
    etags = Pho::Etags.new()
    etags.add("http://api.talis.com/stores/testing/meta?about=http://www.example.org", "1234")
      
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    response = store.describe("http://www.example.org", "application/rdf+xml", etags)
    assert_equal("description", response.content)
    
  end    

  def test_describe_with_if_match
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/meta", {"about" => "http://www.example.org"}, 
      {"Accept" => "application/rdf+xml", "If-Match" => "1234"}).returns( HTTP::Message.new_response("description") )
    
    etags = Pho::Etags.new()
    etags.add("http://api.talis.com/stores/testing/meta?about=http://www.example.org", "1234")
      
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    response = store.describe("http://www.example.org", "application/rdf+xml", etags, :ifmatch)
    assert_equal("description", response.content)
    
  end    
    
  def test_describe_with_if_none_match_and_changed
    r = HTTP::Message.new_response("description")
    r.header["ETag"] = "abcdef"
    
    mc = mock()
    mc.expects(:set_auth)    
    mc.expects(:get).with("http://api.talis.com/stores/testing/meta", {"about" => "http://www.example.org"},      
      {"Accept" => "application/rdf+xml", "If-None-Match" => "1234"}).returns( r )
    
    etags = Pho::Etags.new
    etags.add("http://api.talis.com/stores/testing/meta?about=http://www.example.org", "1234")
    
    #etags = mock()
    #etags.stub_everything
    #etags.expects(:has_tag?).with("http://api.talis.com/stores/testing/meta?about=http://www.example.org").returns(true)
    #etags.expects(:get).with("http://api.talis.com/stores/testing/meta?about=http://www.example.org").returns("1234")
    #etags.expects(:add).with("http://api.talis.com/stores/testing/meta?about=http://www.example.org", "abcdef")
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    response = store.describe("http://www.example.org", "application/rdf+xml", etags)

    assert_equal("description", response.content)
    assert_equal("abcdef", etags.get("http://api.talis.com/stores/testing/meta?about=http://www.example.org"))
    
  end
  
end