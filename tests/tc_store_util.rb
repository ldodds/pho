$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'pho'
require 'test/unit'

class StoreUtilTest < Test::Unit::TestCase

  def test_build_uri
    store = Pho::Store.new("http://api.talis.com/stores/testing")
    
    assert_equal("http://api.talis.com/stores/testing/meta", store.build_uri("/meta") )
    assert_equal("http://api.talis.com/stores/testing/meta", store.build_uri("meta") )
    assert_equal("http://api.talis.com/stores/testing/meta", store.build_uri("http://api.talis.com/stores/testing/meta") )
  end
  
  def test_storename
    store = Pho::Store.new("http://api.talis.com/stores/testing")
    assert_equal("testing", store.name)
    store = Pho::Store.new("http://api.talis.com/stores/testing/")    
    assert_equal("testing", store.name)    
  end
end