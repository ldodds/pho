$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'pho'
require 'test/unit'
require 'mocha'
require 'rexml/document'

class FieldPredicateMapTest < Test::Unit::TestCase

  TEST_FPMAP = <<-EOL
  {
    "http:\/\/api.talis.com\/stores\/testing\/config\/fpmaps\/1#description" : {
      "http:\/\/schemas.talis.com\/2006\/frame\/schema#property" : [ { "value" : "http:\/\/purl.org\/dc\/elements\/1.1\/description", "type" : "uri" } ],
      "http:\/\/schemas.talis.com\/2006\/frame\/schema#name" : [ { "value" : "description", "type" : "literal" } ]
    },
    "http:\/\/api.talis.com\/stores\/testing\/config\/fpmaps\/1" : {
      "http:\/\/www.w3.org\/2000\/01\/rdf-schema#label" : [ { "value" : "default field\/predicate map", "type" : "literal" } ],
      "http:\/\/www.w3.org\/1999\/02\/22-rdf-syntax-ns#type" : [ { "value" : "http:\/\/schemas.talis.com\/2006\/bigfoot\/configuration#FieldPredicateMap", "type" : "uri" } ],
      "http:\/\/schemas.talis.com\/2006\/frame\/schema#mappedDatatypeProperty" : [ 
        { "value" : "http:\/\/api.talis.com\/stores\/testing\/config\/fpmaps\/1#name", "type" : "uri" },
        { "value" : "http:\/\/api.talis.com\/stores\/testing\/config\/fpmaps\/1#title", "type" : "uri" },
        { "value" : "http:\/\/api.talis.com\/stores\/testing\/config\/fpmaps\/1#description", "type" : "uri" }
      ]
    },
    "http:\/\/api.talis.com\/stores\/testing\/config\/fpmaps\/1#title" : {
      "http:\/\/schemas.talis.com\/2006\/frame\/schema#property" : [ { "value" : "http:\/\/purl.org\/dc\/elements\/1.1\/title", "type" : "uri" } ],
      "http:\/\/schemas.talis.com\/2006\/frame\/schema#name" : [ { "value" : "title", "type" : "literal" } ]
    },
    "http:\/\/api.talis.com\/stores\/testing\/config\/fpmaps\/1#name" : {
      "http:\/\/schemas.talis.com\/2006\/frame\/schema#property" : [ { "value" : "http:\/\/xmlns.com\/foaf\/0.1\/name", "type" : "uri" } ],
      "http:\/\/schemas.talis.com\/2006\/frame\/schema#name" : [ { "value" : "name", "type" : "literal" } ]
    }
  }  
