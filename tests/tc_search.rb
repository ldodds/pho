$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'pho'
require 'test/unit'
require 'mocha'

class SearchTest < Test::Unit::TestCase
  
  def test_simple_search
    mc = mock()
    mc.stub_everything()
    mc.expects(:get).with("http://api.talis.com/stores/testing/items", {"query" => "lunar"})
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    s = store.search("lunar")       
  end
  
  def test_parameter_search
    mc = mock()
    mc.stub_everything()
    mc.expects(:get).with("http://api.talis.com/stores/testing/items", {"query" => "lunar", "max" => "50", "offset" => "10"})
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    s = store.search("lunar", {"max" => "50", "offset" => "10"})          
  end
  
  def test_facet
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/services/facet", {"query" => "lunar", "fields" => "name,agency"})
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    s = store.facet("lunar", ["name", "agency"] )
  end
  
  def test_augment_uri
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/services/augment", {"data-uri" => "http://www.example.org/index.rss"})
      
     
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    response = store.augment_uri("http://www.example.org/index.rss")    
  end
  
  def test_augment
     mc = mock()
     mc.expects(:set_auth)
     mc.expects(:post).with("http://api.talis.com/stores/testing/services/augment", "data", anything)
     
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    response = store.augment("data")    
              
  end
end