$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'pho'
require 'test/unit'
require 'mocha'

class FileSplitterTest < Test::Unit::TestCase
  
  def setup()
    Dir.mkdir("/tmp/pho") unless File.exists?("/tmp/pho")
    Dir.mkdir("/tmp/pho/split") unless File.exists?("/tmp/pho/split")
    Dir.mkdir("/tmp/pho/split/tmp") unless File.exists?("/tmp/pho/split/tmp")
    
    RDF::Writer.open("/tmp/pho/split/large.nt") do |writer|
      31.times do 
        writer << RDF::Statement.new( 
          RDF::Resource.new("http://www.example.org"), 
          RDF::RDFS.label,
          RDF::Literal.new("This is a test")
          )
      end      
    end
    
  end
  
  def teardown()
    Dir.glob("/tmp/pho/split/tmp/*.*") do |file|
      File.delete(file)
    end    
    Dir.glob("/tmp/pho/split/*.*") do |file|
      File.delete(file)
    end    
    delete("/tmp/pho/split/tmp")
    delete("/tmp/pho/split")
  end
  
  def delete(dir)
    Dir.delete(dir) if File.exists?(dir)
  end
  
  def test_split_file()
    splitter = Pho::FileManagement::FileSplitter.new("/tmp/pho/split/tmp", 10)
    splitter.split_file("/tmp/pho/split/large.nt")
    assert_equal(4, Dir.glob("/tmp/pho/split/tmp/large*.nt").size )
    assert_equal(true, File.exists?("/tmp/pho/split/tmp/large_10.nt"))
    assert_equal(true, File.exists?("/tmp/pho/split/tmp/large_20.nt"))
    assert_equal(true, File.exists?("/tmp/pho/split/tmp/large_30.nt"))
    assert_equal(true, File.exists?("/tmp/pho/split/tmp/large_31.nt"))
          
  end
  
end
