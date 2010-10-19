$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'pho'
require 'test/unit'
require 'mocha'

#TODO factor out tests for AbstractFileManager
class RDFCollectionTest < Test::Unit::TestCase

  def setup()    
    Dir.mkdir("/tmp/rdf") unless File.exists?("/tmp/rdf")        
    10.times do |i|
      file = File.new( File.join("/tmp/rdf", "#{i}.rdf"), "w" )
      file.write("RDF#{i}")
      file.close()
    end
    Dir.mkdir("/tmp/rdf/.pho") unless File.exists?("/tmp/rdf/.pho")    
    4.times do |i|
      file = File.new( File.join("/tmp/rdf/.pho", "#{i}.rdf.ok"), "w" )
      file.write("OK")
      file.close()      
    end
    3.times do |i|
      num = 4 + i
      file = File.new( File.join("/tmp/rdf/.pho", "#{num}.rdf.fail"), "w" )
      file.write("FAIL")
      file.close()      
    end
    3.times do |i|
      num = 10 + i
      file = File.new( File.join("/tmp/rdf", "#{num}.ttl"), "w" )
      file.write("TTL#{num}")
      file.close()       
    end    
  end
  
  def teardown()
    Dir.glob("/tmp/rdf/*.rdf") do |file|
      File.delete(file)
    end
    Dir.glob("/tmp/rdf/.pho/*.*") do |file|
      File.delete(file)
    end
    Dir.glob("/tmp/rdf/*.ttl") do |file|
      File.delete(file)
    end
    delete("/tmp/rdf/.pho")  
    delete("/tmp/rdf")

  end
  
  def delete(dir)
    Dir.delete(dir) if File.exists?(dir)
  end
    
  def test_get_fail_file_for()
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass")
    collection = Pho::FileManagement::RDFManager.new(store, "/tmp/rdf", ["rdf"])
    
    assert_equal("/tmp/rdf/.pho/foo.rdf.fail", collection.get_fail_file_for("/tmp/rdf/foo.rdf") )    
  end

  def test_get_ok_file_for()
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass")
    collection = Pho::FileManagement::RDFManager.new(store, "/tmp/rdf", ["rdf"])
    
    assert_equal("/tmp/rdf/.pho/foo.rdf.ok", collection.get_ok_file_for("/tmp/rdf/foo.rdf") )    
  end  

  def test_stored()
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass")    
    collection = Pho::FileManagement::RDFManager.new(store, "/tmp/rdf", ["rdf"])
    7.times do |i|
      assert_equal( true, collection.stored?("/tmp/rdf/#{i}.rdf"), "#{i}.rdf should be stored" )
    end        
  end

    
  def test_successes()
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass")
    collection = Pho::FileManagement::RDFManager.new(store, "/tmp/rdf", ["rdf"])

    success = collection.successes()
    success.sort!

    assert_equal(4, success.size)
    assert_equal("/tmp/rdf/0.rdf", success[0])    
    assert_equal("/tmp/rdf/1.rdf", success[1])
    assert_equal("/tmp/rdf/2.rdf", success[2])
    assert_equal("/tmp/rdf/3.rdf", success[3])
  end

  def test_failures()
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass")
    collection = Pho::FileManagement::RDFManager.new(store, "/tmp/rdf", ["rdf"])

    fails = collection.failures()
    fails.sort!
    assert_equal(3, fails.size)
    assert_equal("/tmp/rdf/4.rdf", fails[0])    
    assert_equal("/tmp/rdf/5.rdf", fails[1])
    assert_equal("/tmp/rdf/6.rdf", fails[2])
  end
  
  def test_new_files()
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass")
    collection = Pho::FileManagement::RDFManager.new(store, "/tmp/rdf", ["rdf"])

    newfiles = collection.new_files()
    newfiles.sort!
    assert_equal(3, newfiles.size)
    assert_equal("/tmp/rdf/7.rdf", newfiles[0])    
    assert_equal("/tmp/rdf/8.rdf", newfiles[1])
    assert_equal("/tmp/rdf/9.rdf", newfiles[2])        
  end        

  def test_new_files_all_serializations()
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass")
    collection = Pho::FileManagement::RDFManager.new(store, "/tmp/rdf")

    newfiles = collection.new_files()
    newfiles.sort!
    assert_equal(6, newfiles.size)
    assert_equal("/tmp/rdf/10.ttl", newfiles[0])
    assert_equal("/tmp/rdf/11.ttl", newfiles[1])
    assert_equal("/tmp/rdf/12.ttl", newfiles[2])
    assert_equal("/tmp/rdf/7.rdf", newfiles[3])    
    assert_equal("/tmp/rdf/8.rdf", newfiles[4])
    assert_equal("/tmp/rdf/9.rdf", newfiles[5])        
  end        
      
  def test_store()
      mc = mock()
      mc.stub_everything()
      mc.expects(:post).with("http://api.talis.com/stores/testing/meta", "RDF7", {"Content-Type" => "application/rdf+xml"}).returns( HTTP::Message.new_response("OK"))
      mc.expects(:post).with("http://api.talis.com/stores/testing/meta", "RDF8", {"Content-Type" => "application/rdf+xml"}).returns( HTTP::Message.new_response("OK"))
      mc.expects(:post).with("http://api.talis.com/stores/testing/meta", "RDF9", {"Content-Type" => "application/rdf+xml"}).returns( HTTP::Message.new_response("OK"))
      
      store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)      
      collection = Pho::FileManagement::RDFManager.new(store, "/tmp/rdf", ["rdf"])
      collection.store()
      
      assert_equal(true, File.exists?("/tmp/rdf/.pho/7.rdf.ok") )      
      assert_equal(true, File.exists?("/tmp/rdf/.pho/8.rdf.ok") )
      assert_equal(true, File.exists?("/tmp/rdf/.pho/9.rdf.ok") )
      
  end

  def test_store_turtle()
      mc = mock()
      #mc.stub_everything()
      mc.expects(:set_auth)
      mc.expects(:post).with("http://api.talis.com/stores/testing/meta", "TTL10", {"Content-Type" => "text/turtle"}).returns( HTTP::Message.new_response("OK") )
      mc.expects(:post).with("http://api.talis.com/stores/testing/meta", "TTL11", {"Content-Type" => "text/turtle"}).returns( HTTP::Message.new_response("OK") )
      mc.expects(:post).with("http://api.talis.com/stores/testing/meta", "TTL12", {"Content-Type" => "text/turtle"}).returns( HTTP::Message.new_response("OK") )
      
      store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
      collection = Pho::FileManagement::RDFManager.new(store, "/tmp/rdf", ["ttl"])
      collection.store()
            
      assert_equal(true, File.exists?("/tmp/rdf/.pho/10.ttl.ok") )
      assert_equal(true, File.exists?("/tmp/rdf/.pho/11.ttl.ok") )
      assert_equal(true, File.exists?("/tmp/rdf/.pho/12.ttl.ok") )
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
      collection = Pho::FileManagement::RDFManager.new(store, "/tmp/rdf")
      collection.store()
            
      assert_equal(true, File.exists?("/tmp/rdf/.pho/10.ttl.ok") )
      assert_equal(true, File.exists?("/tmp/rdf/.pho/11.ttl.ok") )
      assert_equal(true, File.exists?("/tmp/rdf/.pho/12.ttl.ok") )
      assert_equal(true, File.exists?("/tmp/rdf/.pho/7.rdf.ok") )      
      assert_equal(true, File.exists?("/tmp/rdf/.pho/8.rdf.ok") )
      assert_equal(true, File.exists?("/tmp/rdf/.pho/9.rdf.ok") )
      
  end
    
  def test_reset()
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass")
    collection = Pho::FileManagement::RDFManager.new(store, "/tmp/rdf", ["rdf"])

    collection.reset()
    newfiles = collection.new_files()
    assert_equal(10, newfiles.size)        
  end
  
  def test_list()
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass")
    collection = Pho::FileManagement::RDFManager.new(store, "/tmp/rdf", ["rdf"])

    files = collection.list()
    assert_equal(10, files.size)    
  end
  
  def test_summary()
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass")
    collection = Pho::FileManagement::RDFManager.new(store, "/tmp/rdf", ["rdf"])
  end
            
end

