$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'pho'
require 'test/unit'
require 'mocha'

#TODO factor out tests for AbstractFileManager
class RDFCollectionTest < Test::Unit::TestCase

  def setup()
    10.times do |i|
      file = File.new( File.join("/tmp", "#{i}.rdf"), "w" )
      file.write("RDF#{i}")
      file.close()
    end
    4.times do |i|
      file = File.new( File.join("/tmp", "#{i}.ok"), "w" )
      file.write("OK")
      file.close()      
    end
    3.times do |i|
      num = 4 + i
      file = File.new( File.join("/tmp", "#{num}.fail"), "w" )
      file.write("FAIL")
      file.close()      
    end
    3.times do |i|
      num = 10 + i
      file = File.new( File.join("/tmp", "#{num}.ttl"), "w" )
      file.write("TTL#{num}")
      file.close()       
    end    
  end
  
  def teardown()
    Dir.glob("/tmp/*.rdf") do |file|
      File.delete(file)
    end
    Dir.glob("/tmp/*.ok") do |file|
      File.delete(file)
    end
    Dir.glob("/tmp/*.fail") do |file|
      File.delete(file)
    end        
    Dir.glob("/tmp/*.ttl") do |file|
      File.delete(file)
    end         
  end
  
  def test_get_fail_file_for()
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass")
    collection = Pho::FileManagement::RDFManager.new(store, "/tmp", ["rdf"])
    
    assert_equal("foo.fail", collection.get_fail_file_for("foo.rdf") )    
  end

  def test_get_fail_file_for_with_ext_in_path()
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass")
    collection = Pho::FileManagement::RDFManager.new(store, "/tmp/rdf", ["rdf"])
    
    assert_equal("/tmp/rdf/foo.fail", collection.get_fail_file_for("/tmp/rdf/foo.rdf") )    
  end
    
  def test_get_ok_file_for()
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass")
    collection = Pho::FileManagement::RDFManager.new(store, "/tmp", ["rdf"])
    
    assert_equal("foo.ok", collection.get_ok_file_for("foo.rdf") )    
  end  

  def test_get_ok_file_for_with_ext_in_path()
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass")
    collection = Pho::FileManagement::RDFManager.new(store, "/tmp/js", ["rdf"])
    
    assert_equal("/tmp/js/foo.ok", collection.get_ok_file_for("/tmp/js/foo.js") )    
  end  
    

  def test_successes()
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass")
    collection = Pho::FileManagement::RDFManager.new(store, "/tmp", ["rdf"])

    success = collection.successes()
    success.sort!

    assert_equal(4, success.size)
    assert_equal("/tmp/0.rdf", success[0])    
    assert_equal("/tmp/1.rdf", success[1])
    assert_equal("/tmp/2.rdf", success[2])
    assert_equal("/tmp/3.rdf", success[3])
  end

  def test_failures()
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass")
    collection = Pho::FileManagement::RDFManager.new(store, "/tmp", ["rdf"])

    fails = collection.failures()
    fails.sort!
    assert_equal(3, fails.size)
    assert_equal("/tmp/4.rdf", fails[0])    
    assert_equal("/tmp/5.rdf", fails[1])
    assert_equal("/tmp/6.rdf", fails[2])
  end
  
  def test_new_files()
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass")
    collection = Pho::FileManagement::RDFManager.new(store, "/tmp", ["rdf"])

    newfiles = collection.new_files()
    newfiles.sort!
    assert_equal(3, newfiles.size)
    assert_equal("/tmp/7.rdf", newfiles[0])    
    assert_equal("/tmp/8.rdf", newfiles[1])
    assert_equal("/tmp/9.rdf", newfiles[2])        
  end        

  def test_new_files_all_serializations()
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass")
    collection = Pho::FileManagement::RDFManager.new(store, "/tmp")

    newfiles = collection.new_files()
    newfiles.sort!
    assert_equal(6, newfiles.size)
    assert_equal("/tmp/10.ttl", newfiles[0])
    assert_equal("/tmp/11.ttl", newfiles[1])
    assert_equal("/tmp/12.ttl", newfiles[2])
    assert_equal("/tmp/7.rdf", newfiles[3])    
    assert_equal("/tmp/8.rdf", newfiles[4])
    assert_equal("/tmp/9.rdf", newfiles[5])        
  end        
      
  def test_store()
      mc = mock()
      mc.stub_everything()
      mc.expects(:post).with("http://api.talis.com/stores/testing/meta", "RDF7", {"Content-Type" => "application/rdf+xml"}).returns( HTTP::Message.new_response("OK"))
      mc.expects(:post).with("http://api.talis.com/stores/testing/meta", "RDF8", {"Content-Type" => "application/rdf+xml"}).returns( HTTP::Message.new_response("OK"))
      mc.expects(:post).with("http://api.talis.com/stores/testing/meta", "RDF9", {"Content-Type" => "application/rdf+xml"}).returns( HTTP::Message.new_response("OK"))
      
      store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)      
      collection = Pho::FileManagement::RDFManager.new(store, "/tmp", ["rdf"])
      collection.store()
      
      assert_equal(true, File.exists?("/tmp/7.ok") )      
      assert_equal(true, File.exists?("/tmp/8.ok") )
      assert_equal(true, File.exists?("/tmp/9.ok") )
      
  end

  def test_store_turtle()
      mc = mock()
      #mc.stub_everything()
      mc.expects(:set_auth)
      mc.expects(:post).with("http://api.talis.com/stores/testing/meta", "TTL10", {"Content-Type" => "text/turtle"}).returns( HTTP::Message.new_response("OK") )
      mc.expects(:post).with("http://api.talis.com/stores/testing/meta", "TTL11", {"Content-Type" => "text/turtle"}).returns( HTTP::Message.new_response("OK") )
      mc.expects(:post).with("http://api.talis.com/stores/testing/meta", "TTL12", {"Content-Type" => "text/turtle"}).returns( HTTP::Message.new_response("OK") )
      
      store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
      collection = Pho::FileManagement::RDFManager.new(store, "/tmp", ["ttl"])
      collection.store()
            
      assert_equal(true, File.exists?("/tmp/10.ok") )
      assert_equal(true, File.exists?("/tmp/11.ok") )
      assert_equal(true, File.exists?("/tmp/12.ok") )
  end
      
  def test_store_all_serializations()
      mc = mock()
      #mc.stub_everything()
      mc.expects(:set_auth)
      mc.expects(:post).with("http://api.talis.com/stores/testing/meta", "TTL10", {"Content-Type" => "text/turtle"}).returns( HTTP::Message.new_response("OK") )
      mc.expects(:post).with("http://api.talis.com/stores/testing/meta", "TTL11", {"Content-Type" => "text/turtle"}).returns( HTTP::Message.new_response("OK") )
      mc.expects(:post).with("http://api.talis.com/stores/testing/meta", "TTL12", {"Content-Type" => "text/turtle"}).returns( HTTP::Message.new_response("OK") )
      mc.expects(:post).with("http://api.talis.com/stores/testing/meta", "RDF7", {"Content-Type" => "application/rdf+xml"}).returns( HTTP::Message.new_response("OK"))
      mc.expects(:post).with("http://api.talis.com/stores/testing/meta", "RDF8", {"Content-Type" => "application/rdf+xml"}).returns( HTTP::Message.new_response("OK"))
      mc.expects(:post).with("http://api.talis.com/stores/testing/meta", "RDF9", {"Content-Type" => "application/rdf+xml"}).returns( HTTP::Message.new_response("OK"))
      
      store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
      collection = Pho::FileManagement::RDFManager.new(store, "/tmp")
      collection.store()
            
      assert_equal(true, File.exists?("/tmp/10.ok") )
      assert_equal(true, File.exists?("/tmp/11.ok") )
      assert_equal(true, File.exists?("/tmp/12.ok") )
      assert_equal(true, File.exists?("/tmp/7.ok") )      
      assert_equal(true, File.exists?("/tmp/8.ok") )
      assert_equal(true, File.exists?("/tmp/9.ok") )
      
  end
    
  def test_reset()
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass")
    collection = Pho::FileManagement::RDFManager.new(store, "/tmp", ["rdf"])

    collection.reset()
    newfiles = collection.new_files()
    assert_equal(10, newfiles.size)        
  end
  
  def test_list()
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass")
    collection = Pho::FileManagement::RDFManager.new(store, "/tmp", ["rdf"])

    files = collection.list()
    assert_equal(10, files.size)    
  end
  
  def test_summary()
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass")
    collection = Pho::FileManagement::RDFManager.new(store, "/tmp", ["rdf"])
  end
            
end

