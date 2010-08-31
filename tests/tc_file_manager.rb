$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'pho'
require 'test/unit'
require 'mocha'

class FileManagerTest < Test::Unit::TestCase

  def setup()
    Dir.mkdir("/tmp/pho") unless File.exists?("/tmp/pho")
    Dir.mkdir("/tmp/pho/a") unless File.exists?("/tmp/pho/a")
    Dir.mkdir("/tmp/pho/b") unless File.exists?("/tmp/pho/b")
    7.times do |i|
      file = File.new( File.join("/tmp/pho", "#{i}.css"), "w" )
      file.write("CSS#{i}")
      file.close()
    end
    3.times do |i|
      num = i + 7
      file = File.new( File.join("/tmp/pho", "#{num}.js"), "w" )
      file.write("JS#{num}")
      file.close()
    end
    4.times do |i|
      file = File.new( File.join("/tmp/pho", "#{i}.ok"), "w" )
      file.write("OK")
      file.close()      
    end
    3.times do |i|
      num = 4 + i
      file = File.new( File.join("/tmp/pho", "#{num}.fail"), "w" )
      file.write("FAIL")
      file.close()      
    end

    #/tmp/pho/a
    2.times do |i|
      num = i
      file = File.new( File.join("/tmp/pho/a", "#{num}.txt"), "w" )
      file.write("TXT#{num}")
      file.close()
    end

    #/tmp/pho/b
    1.times do |i|
      num = i
      file = File.new( File.join("/tmp/pho/b", "#{num}.txt"), "w" )
      file.write("TXT#{num}")
      file.close()
    end
    
  end
  
  def teardown()
    Dir.glob("/tmp/pho/*.css") do |file|
      File.delete(file)
    end
    Dir.glob("/tmp/pho/*.js") do |file|
      File.delete(file)
    end    
    Dir.glob("/tmp/pho/**/*.ok") do |file|
      File.delete(file)
    end
    Dir.glob("/tmp/pho/**/*.fail") do |file|
      File.delete(file)
    end
    Dir.glob("/tmp/pho/**/*.txt") do |file|
      File.delete(file)
    end                    
  end
      
  def test_new_files()
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass")
    collection = Pho::FileManagement::FileManager.new(store, "/tmp/pho")

    newfiles = collection.new_files()
    newfiles.sort!
    assert_equal(3, newfiles.size)
    assert_equal("/tmp/pho/7.js", newfiles[0])    
    assert_equal("/tmp/pho/8.js", newfiles[1])
    assert_equal("/tmp/pho/9.js", newfiles[2])
        
  end        
  
  def test_new_files_recursive()
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass")
    collection = Pho::FileManagement::FileManager.new(store, "/tmp/pho")

    newfiles = collection.new_files(:recurse)
    newfiles.sort!
    
    assert_equal(6, newfiles.size)
    assert_equal("/tmp/pho/7.js", newfiles[0])    
    assert_equal("/tmp/pho/8.js", newfiles[1])
    assert_equal("/tmp/pho/9.js", newfiles[2])
    assert_equal("/tmp/pho/a/0.txt", newfiles[3])
    assert_equal("/tmp/pho/a/1.txt", newfiles[4])
    assert_equal("/tmp/pho/b/0.txt", newfiles[5])
        
  end 

  def test_store()
      mc = mock()
      mc.expects(:set_auth)
      #mc.stub_everything()      
      mc.expects(:put).with("http://api.talis.com/stores/testing/items/7.js", "JS7", {"Content-Type" => "application/javascript"}).returns( HTTP::Message.new_response("OK"))
      mc.expects(:put).with("http://api.talis.com/stores/testing/items/8.js", "JS8", {"Content-Type" => "application/javascript"}).returns( HTTP::Message.new_response("OK"))
      mc.expects(:put).with("http://api.talis.com/stores/testing/items/9.js", "JS9", {"Content-Type" => "application/javascript"}).returns( HTTP::Message.new_response("OK"))
      
      store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)      
      collection = Pho::FileManagement::FileManager.new(store, "/tmp/pho")
      collection.store()
      
      assert_equal(true, File.exists?("/tmp/pho/7.ok") )      
      assert_equal(true, File.exists?("/tmp/pho/8.ok") )
      assert_equal(true, File.exists?("/tmp/pho/9.ok") )
      
  end

  def test_store_with_base()
      mc = mock()
      mc.expects(:set_auth)
      #mc.stub_everything()      
      mc.expects(:put).with("http://api.talis.com/stores/testing/items/assets/7.js", "JS7", {"Content-Type" => "application/javascript"}).returns( HTTP::Message.new_response("OK"))
      mc.expects(:put).with("http://api.talis.com/stores/testing/items/assets/8.js", "JS8", {"Content-Type" => "application/javascript"}).returns( HTTP::Message.new_response("OK"))
      mc.expects(:put).with("http://api.talis.com/stores/testing/items/assets/9.js", "JS9", {"Content-Type" => "application/javascript"}).returns( HTTP::Message.new_response("OK"))
      
      store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)      
      collection = Pho::FileManagement::FileManager.new(store, "/tmp/pho", "assets")
      collection.store()
      
      assert_equal(true, File.exists?("/tmp/pho/7.ok") )      
      assert_equal(true, File.exists?("/tmp/pho/8.ok") )
      assert_equal(true, File.exists?("/tmp/pho/9.ok") )
      
  end

          
  def test_store_recursive()
      mc = mock()
      mc.expects(:set_auth)
      #mc.stub_everything()      
      mc.expects(:put).with("http://api.talis.com/stores/testing/items/7.js", "JS7", {"Content-Type" => "application/javascript"}).returns( HTTP::Message.new_response("OK"))
      mc.expects(:put).with("http://api.talis.com/stores/testing/items/8.js", "JS8", {"Content-Type" => "application/javascript"}).returns( HTTP::Message.new_response("OK"))
      mc.expects(:put).with("http://api.talis.com/stores/testing/items/9.js", "JS9", {"Content-Type" => "application/javascript"}).returns( HTTP::Message.new_response("OK"))
      mc.expects(:put).with("http://api.talis.com/stores/testing/items/a/0.txt", "TXT0", {"Content-Type" => "text/plain"}).returns( HTTP::Message.new_response("OK"))
      mc.expects(:put).with("http://api.talis.com/stores/testing/items/a/1.txt", "TXT1", {"Content-Type" => "text/plain"}).returns( HTTP::Message.new_response("OK"))
      mc.expects(:put).with("http://api.talis.com/stores/testing/items/b/0.txt", "TXT0", {"Content-Type" => "text/plain"}).returns( HTTP::Message.new_response("OK"))
      
      store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)      
      collection = Pho::FileManagement::FileManager.new(store, "/tmp/pho")
      collection.store(:recursive)
      
      assert_equal(true, File.exists?("/tmp/pho/7.ok") )      
      assert_equal(true, File.exists?("/tmp/pho/8.ok") )
      assert_equal(true, File.exists?("/tmp/pho/9.ok") )
      assert_equal(true, File.exists?("/tmp/pho/a/0.ok") )
      assert_equal(true, File.exists?("/tmp/pho/a/1.ok") )
      assert_equal(true, File.exists?("/tmp/pho/b/0.ok") )
      
  end
  
  def test_list()
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass")
    collection = Pho::FileManagement::FileManager.new(store, "/tmp/pho")

    files = collection.list()
    assert_equal(10, files.size)    
  end
              
  def test_list_recursive()
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass")
    collection = Pho::FileManagement::FileManager.new(store, "/tmp/pho")

    files = collection.list(:recurse)
    assert_equal(13, files.size)
  end
  
end
