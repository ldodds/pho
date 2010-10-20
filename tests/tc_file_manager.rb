$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'pho'
require 'test/unit'
require 'mocha'

class FileManagerTest < Test::Unit::TestCase

  def setup()
    Dir.mkdir("/tmp/pho") unless File.exists?("/tmp/pho")    
    Dir.mkdir("/tmp/pho/.pho") unless File.exists?("/tmp/pho/.pho")

    Dir.mkdir("/tmp/pho/a") unless File.exists?("/tmp/pho/a")    
    Dir.mkdir("/tmp/pho/b") unless File.exists?("/tmp/pho/b")        

    #/tmp/pho/[0-6].css
    7.times do |i|
      file = File.new( File.join("/tmp/pho", "#{i}.css"), "w" )
      file.write("CSS#{i}")
      file.close()
    end
    #/tmp/pho/[7-9].js
    3.times do |i|
      num = i + 7
      file = File.new( File.join("/tmp/pho", "#{num}.js"), "w" )
      file.write("JS#{num}")
      file.close()
    end
    #/tmp/pho/.pho/[0-3].ok
    4.times do |i|
      file = File.new( File.join("/tmp/pho/.pho", "#{i}.css.ok"), "w" )
      file.write("OK")
      file.close()      
    end
    #/tmp/pho/.pho/[4-6].fail
    3.times do |i|
      num = 4 + i
      file = File.new( File.join("/tmp/pho/.pho", "#{num}.css.fail"), "w" )
      file.write("FAIL")
      file.close()      
    end

    #/tmp/pho/a/[0-1].txt
    2.times do |i|
      num = i
      file = File.new( File.join("/tmp/pho/a", "#{num}.txt"), "w" )
      file.write("TXT#{num}")
      file.close()
    end

    #/tmp/pho/b/0.txt
    1.times do |i|
      num = i
      file = File.new( File.join("/tmp/pho/b", "#{num}.txt"), "w" )
      file.write("TXT#{num}")
      file.close()
    end
    
  end
  
  def teardown()
    Dir.glob("/tmp/pho/*.*") do |file|
      File.delete(file)
    end
    Dir.glob("/tmp/pho/.pho/*.*") do |file|
      File.delete(file)
    end
    Dir.glob("/tmp/pho/a/.pho/*.*") do |file|
      File.delete(file)
    end
    Dir.glob("/tmp/pho/b/.pho/*.*") do |file|
      File.delete(file)
    end
    Dir.glob("/tmp/pho/a/*.*") do |file|
      File.delete(file)
    end
    Dir.glob("/tmp/pho/b/*.*") do |file|
      File.delete(file)
    end
    
    delete("/tmp/pho/a/.pho")
    delete("/tmp/pho/b/.pho")
    delete("/tmp/pho/a")
    delete("/tmp/pho/b")
    delete("/tmp/pho/.pho")    
    delete("/tmp/pho")                        
  end
      
  def delete(dir)
    Dir.delete(dir) if File.exists?(dir)
  end
  
  def test_get_ok_file_for()
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass")    
    collection = Pho::FileManagement::FileManager.new(store, "/tmp/pho")
    assert_equal( "/tmp/pho/.pho/0.css.ok", collection.get_ok_file_for("/tmp/pho/0.css") )
    assert_equal( "/tmp/pho/a/.pho/0.txt.ok", collection.get_ok_file_for("/tmp/pho/a/0.txt") )    
  end

  def test_get_fail_file_for()    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass")    
    collection = Pho::FileManagement::FileManager.new(store, "/tmp/pho")
    assert_equal( "/tmp/pho/.pho/0.css.fail", collection.get_fail_file_for("/tmp/pho/0.css") )
    assert_equal( "/tmp/pho/a/.pho/0.txt.fail", collection.get_fail_file_for("/tmp/pho/a/0.txt") )    
  end
  
  def test_stored()
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass")    
    collection = Pho::FileManagement::FileManager.new(store, "/tmp/pho")
    7.times do |i|
      assert_equal( true, collection.stored?("/tmp/pho/#{i}.css"), "#{i}.css should be stored" )
    end
        
  end
      
  def test_changed()
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass")    
    collection = Pho::FileManagement::FileManager.new(store, "/tmp/pho")
    7.times do |i|
      assert_equal( false, collection.changed?("/tmp/pho/#{i}.css"), "#{i}.css should not be changed" )
    end    
    
    sleep(1)
    #check we're not creating it with the touch
    assert_equal( true, File.exists?("/tmp/pho/0.css") )
    FileUtils.touch( "/tmp/pho/0.css")    
    assert_equal( true, collection.changed?("/tmp/pho/0.css") )
    #other files are unchanged
    6.times do |i|
      assert_equal( false, collection.changed?("/tmp/pho/#{i+1}.css"), "#{i+1}.css should not be changed" )
    end    
    #untracked files are also changed
    3.times do |i|
      assert_equal( true, collection.changed?("/tmp/pho/#{i+7}.js"), "#{i+7}.js should not be changed" )
    end    
    
  end
  
  def test_changed_files()
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass")    
    collection = Pho::FileManagement::FileManager.new(store, "/tmp/pho")
    changed = collection.changed_files()
    assert_equal( 3, changed.size )
    
    sleep(1)
    #check we're not creating it with the touch
    assert_equal( true, File.exists?("/tmp/pho/0.css") )
    FileUtils.touch( "/tmp/pho/0.css")
        
    changed = collection.changed_files()
    changed.sort!
    assert_equal( 4, changed.size )
    assert_equal( "/tmp/pho/0.css", changed[0] )

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
      
      assert_equal(true, File.exists?("/tmp/pho/.pho/7.js.ok") )      
      assert_equal(true, File.exists?("/tmp/pho/.pho/8.js.ok") )
      assert_equal(true, File.exists?("/tmp/pho/.pho/9.js.ok") )
      
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
      
      assert_equal(true, File.exists?("/tmp/pho/.pho/7.js.ok") )      
      assert_equal(true, File.exists?("/tmp/pho/.pho/8.js.ok") )
      assert_equal(true, File.exists?("/tmp/pho/.pho/9.js.ok") )
      
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
      
      assert_equal(true, File.exists?("/tmp/pho/.pho/7.js.ok") )      
      assert_equal(true, File.exists?("/tmp/pho/.pho/8.js.ok") )
      assert_equal(true, File.exists?("/tmp/pho/.pho/9.js.ok") )
      assert_equal(true, File.exists?("/tmp/pho/a/.pho/0.txt.ok") )
      assert_equal(true, File.exists?("/tmp/pho/a/.pho/1.txt.ok") )
      assert_equal(true, File.exists?("/tmp/pho/b/.pho/0.txt.ok") )
      
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
  
  def test_reset()
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass")
    collection = Pho::FileManagement::FileManager.new(store, "/tmp/pho")
  
    collection.reset()
    newfiles = collection.new_files()
    assert_equal(10, newfiles.size)        
  end

  def test_reset_recursive()
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass")
    collection = Pho::FileManagement::FileManager.new(store, "/tmp/pho")
  
    Dir.mkdir("/tmp/pho/b/.pho") unless File.exists?("/tmp/pho/b/.pho")
    
    file = File.new( File.join("/tmp/pho/b/.pho", "0.txt.fail"), "w" )
    file.write("FAIL")
    file.close()      
    
    files = collection.failures(:recurse)
    assert_equal(4, files.size)        
    assert_equal( true, files.include?("/tmp/pho/b/0.txt") )
        
    collection.reset(:recurse)
    newfiles = collection.new_files(:recurse)
    assert_equal(13, newfiles.size)        
    assert_equal( true, newfiles.include?("/tmp/pho/b/0.txt") )
    
    files = collection.failures(:recurse)
    assert_equal(0, files.size)
    
    assert_equal( true, !File.exists?("/tmp/pho/b/.pho/0.txt.fail") )
  end    
end
