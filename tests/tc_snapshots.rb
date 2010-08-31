$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'pho'
require 'test/unit'
require 'mocha'
require 'tmpdir'

class SnapshotsTest < Test::Unit::TestCase

  SNAPSHOT = <<-EOL      
<rdf:RDF
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:j.0="http://schemas.talis.com/2006/bigfoot/configuration#" > 
  <rdf:Description rdf:about="http://api.talis.com/stores/testing">
    <j.0:snapshot rdf:resource="http://api.talis.com/stores/testing/snapshots/20090222113727.tar"/>
  </rdf:Description>
  <rdf:Description rdf:about="http://api.talis.com/stores/testing/snapshots/20090222113727.tar">
    <j.0:md5 rdf:resource="http://api.talis.com/stores/testing/snapshots/20090222113727.tar.md5"/>
    <j.0:filesize>30 KB</j.0:filesize>
    <dc:date>11:37 22-February-2009</dc:date>
  </rdf:Description>    
</rdf:RDF>
EOL
    
  EMPTY = <<-EOL
  <rdf:RDF
      xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" > 
  </rdf:RDF>  
EOL

  def teardown()
    
    f = File.join(Dir.tmpdir, "2009022213727.tar")
    if File.exists?(f)
      File.delete(f)
    end
    
  end

  def test_get_snapshots()
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/snapshots", nil, Pho::ACCEPT_RDF)
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    response = store.get_snapshots()        
  end  
  
  def test_read_from_store()
    
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/snapshots", 
      anything, {"Accept" => "application/rdf+xml"}).returns(
      HTTP::Message.new_response(SNAPSHOT) )
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)  
        
    snapshot = Pho::Snapshot.read_from_store(store)

    assert_equal("http://api.talis.com/stores/testing/snapshots/20090222113727.tar", snapshot.url)
    assert_equal("http://api.talis.com/stores/testing/snapshots/20090222113727.tar.md5", snapshot.md5_url)
    assert_equal("30", snapshot.size)
    assert_equal("KB", snapshot.units)
        
  end
  
  def test_parse()
                
      snapshot = Pho::Snapshot.parse("http://api.talis.com/stores/testing", SNAPSHOT)
      
      assert_equal(true, snapshot != nil)
    
      assert_equal("http://api.talis.com/stores/testing/snapshots/20090222113727.tar", snapshot.url)
      assert_equal("http://api.talis.com/stores/testing/snapshots/20090222113727.tar.md5", snapshot.md5_url)
      assert_equal("30", snapshot.size)
      assert_equal("KB", snapshot.units)
  end
               
  def test_read_from_store_raises_exception()

    msg = HTTP::Message.new_response("")
    msg.status = 500    
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/snapshots", 
      anything, {"Accept" => "application/rdf+xml"}).returns( msg )
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)  
        
    assert_raise RuntimeError do
      snapshot = Pho::Snapshot.read_from_store(store)    end
        
  end  
  
  def test_backup()
    
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get_content).with("http://api.talis.com/stores/test-store/snapshots/20090222113727.tar.md5").returns("4880c0340c65d142838ea33ace9b850a")
    mc.expects(:get_content).with("http://api.talis.com/stores/test-store/snapshots/20090222113727.tar").returns("12345abcdef")    
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    
    snapshot = Pho::Snapshot.new("http://api.talis.com/stores/test-store/snapshots/20090222113727.tar", "http://api.talis.com/stores/test-store/snapshots/20090222113727.tar.md5", "1", "KB", "11:37 22-February-2009")
    
    snapshot.backup(store, Dir.tmpdir)
        
    assert_equal(true, File.exists?( File.join(Dir.tmpdir, "20090222113727.tar" ) ) )        
  end
  
  def test_empty_response()
    snapshot = Pho::Snapshot.parse("http://api.talis.com/stores/testing", EMPTY)
    
    assert_nil( snapshot )
 
  end
  
end