EOL

  def setup
      @fpmap = Pho::FieldPredicateMap.new("http://api.talis.com/stores/testing/config/fpmaps/1", "Test FieldPredicate Map")
      
      @fpmap << Pho::DatatypeProperty.new("http://api.talis.com/stores/testing/config/fpmaps/1#test", 
          "http://www.example.org/ns/test", "test")
          
      @fpmap << Pho::DatatypeProperty.new("http://api.talis.com/stores/testing/config/fpmaps/1#title", 
        "http://www.example.org/ns/title", "title", Pho::Analyzers::STANDARD) 
      
      @fpmap << Pho::DatatypeProperty.new("http://api.talis.com/stores/testing/config/fpmaps/1#address", 
        "http://www.example.org/ns/address", "address")
        
  end    

  def teardown
    @fpmap = nil
  end  
  
  def test_get
     p = @fpmap.get_by_name("test")
     assert_equal("http://api.talis.com/stores/testing/config/fpmaps/1#test", p.uri)
      
     p = @fpmap.get_by_uri("http://www.example.org/ns/test")
     assert_equal("http://api.talis.com/stores/testing/config/fpmaps/1#test", p.uri)
             
  end

  def test_remove_all
    @fpmap.remove_all
    assert_equal(0, @fpmap.datatype_properties.length)
    assert_nil( @fpmap.get_by_name("test") )
  end
    
  def test_remove
     p = @fpmap.get_by_name("test")
     assert_not_nil(p)
     @fpmap.remove(p)
     assert_equal(nil, @fpmap.get_by_name("test") )
     assert_equal(2, @fpmap.datatype_properties.length)
     
     p = @fpmap.remove_by_name("title")
     assert_not_nil(p)

     p = @fpmap.remove_by_name("iamnotthere")
     assert_nil(p)
          
     p = @fpmap.remove_by_uri("http://www.example.org/ns/address")
     assert_not_nil(p)
     
     assert_equal(0, @fpmap.datatype_properties.length)
  end
   
  def test_datatype_property_to_rdf_no_analyzer
    
    prop = Pho::DatatypeProperty.new("http://api.talis.com/stores/testing/config/fpmaps/1#test", 
      "http://www.example.org/ns/test", "test")

    rdf = prop.to_rdf
    
    assert_equal(true, rdf != nil)
    
    #Check it parses
    doc = nil
    assert_nothing_raised {
        doc = REXML::Document.new(rdf)
    }    
    
    root = doc.root
    assert_equal("http://api.talis.com/stores/testing/config/fpmaps/1#test", root.attributes["about"])
    
    assert_has_single_property_with_resource(root, "frm:property", "http://www.example.org/ns/test")
    assert_has_single_property_with_literal(root, "frm:name", "test")
        
    assert_equal(0, root.get_elements("bf:analyzer").length)    
  end
  
  def test_datatype_property_to_rdf_with_analyzer
    
    prop = Pho::DatatypeProperty.new("http://api.talis.com/stores/testing/config/fpmaps/1#test", 
      "http://www.example.org/ns/test", "test", Pho::Analyzers::NORMALISE_STANDARD)

    rdf = prop.to_rdf
    
    assert_equal(true, rdf != nil)
    
    #Check it parses
    doc = nil
    assert_nothing_raised {
        doc = REXML::Document.new(rdf)
    }    
    
    root = doc.root
    assert_equal("http://api.talis.com/stores/testing/config/fpmaps/1#test", root.attributes["about"])
    
    assert_has_single_property_with_resource(root, "frm:property", "http://www.example.org/ns/test")
    assert_has_single_property_with_literal(root, "frm:name", "test")
    assert_has_single_property_with_resource(root, "bf:analyzer", "http://schemas.talis.com/2007/bigfoot/analyzers#norm-en")
        
  end

  def assert_has_single_property_with_literal(el, property, value)

    assert_equal(1, el.get_elements(property).length)    
    child = el.get_elements(property)[0]
    assert_equal(value, child.text)
            
  end
  
  def assert_has_single_property_with_resource(el, property, resource_uri)
    assert_equal(1, el.get_elements(property).length)    
    analyzer = el.get_elements(property)[0]
    assert_equal(resource_uri, analyzer.attributes["resource"])
  end
      
  def test_get_fpmaps_from_store
     mc = mock()
     mc.expects(:set_auth)
     mc.expects(:get).with("http://api.talis.com/stores/testing/config/fpmaps/1", anything, {"Accept" => "application/json"})
     
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)     
    resp = store.get_field_predicate_map()
              
  end

  def test_read_fpmaps_from_store_as_xml
     mc = mock()
     mc.expects(:set_auth)
     mc.expects(:get).with("http://api.talis.com/stores/testing/config/fpmaps/1", anything, {"Accept" => "application/rdf+xml"})
     
     store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)     
     resp = store.get_field_predicate_map(Pho::ACCEPT_RDF)              
  end
    
  def test_put_fpmaps_to_store
      mc = mock()
      mc.expects(:set_auth)
      mc.expects(:put).with("http://api.talis.com/stores/testing/config/fpmaps/1", anything, {"Content-Type" => "application/rdf+xml"} )
      
      store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)     
      resp = store.put_field_predicate_map(@fpmap)              
  end  
  
  def test_upload_to_store
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:put).with("http://api.talis.com/stores/testing/config/fpmaps/1", anything, {"Content-Type" => "application/rdf+xml"} )
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)     
    @fpmap.upload(store)    
  end
  
  def test_read_from_store
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/config/fpmaps/1", anything, 
      {"Accept" => "application/json"}).returns( HTTP::Message.new_response(TEST_FPMAP))
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)     
    
    fpmap = Pho::FieldPredicateMap.read_from_store(store)
    assert_not_nil(fpmap)
    assert_equal("default field/predicate map", fpmap.label)
    assert_equal(3, fpmap.datatype_properties.length)
    
    sorted = fpmap.datatype_properties.sort { |x,y|
      x.name <=> y.name
    }
   
    assert_expected_datatype_property(sorted[0], "description", 
      "http://api.talis.com/stores/testing/config/fpmaps/1#description", 
      "http://purl.org/dc/elements/1.1/description")
        
    assert_expected_datatype_property(sorted[1], "name", 
      "http://api.talis.com/stores/testing/config/fpmaps/1#name", 
      "http://xmlns.com/foaf/0.1/name")
      
    assert_expected_datatype_property(sorted[2], "title", 
      "http://api.talis.com/stores/testing/config/fpmaps/1#title", 
      "http://purl.org/dc/elements/1.1/title")
           
  end   

  def assert_expected_datatype_property(dp, name, uri, property_uri)
    assert_equal(name, dp.name)
    assert_equal(uri, dp.uri)
    assert_equal(property_uri, dp.property_uri)    
  end
      
  def test_get_name
    
    name = @fpmap.get_name("http://www.example.org/ns/title")    
    assert_not_nil(name)
    assert_equal("title", name)

    name = @fpmap.get_name("http://www.example.org/ns/location")    
    assert_nil(name)
             
  end

  def test_get_property_uri

    uri = @fpmap.get_property_uri("address")    
    assert_not_nil(uri)
    assert_equal("http://www.example.org/ns/address", uri)

    uri = @fpmap.get_property_uri("location")    
    assert_nil(uri)
        
  end  
  
  def test_mapped_name?
    assert_equal(true, @fpmap.mapped_name?("address"))
    assert_equal(false, @fpmap.mapped_name?("location"))        
  end  
  
  def test_mapped_uri?
    assert_equal(true, @fpmap.mapped_uri?("http://www.example.org/ns/address"))
    assert_equal(false, @fpmap.mapped_uri?("http://www.example.org/ns/location"))            
  end
  
  def test_create_mapping_with_slash_uri
    mc = mock()
    mc.stub_everything
    mc.expects(:build_uri).with("/config/fpmaps/1#title").returns("http://api.talis.com/stores/testing/config/fpmaps/1#title")
    
    mapping = Pho::FieldPredicateMap.create_mapping(mc, "http://www.example.org/ns/title", "title")
    assert_not_nil(mapping)
    assert_equal("http://api.talis.com/stores/testing/config/fpmaps/1#title", mapping.uri)
    assert_equal("http://www.example.org/ns/title", mapping.property_uri)
    assert_equal("title", mapping.name)
    assert_equal(nil, mapping.analyzer)    
  end

  def test_create_mapping_with_hash_uri
    mc = mock()
    mc.stub_everything
    mc.expects(:build_uri).with("/config/fpmaps/1#document").returns("http://api.talis.com/stores/testing/config/fpmaps/1#document")
    
    mapping = Pho::FieldPredicateMap.create_mapping(mc, "http://www.example.org/ns/things#document", "document", Pho::Analyzers::DUTCH)
    assert_not_nil(mapping)
    assert_equal("http://api.talis.com/stores/testing/config/fpmaps/1#document", mapping.uri)
    assert_equal("http://www.example.org/ns/things#document", mapping.property_uri)
    assert_equal("document", mapping.name)
    assert_equal(Pho::Analyzers::DUTCH, mapping.analyzer)    
  end
  
  def test_create_mapping_with_invalid_name
    assert_raise RuntimeError do
      Pho::FieldPredicateMap.create_mapping(nil, "http://www.example.org/ns/things#document", "12345")
    end
  end    
  
  def test_to_rdf
    rdf = @fpmap.to_rdf
    
    assert_equal(true, rdf != nil)
    
    #Check it parses
    doc = nil
    assert_nothing_raised {
        doc = REXML::Document.new(rdf)
    }    
    
    root = doc.root
    
    children = root.get_elements("rdf:Description")
    #fpmap + 3 mappings
    assert_equal(4, children.length)
    
    fpmap = children[0]
    assert_has_single_property_with_literal(fpmap, "rdfs:label", "Test FieldPredicate Map")
    assert_has_single_property_with_resource(fpmap, "rdf:type", "http://schemas.talis.com/2006/bigfoot/configuration#FieldPredicateMap") 
  end
  
end