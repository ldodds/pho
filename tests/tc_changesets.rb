$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'pho'
require 'test/unit'
require 'mocha'
require 'rexml/document'
require 'uri'

class ChangesetsTest < Test::Unit::TestCase
  SINGLE_TRIPLE_RESOURCE = <<-EOL
  {
    "http://www.example.org" : {
      "http://www.example.org/ns/predicate" : [ { "value" : "http://www.example.org/page", "type" : "uri" } ]
    }
  }
  EOL

  SINGLE_TRIPLE_LITERAL = <<-EOL
  {
    "http://www.example.org" : {
      "http://www.example.org/ns/predicate" : [ { "value" : "Title", "type" : "literal" } ]
    }
  }
  EOL
  
  def test_submit_all
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:post).with("http://api.talis.com/stores/testing/meta", anything, {"Content-Type" => "application/vnd.talis.changeset+xml"} )
      
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    
    changesets = Array.new
    changesets << Pho::Update::Changeset.new("http://www.example.org/my-resource") do |c|
      c.add_removal( Pho::Update::Statement.create_resource("http://www.example.org/my-resource", "http://xmlns.com/foaf/0.1/homePage", "http://www.example.org/page") )
    end    

    changesets << Pho::Update::Changeset.new("http://www.example.org/my-resource") do |c|
      c.add_removal( Pho::Update::Statement.create_resource("http://www.example.org/my-resource", "http://xmlns.com/foaf/0.1/name", "Name") )
    end    
        
    resp = Pho::Update::Changesets.submit_all(changesets, store)
    
  end  
  
  def test_all_to_rdf
    
    changesets = Array.new
    changesets << Pho::Update::Changeset.new("http://www.example.org/my-resource") do |c|
      c.add_removal( Pho::Update::Statement.create_resource("http://www.example.org/my-resource", "http://xmlns.com/foaf/0.1/homePage", "http://www.example.org/page") )
    end    

    changesets << Pho::Update::Changeset.new("http://www.example.org/my-resource") do |c|
      c.add_removal( Pho::Update::Statement.create_resource("http://www.example.org/my-resource", "http://xmlns.com/foaf/0.1/name", "Name") )
    end    
    
    rdf = Pho::Update::Changesets.all_to_rdf(changesets)
    
    doc = REXML::Document.new(rdf)
    root = doc.root
    assert_equal("RDF", root.name)
    assert_equal("http://www.w3.org/1999/02/22-rdf-syntax-ns#", root.namespace)
    count = 0
    REXML::XPath.each(root, "cs:ChangeSet", Pho::Namespaces::MAPPING) do |cs|
      count += 1 
    end
    assert_equal(2, count)
  end
  
#  def test_build_with_single_triple1
#      
#    cs = Pho::Update::Changesets.build(nil, SINGLE_TRIPLE_RESOURCE)
#    assert_not_nil(cs)
#    assert_equal("http://www.example.org", cs.subject_of_change)
#    assert_nil(cs.removal)  
#    assert_not_nil(cs.addition)
#    s = cs.addition
#    assert_equal("http://www.example.org", s.subject)
#    assert_equal("http://www.example.org/predicate", s.predicate)
#    assert_equal("http://www.example.org/page", s.object)
#  end
#
#  def test_build_with_single_triple2
#      
#    cs = Pho::Update::Changesets.build(nil, SINGLE_TRIPLE_LITERAL)
#    assert_not_nil(cs)
#    assert_equal("http://www.example.org", cs.subject_of_change)
#    assert_nil(cs.removal)  
#    assert_not_nil(cs.addition)
#    s = cs.addition
#    assert_equal("http://www.example.org", s.subject)
#    assert_equal("http://www.example.org/predicate", s.predicate)
#    assert_equal("Title", s.object)
#    
#  end
    
end