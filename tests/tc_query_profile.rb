$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'pho'
require 'test/unit'
require 'mocha'
require 'rexml/document'

class QueryProfileTest < Test::Unit::TestCase

  QP_JSON = <<-EOL
  {
    "http:\/\/api.talis.com\/stores\/testing\/config\/queryprofiles\/1" : {
      "http:\/\/www.w3.org\/2000\/01\/rdf-schema#label" : [ { "value" : "default query profile", "type" : "literal" } ],
      "http:\/\/www.w3.org\/1999\/02\/22-rdf-syntax-ns#type" : [ { "value" : "http:\/\/schemas.talis.com\/2006\/bigfoot\/configuration#QueryProfile", "type" : "uri" } ],
      "http:\/\/schemas.talis.com\/2006\/bigfoot\/configuration#fieldWeight" : [ 
        { "value" : "http:\/\/api.talis.com\/stores\/testing\/config\/queryprofiles\/1#name", "type" : "uri" },
        { "value" : "http:\/\/api.talis.com\/stores\/testing\/config\/queryprofiles\/1#nick", "type" : "uri" }
      ]
    },
    "http:\/\/api.talis.com\/stores\/testing\/config\/queryprofiles\/1#nick" : {
      "http:\/\/schemas.talis.com\/2006\/bigfoot\/configuration#weight" : [ { "value" : "1.0", "type" : "literal" } ],
      "http:\/\/schemas.talis.com\/2006\/frame\/schema#name" : [ { "value" : "nick", "type" : "literal" } ]
    },
    "http:\/\/api.talis.com\/stores\/testing\/config\/queryprofiles\/1#name" : {
      "http:\/\/schemas.talis.com\/2006\/bigfoot\/configuration#weight" : [ { "value" : "2.0", "type" : "literal" } ],
      "http:\/\/schemas.talis.com\/2006\/frame\/schema#name" : [ { "value" : "name", "type" : "literal" } ]
    }
  }  
EOL
  
  def setup
    @qp = Pho::QueryProfile.new("http://api.talis.com/stores/testing/config/queryprofiles/default", "test query profile")
    
    @qp << Pho::FieldWeighting.new("http://api.talis.com/stores/testing/config/queryprofiles/default#title","title", 10)
    @qp << Pho::FieldWeighting.new("http://api.talis.com/stores/testing/config/queryprofiles/default#abstract", "abstract", 5)
    @qp << Pho::FieldWeighting.new("http://api.talis.com/stores/testing/config/queryprofiles/default#body", "body", 1)
        
  end
  
  def test_field_weighting
    
    fw = Pho::FieldWeighting.new("http://api.talis.com/stores/testing/config/queryprofiles/default#title", "title", 10)

    rdf = fw.to_rdf
    
    assert_equal(true, rdf != nil)
    
    #Check it parses
    doc = nil
    assert_nothing_raised {
        doc = REXML::Document.new(rdf)
    }    
    
    root = doc.root
    assert_equal("http://api.talis.com/stores/testing/config/queryprofiles/default#title", root.attributes["about"])
    
    assert_has_single_property_with_literal(root, "frm:name", "title")
    assert_has_single_property_with_literal(root, "bf:weight", "10")
            
  end
    
    
  def assert_has_single_property_with_literal(el, property, value)

    assert_equal(1, el.get_elements(property).length)    
    child = el.get_elements(property)[0]
    assert_equal(value, child.text)
            
  end
  
  def test_to_rdf
    rdf = @qp.to_rdf
    
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
    assert_has_single_property_with_literal(fpmap, "rdfs:label", "test query profile")
    
    assert_equal(3, fpmap.get_elements("bf:fieldWeight").length )
     
  end  
  
  def test_get_queryprofile_from_store
     mc = mock()
     mc.expects(:set_auth)
     mc.expects(:get).with("http://api.talis.com/stores/testing/config/queryprofiles/1", anything, {"Accept" => "application/json"})
     
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)     
    resp = store.get_query_profile()
              
  end

  def test_get_query_profile_from_store_as_xml
     mc = mock()
     mc.expects(:set_auth)
     mc.expects(:get).with("http://api.talis.com/stores/testing/config/queryprofiles/1", anything, {"Accept" => "application/rdf+xml"})
     
     store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)     
     resp = store.get_query_profile(Pho::ACCEPT_RDF)              
  end

    
  def test_read_from_store
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/config/queryprofiles/1", anything, 
    {"Accept" => "application/json"}).returns( HTTP::Message.new_response(QP_JSON) )
   
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    qp = Pho::QueryProfile.read_from_store(store)
    
    assert_not_nil(qp)
    
    assert_equal("http://api.talis.com/stores/testing/config/queryprofiles/1", qp.uri)
    assert_equal("default query profile", qp.label)
    
    assert_equal(2, qp.field_weights.length)       
    
    sorted = qp.field_weights.sort { |x,y|
      x.name <=> y.name
    }
    
    assert_expected_field_weighting(sorted[0], "name", "http://api.talis.com/stores/testing/config/queryprofiles/1#name", "2.0")
    assert_expected_field_weighting(sorted[1], "nick", "http://api.talis.com/stores/testing/config/queryprofiles/1#nick", "1.0")
  end  
  
  def test_get_by_name
        
    assert_expected_field_weighting(@qp.get_by_name("abstract"), "abstract", "http://api.talis.com/stores/testing/config/queryprofiles/default#abstract", 5.0)     
    assert_expected_field_weighting(@qp.get_by_name("title"), "title", "http://api.talis.com/stores/testing/config/queryprofiles/default#title", 10.0)
    
  end
  
  def test_create_weighting
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass")
    weight = Pho::QueryProfile.create_weighting(store, "title", 2)

    assert_expected_field_weighting(weight, "title", "http://api.talis.com/stores/testing/config/queryprofiles/1#title", 2)
            
  end
  
  def assert_expected_field_weighting(fw, name, uri, weight)
    assert_equal(name, fw.name)
    assert_equal(uri, fw.uri)
    assert_equal(weight, fw.weight)    
  end
  
  def test_remove
    fw = @qp.get_by_name("title")
    assert_not_nil(fw)
    @qp.remove(fw)
    fw = @qp.get_by_name("title")
    assert_nil(fw)
    
    fw = @qp.get_by_name("abstract")
    assert_not_nil(fw)
    @qp.remove_by_name("abstract")
    fw = @qp.get_by_name("abstract")
    assert_nil(fw)
   
    assert_equal(false, @qp.mapped_name?("title"))
    assert_equal(false, @qp.mapped_name?("abstract"))
    assert_equal(true, @qp.mapped_name?("body"))
    assert_equal(1, @qp.field_weights.length)     
  end
  
  def test_remove_all
    @qp.remove_all()
    assert_equal( 0, @qp.field_weights.length )    
    assert_nil( @qp.get_by_name("title") )
  end
  
  def test_put_query_profile
      mc = mock()
      mc.expects(:set_auth)
      mc.expects(:put).with("http://api.talis.com/stores/testing/config/queryprofiles/1", anything, {"Content-Type" => "application/rdf+xml"} )
      
      store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)     
      resp = store.put_query_profile(@qp)              
  end  
  
  def test_upload_to_store
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:put).with("http://api.talis.com/stores/testing/config/queryprofiles/1", anything, {"Content-Type" => "application/rdf+xml"} )
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)     
    @qp.upload(store)
        
  end
  
end