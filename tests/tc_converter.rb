$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'pho'
require 'test/unit'
require 'rexml/document'

class ConverterTest < Test::Unit::TestCase
  
  SINGLE_RESOURCE_JSON = <<-EOL
  {
    "http://www.example.org" : {
      "http://www.example.org/ns/resource" : [ { "value" : "http://www.example.org/page", "type" : "uri" } ]
    }
  }
  EOL

  SINGLE_RESOURCE_RDFXML = <<-EOL
  <rdf:RDF xmlns:rdf      = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
           xmlns:ex       = "http://www.example.org/ns/">
  
    <rdf:Description rdf:about="http://www.example.org">
      <ex:resource rdf:resource="http://www.example.org/page"/>
    </rdf:Description>
    
  </rdf:RDF>
  
  EOL
  
  SINGLE_RESOURCE_NTRIPLES = <<-EOL
  <http://www.example.org> <http://www.example.org/ns/resource> <http://www.example.org/page>.
  EOL

  SINGLE_RESOURCE_TURTLE = <<-EOL
  <http://www.example.org> <http://www.example.org/ns/resource> <http://www.example.org/page>.
  EOL
      
  def test_parse_json
    
    hash = Pho::ResourceHash::Converter.parse_json(SINGLE_RESOURCE_JSON)
    assert_not_nil(hash)
    assert_not_nil(hash["http://www.example.org"])
    
  end
  
  def test_parse_rdfxml

    hash = Pho::ResourceHash::Converter.parse_rdfxml(SINGLE_RESOURCE_RDFXML)
    assert_not_nil(hash)
    assert_not_nil(hash["http://www.example.org"])
    
    predicates = hash["http://www.example.org"]
    assert_equal(1, predicates.size() )
    assert_equal(1, predicates["http://www.example.org/ns/resource"].length)
    assert_equal("http://www.example.org/page", predicates["http://www.example.org/ns/resource"][0]["value"])
    assert_equal("uri", predicates["http://www.example.org/ns/resource"][0]["type"])
  end
  
  def test_parse_ntriples
    
    hash = Pho::ResourceHash::Converter.parse_ntriples(SINGLE_RESOURCE_NTRIPLES)
    assert_not_nil(hash)
    assert_not_nil(hash["http://www.example.org"])
    
    predicates = hash["http://www.example.org"]
    assert_equal(1, predicates.size() )
    assert_equal(1, predicates["http://www.example.org/ns/resource"].length)
    assert_equal("http://www.example.org/page", predicates["http://www.example.org/ns/resource"][0]["value"])
    assert_equal("uri", predicates["http://www.example.org/ns/resource"][0]["type"])
    
  end

  def test_parse_turtle
    
    hash = Pho::ResourceHash::Converter.parse_ntriples(SINGLE_RESOURCE_TURTLE)
    assert_not_nil(hash)
    assert_not_nil(hash["http://www.example.org"])
    
    predicates = hash["http://www.example.org"]
    assert_equal(1, predicates.size() )
    assert_equal(1, predicates["http://www.example.org/ns/resource"].length)
    assert_equal("http://www.example.org/page", predicates["http://www.example.org/ns/resource"][0]["value"])
    assert_equal("uri", predicates["http://www.example.org/ns/resource"][0]["type"])
    
  end
  
  def test_serialize_json
    parsed = Pho::ResourceHash::Converter.parse_json(SINGLE_RESOURCE_JSON)
    
    serialized = Pho::ResourceHash::Converter.serialize_json(parsed)    
    reparsed = Pho::ResourceHash::Converter.parse_json(serialized)
    
    assert_equal(parsed, reparsed)
     
  end  
    
end