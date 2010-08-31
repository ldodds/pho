$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'pho'
require 'test/unit'
require 'yaml'
class EtagsTest < Test::Unit::TestCase
  
  def test_it()
  
    io = StringIO.new("---\n- http://www.example.org : '12345'")
    etags = Pho::Etags.new(io)
    
    assert_equal(true, etags.has_tag?("http://www.example.org") )
    assert_equal("12345", etags.get("http://www.example.org") )
    
    etags.add("http://www.example.com/foo", "abc")
    assert_equal(false, etags.saved)
    
    etags.save()
    
  end

  def test_overwrite()
    etags = Pho::Etags.new()
    etags.add("http://www.example.org", "etag")
    assert_equal("etag", etags.get("http://www.example.org") )
    etags.add("http://www.example.org", "etag_updated")
    assert_equal("etag_updated", etags.get("http://www.example.org") )
  end  
  
  def test_add_from_response()
    response = HTTP::Message.new_response("description")
    response.header["ETag"] = "abcdef"
    etags = Pho::Etags.new()
    etags.add_from_response("http://www.example.org", response)
    assert_equal("abcdef", etags.get("http://www.example.org") )    
  end
  
end