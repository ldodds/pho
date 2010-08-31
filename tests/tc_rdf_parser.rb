$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'pho'
require 'test/unit'
require 'mocha'
require 'rexml/document'

class RdfParserTest < Test::Unit::TestCase
  
  NTRIPLES = <<-EOL
  <http://www.example.org> <http://www.example.org/ns/resource> <http://www.example.org/page>.
  EOL
      
  def setup()
    Dir.mkdir("/tmp/pho") unless File.exists?("/tmp/pho")
    @file = File.new( File.join("/tmp/pho", "test.nt"), "w" )
    @file.write(NTRIPLES)
    @file.close()    
  end
  
  def teardown()
    Dir.glob("/tmp/pho/*.nt") do |file|
      File.delete(file)
    end    
  end
  
  def test_parse_ntriples    
    data = Pho::RDF::Parser.parse_ntriples(@file)
    assert_not_nil(data)
    REXML::Document.new(data)    
  end
  
  def test_parse_ntriples_from_string
    data = Pho::RDF::Parser.parse_ntriples_from_string(NTRIPLES, "http://www.example.org")
    assert_not_nil(data)
    REXML::Document.new(data)        
  end
end