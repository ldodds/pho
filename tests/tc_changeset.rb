$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'pho'
require 'test/unit'
require 'mocha'
require 'rexml/document'
require 'uri'

class ChangesetTest < Test::Unit::TestCase

  def test_equality_resources
    one = Pho::Update::Statement.create_resource("http://www.example.org/my-resource", "http://xmlns.com/foaf/0.1/homePage", "http://www.example.org/page1")
    two = Pho::Update::Statement.create_resource("http://www.example.org/my-resource", "http://xmlns.com/foaf/0.1/homePage", "http://www.example.org/page2")
    assert_equal(false, one == two)
    assert_equal(true, one != two)
    
    two = Pho::Update::Statement.create_resource("http://www.example.org/my-resource", "http://xmlns.com/foaf/0.1/homePage", "http://www.example.org/page1")
    assert_are_equal(one, two)      
  end

  def test_equality_literals
    one = Pho::Update::Statement.create_literal("http://www.example.org/my-resource", "http://xmlns.com/foaf/0.1/homePage", "one")
    two = Pho::Update::Statement.create_literal("http://www.example.org/my-resource", "http://xmlns.com/foaf/0.1/homePage", "two")
    assert_equal(false, one == two)
    assert_equal(true, one != two)
    
    two = Pho::Update::Statement.create_literal("http://www.example.org/my-resource", "http://xmlns.com/foaf/0.1/homePage", "one")
    assert_are_equal(one, two)
            
  end
  
  def test_statement_constructor
    s = Pho::Update::Statement.create_literal("http://www.example.org/my-resource", "http://xmlns.com/foaf/0.1/homePage", "one", "en")
    s = Pho::Update::Statement.create_literal("http://www.example.org/my-resource", "http://xmlns.com/foaf/0.1/homePage", "one", nil, "http://www.example.org/datatype")
    assert_raise RuntimeError do
      s = Pho::Update::Statement.create_literal("http://www.example.org/my-resource", "http://xmlns.com/foaf/0.1/homePage", "one", "en", "http://www.example.org/datatype")    end
  end

  def test_statement_constructor_visibility
    assert_raise NoMethodError do 
      s = Pho::Update::Statement.new("http://www.example.org/my-resource", "http://xmlns.com/foaf/0.1/homePage", "one", "en")  
    end
    
  end
  
  #Test validation code in constructor
  def test_must_pass_uri_to_constructor
    
    assert_raise URI::InvalidURIError do
      cs = Pho::Update::Changeset.new(nil)
    end
    
    assert_raise URI::InvalidURIError do
      cs = Pho::Update::Changeset.new("literal")
    end
    cs = Pho::Update::Changeset.new("http://www.example.org/my-resource")
    
  end
    
  def assert_are_equal(one, two)
    assert_equal(true, one == two)
    assert_equal(false, one != two)

    assert_equal(true, two == one)
    assert_equal(false, two != one)    
  end
  
  def test_cannot_add_with_wrong_subject()
    cs = Pho::Update::Changeset.new("http://www.example.org")
    assert_raise RuntimeError do
      cs.add_addition( Pho::Update::Statement.create_literal("http://example.net", "http://example.net/predicate", "foo") )    end
    assert_raise RuntimeError do
      cs.add_removal( Pho::Update::Statement.create_literal("http://example.net", "http://example.net/predicate", "foo") )
    end    
  end
  
  def test_to_rdf_empty_changeset
      cs = Pho::Update::Changeset.new("http://www.example.org/my-resource")
      
      rdf = cs.to_rdf()
      assert_not_nil(rdf)
  
      cs_el = get_changeset(rdf)
      soc = REXML::XPath.first(cs_el, "cs:subjectOfChange", Pho::Namespaces::MAPPING)
      assert_equal("http://www.example.org/my-resource", soc.attributes["rdf:resource"] )
      
      el = REXML::XPath.first(cs_el, "cs:creatorName", Pho::Namespaces::MAPPING)
      assert_nil(el)
      el = REXML::XPath.first(cs_el, "cs:changeReason", Pho::Namespaces::MAPPING)
      assert_nil(el) 
       
  end
  
  def test_to_rdf_empty_changeset_with_creator_and_reason
      cs = Pho::Update::Changeset.new("http://www.example.org/my-resource", "creator", "reason")
      
      cs_el = get_changeset(cs.to_rdf)
      soc = REXML::XPath.first(cs_el, "cs:subjectOfChange", Pho::Namespaces::MAPPING)
      assert_equal("http://www.example.org/my-resource", soc.attributes["rdf:resource"] )
      
      el = REXML::XPath.first(cs_el, "cs:creatorName", Pho::Namespaces::MAPPING)
      assert_equal("creator", el.text)
      el = REXML::XPath.first(cs_el, "cs:changeReason", Pho::Namespaces::MAPPING)
      assert_equal("reason", el.text)
       
  end    

  def test_to_rdf_empty_changeset_with_block
      cs = Pho::Update::Changeset.new("http://www.example.org/my-resource") do |obj|
        obj.creator_name = "creator"
        obj.change_reason = "reason"
      end
        
      root = parse(cs.to_rdf)
      cs_el = REXML::XPath.first(root, "cs:ChangeSet", Pho::Namespaces::MAPPING)
      soc = REXML::XPath.first(cs_el, "cs:subjectOfChange", Pho::Namespaces::MAPPING)
      assert_equal("http://www.example.org/my-resource", soc.attributes["rdf:resource"] )
      
      el = REXML::XPath.first(cs_el, "cs:creatorName", Pho::Namespaces::MAPPING)
      assert_equal("creator", el.text)
      el = REXML::XPath.first(cs_el, "cs:changeReason", Pho::Namespaces::MAPPING)
      assert_equal("reason", el.text)
       
  end    
  
  def test_to_rdf_with_resource_addition
    cs = Pho::Update::Changeset.new("http://www.example.org/my-resource") do |c|
      c.add_addition( Pho::Update::Statement.create_resource("http://www.example.org/my-resource", "http://xmlns.com/foaf/0.1/homePage", "http://www.example.org/page") )
    end        
    assert_equal(1, cs.additions.length)
    assert_equal(0, cs.removals.length)

    cs_el = get_changeset(cs.to_rdf)
    
    addition = REXML::XPath.first(cs_el, "cs:addition", Pho::Namespaces::MAPPING)
    assert_not_nil(addition)
    statement = REXML::XPath.first(addition, "rdf:Statement", Pho::Namespaces::MAPPING)
    assert_not_nil(statement)    
    el = REXML::XPath.first(statement, "rdf:subject", Pho::Namespaces::MAPPING)
    assert_equal("http://www.example.org/my-resource", el.attributes["rdf:resource"])
    el = REXML::XPath.first(statement, "rdf:predicate", Pho::Namespaces::MAPPING)
    assert_equal("http://xmlns.com/foaf/0.1/homePage", el.attributes["rdf:resource"])
    el = REXML::XPath.first(statement, "rdf:object", Pho::Namespaces::MAPPING)
    assert_equal("http://www.example.org/page", el.attributes["rdf:resource"])
    assert_equal(nil, el.text)
            
  end  

  def test_to_rdf_with_literal_addition
    cs = Pho::Update::Changeset.new("http://www.example.org/my-resource") do |c|
      c.add_addition( Pho::Update::Statement.create_literal("http://www.example.org/my-resource", "http://xmlns.com/foaf/0.1/homePage", "literal") )
    end    
    assert_equal(1, cs.additions.length)
    
    cs_el = get_changeset(cs.to_rdf)
    
    addition = REXML::XPath.first(cs_el, "cs:addition", Pho::Namespaces::MAPPING)
    assert_not_nil(addition)
    statement = REXML::XPath.first(addition, "rdf:Statement", Pho::Namespaces::MAPPING)
    assert_not_nil(statement)
    el = REXML::XPath.first(statement, "rdf:subject", Pho::Namespaces::MAPPING)
    assert_equal("http://www.example.org/my-resource", el.attributes["rdf:resource"])
    el = REXML::XPath.first(statement, "rdf:predicate", Pho::Namespaces::MAPPING)
    assert_equal("http://xmlns.com/foaf/0.1/homePage", el.attributes["rdf:resource"])
    el = REXML::XPath.first(statement, "rdf:object", Pho::Namespaces::MAPPING)
    assert_equal(nil, el.attributes["rdf:resource"])
    assert_equal("literal", el.text)
            
  end

  def test_to_rdf_with_typed_literal
    cs = Pho::Update::Changeset.new("http://www.example.org/my-resource") do |c|
      c.add_addition( Pho::Update::Statement.create_literal("http://www.example.org/my-resource", "http://xmlns.com/foaf/0.1/homePage", "literal", 
        nil, "http://www.example.org/type") )
    end    
    assert_equal(1, cs.additions.length)
    
    cs_el = get_changeset(cs.to_rdf)
    
    addition = REXML::XPath.first(cs_el, "cs:addition", Pho::Namespaces::MAPPING)
    assert_not_nil(addition)
    statement = REXML::XPath.first(addition, "rdf:Statement", Pho::Namespaces::MAPPING)
    assert_not_nil(statement)
    el = REXML::XPath.first(statement, "rdf:subject", Pho::Namespaces::MAPPING)
    assert_equal("http://www.example.org/my-resource", el.attributes["rdf:resource"])
    el = REXML::XPath.first(statement, "rdf:predicate", Pho::Namespaces::MAPPING)
    assert_equal("http://xmlns.com/foaf/0.1/homePage", el.attributes["rdf:resource"])
    el = REXML::XPath.first(statement, "rdf:object", Pho::Namespaces::MAPPING)
    assert_equal(nil, el.attributes["rdf:resource"])
    assert_equal("literal", el.text)
    assert_equal( "http://www.example.org/type", el.attributes["rdf:datatype"] )
    assert_equal(nil, el.attributes["xml:lang"])        
  end  

  def test_to_rdf_with_language_literal
    cs = Pho::Update::Changeset.new("http://www.example.org/my-resource") do |c|
      c.add_addition( Pho::Update::Statement.create_literal("http://www.example.org/my-resource", "http://xmlns.com/foaf/0.1/homePage", "literal", "fr") )
    end    
    assert_equal(1, cs.additions.length)
    
    cs_el = get_changeset(cs.to_rdf)
    
    addition = REXML::XPath.first(cs_el, "cs:addition", Pho::Namespaces::MAPPING)
    assert_not_nil(addition)
    statement = REXML::XPath.first(addition, "rdf:Statement", Pho::Namespaces::MAPPING)
    assert_not_nil(statement)
    el = REXML::XPath.first(statement, "rdf:subject", Pho::Namespaces::MAPPING)
    assert_equal("http://www.example.org/my-resource", el.attributes["rdf:resource"])
    el = REXML::XPath.first(statement, "rdf:predicate", Pho::Namespaces::MAPPING)
    assert_equal("http://xmlns.com/foaf/0.1/homePage", el.attributes["rdf:resource"])
    el = REXML::XPath.first(statement, "rdf:object", Pho::Namespaces::MAPPING)
    assert_equal(nil, el.attributes["rdf:resource"])
    assert_equal("literal", el.text)
    assert_equal( nil, el.attributes["rdf:datatype"] )
    assert_equal("fr", el.attributes["xml:lang"])        
  end      
  def test_to_rdf_with_resource_removal
    cs = Pho::Update::Changeset.new("http://www.example.org/my-resource") do |c|
      c.add_removal( Pho::Update::Statement.create_resource("http://www.example.org/my-resource", "http://xmlns.com/foaf/0.1/homePage", "http://www.example.org/page") )
    end    
    assert_equal(0, cs.additions.length)
    assert_equal(1, cs.removals.length)
    
    cs_el = get_changeset(cs.to_rdf)
    
    removal = REXML::XPath.first(cs_el, "cs:removal", Pho::Namespaces::MAPPING)
    assert_not_nil(removal)
    
    statement = REXML::XPath.first(removal, "rdf:Statement", Pho::Namespaces::MAPPING)
    assert_not_nil(statement)    
    el = REXML::XPath.first(statement, "rdf:subject", Pho::Namespaces::MAPPING)
    assert_equal("http://www.example.org/my-resource", el.attributes["rdf:resource"])
    el = REXML::XPath.first(statement, "rdf:predicate", Pho::Namespaces::MAPPING)
    assert_equal("http://xmlns.com/foaf/0.1/homePage", el.attributes["rdf:resource"])
    el = REXML::XPath.first(statement, "rdf:object", Pho::Namespaces::MAPPING)
    assert_equal("http://www.example.org/page", el.attributes["rdf:resource"])
    assert_equal(nil, el.text)
            
  end  
  
  def test_submit_changeset
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:post).with("http://api.talis.com/stores/testing/meta", "data", {"Content-Type" => "application/vnd.talis.changeset+xml"} )
      
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    resp = store.submit_changeset("data")            
  end  

  def test_submit_changeset_to_graph
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:post).with("http://api.talis.com/stores/testing/meta/graphs/1", "data", {"Content-Type" => "application/vnd.talis.changeset+xml"} )
      
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    resp = store.submit_changeset("data", false, "1")
                
  end
    
  def test_submit_versioned_changeset
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:post).with("http://api.talis.com/stores/testing/meta/changesets", "data", {"Content-Type" => "application/vnd.talis.changeset+xml"} )
      
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    resp = store.submit_changeset("data", true)            
  end  

  def test_submit_versioned_changeset_to_graph
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:post).with("http://api.talis.com/stores/testing/meta/graphs/1/changesets", "data", {"Content-Type" => "application/vnd.talis.changeset+xml"} )
      
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    resp = store.submit_changeset("data", true, "1")            
  end  

          
  def test_submit
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:post).with("http://api.talis.com/stores/testing/meta", anything, {"Content-Type" => "application/vnd.talis.changeset+xml"} )
      
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    
    cs = Pho::Update::Changeset.new("http://www.example.org/my-resource") do |c|
      c.add_removal( Pho::Update::Statement.create_resource("http://www.example.org/my-resource", "http://xmlns.com/foaf/0.1/homePage", "http://www.example.org/page") )
    end    
    
    resp = cs.submit(store)
    
  end

  def test_submit_versioned
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:post).with("http://api.talis.com/stores/testing/meta/changesets", anything, {"Content-Type" => "application/vnd.talis.changeset+xml"} )
      
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    
    cs = Pho::Update::Changeset.new("http://www.example.org/my-resource") do |c|
      c.add_removal( Pho::Update::Statement.create_resource("http://www.example.org/my-resource", "http://xmlns.com/foaf/0.1/homePage", "http://www.example.org/page") )
    end    
    
    resp = cs.submit(store, true)
    
  end
    
  #parse rdf, return root element
  def parse(rdf)
    doc = REXML::Document.new(rdf)
    return doc.root()
  end

  #parse rdf/xml and retrieve the changeset element
  def get_changeset(rdf)
    root = parse(rdf)
    return REXML::XPath.first(root, "cs:ChangeSet", Pho::Namespaces::MAPPING)
  end     
end