$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'pho'
require 'test/unit'
require 'mocha'
require 'rexml/document'
require 'uri'

class ChangesetBuilderTest < Test::Unit::TestCase
  
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
  
  TWO_TRIPLES = <<-EOL
  {
    "http://www.example.org" : {
      "http://www.example.org/ns/resource" : [ { "value" : "http://www.example.org/page", "type" : "uri" } ],
      "http://www.example.org/ns/literal" : [ { "value" : "Title", "type" : "literal" } ]        
    }
  }
  EOL

  SOME_TRIPLES = <<-EOL
  {
    "http://www.example.org" : {
      "http://www.example.org/ns/resource" : [ { "value" : "http://www.example.org/page", "type" : "uri" } ],
      "http://www.example.org/ns/property" : [ { "value" : "Blah blah blah", "type" : "literal" } ]
    },
    "http://www.example.org/other" : {
          "http://www.example.org/ns/property" : [ { "value" : "Something", "type" : "literal" } ]        
    }      
  }
  EOL

#  COLLECTION = <<-EOL
#  <rdf:RDF xmlns:rdf      = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
#           xmlns:ex       = "http://www.example.org/ns/">
#  
#    <rdf:Description rdf:about="http://www.example.org">
#      <ex:list rdf:parseType="Collection">
#         <rdf:Description rdf:about="http://www.example.org/first"/>
#         <rdf:Description rdf:about="http://www.example.org/second"/>
#         <rdf:Description rdf:about="http://www.example.org/third"/>         
#      </ex:list>
#    </rdf:Description>
#    
#  </rdf:RDF>  
#  EOL
#
#  SHORT_COLLECTION = <<-EOL
#  <rdf:RDF xmlns:rdf      = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
#           xmlns:ex       = "http://www.example.org/ns/">
#  
#    <rdf:Description rdf:about="http://www.example.org">
#      <ex:list rdf:parseType="List">
#         <rdf:Description rdf:about="http://www.example.org/first"/>
#         <rdf:Description rdf:about="http://www.example.org/second"/>         
#      </ex:list>
#    </rdf:Description>
#    
#  </rdf:RDF>  
#  EOL

  COLLECTION = <<-EOL
  <rdf:RDF xmlns:rdf      = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
           xmlns:ex       = "http://www.example.org/ns/">
  
    <rdf:Description rdf:about="http://www.example.org">
      <ex:list rdf:resource="http://www.example.org/list#first"/>
    </rdf:Description>
  <rdf:Description rdf:about="http://www.example.org/list#first">
     <rdf:first rdf:resource="http://www.example.org/first"/>
     <rdf:rest rdf:resource="http://www.example.org/list#second"/>
  </rdf:Description>
  <rdf:Description rdf:about="http://www.example.org/list#second">
    <rdf:first rdf:resource="http://www.example.org/second"/>
    <rdf:rest rdf:resource="http://www.example.org/second"/>
  </rdf:Description>
  <rdf:Description rdf:about="http://www.example.org/list#third">
   <rdf:first rdf:resource="http://www.example.org/third"/>
   <rdf:rest rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#nil"/>
  </rdf:Description>                  
    
  </rdf:RDF>  
  EOL

  SHORT_COLLECTION = <<-EOL
  <rdf:RDF xmlns:rdf      = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
           xmlns:ex       = "http://www.example.org/ns/">
  
    <rdf:Description rdf:about="http://www.example.org">
      <ex:list rdf:resource="http://www.example.org/list#first"/>
    </rdf:Description>
  <rdf:Description rdf:about="http://www.example.org/list#first">
     <rdf:first rdf:resource="http://www.example.org/first"/>
     <rdf:rest rdf:resource="http://www.example.org/list#second"/>
  </rdf:Description>
  <rdf:Description rdf:about="http://www.example.org/list#second">
    <rdf:first rdf:resource="http://www.example.org/second"/>
  <rdf:rest rdf:resource="http://www.w3.org/1999/02/22-rdf-syntax-ns#nil"/>
  </rdf:Description>
    
  </rdf:RDF>    
  EOL
  
  SEQUENCE = <<-EOL
  <rdf:RDF xmlns:rdf      = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
           xmlns:ex       = "http://www.example.org/ns/">
  
    <rdf:Description rdf:about="http://www.example.org">
      <ex:list>
         <rdf:Seq>
         <rdf:li><rdf:Description rdf:about="http://www.example.org/first"/></rdf:li>
         <rdf:li><rdf:Description rdf:about="http://www.example.org/second"/></rdf:li>
         <rdf:li><rdf:Description rdf:about="http://www.example.org/third"/></rdf:li>
         </rdf:Seq>         
      </ex:list>
    </rdf:Description>
    
  </rdf:RDF>  
  EOL

  SHORT_SEQUENCE = <<-EOL
  <rdf:RDF xmlns:rdf      = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
           xmlns:ex       = "http://www.example.org/ns/">
  
  <rdf:Description rdf:about="http://www.example.org">
    <ex:list>
       <rdf:Seq>
       <rdf:li><rdf:Description rdf:about="http://www.example.org/first"/></rdf:li>
       <rdf:li><rdf:Description rdf:about="http://www.example.org/second"/></rdf:li>
       </rdf:Seq>         
    </ex:list>
  </rdf:Description>    
  </rdf:RDF>  
  EOL
          
    def test_build_with_single_triple1
        
      cs = Pho::Update::ChangesetBuilder.build("http://www.example.org", JSON.parse("{}"), JSON.parse( SINGLE_TRIPLE_RESOURCE ) )
      assert_not_nil(cs)
      assert_equal("http://www.example.org", cs.subject_of_change)
      assert_equal(0, cs.removals.length)  
      assert_equal(1, cs.additions.length)
      s = cs.additions[0]
      assert_equal("http://www.example.org", s.subject)
      assert_equal("http://www.example.org/ns/predicate", s.predicate)
      assert_equal("http://www.example.org/page", s.object)
    end
  
    def test_build_with_single_triple2
        
      cs = Pho::Update::ChangesetBuilder.build("http://www.example.org", JSON.parse("{}"), JSON.parse( SINGLE_TRIPLE_LITERAL ) )
      assert_not_nil(cs)
      assert_equal("http://www.example.org", cs.subject_of_change)
      assert_equal(0, cs.removals.length)  
      assert_equal(1, cs.additions.length)
      s = cs.additions[0]
      assert_equal("http://www.example.org", s.subject)
      assert_equal("http://www.example.org/ns/predicate", s.predicate)
      assert_equal("Title", s.object)
      
    end

  def test_build_with_additions_and_removals
      
    cs = Pho::Update::ChangesetBuilder.build("http://www.example.org", JSON.parse(SINGLE_TRIPLE_LITERAL), JSON.parse( TWO_TRIPLES ) )
    assert_not_nil(cs)
    assert_equal("http://www.example.org", cs.subject_of_change)
    assert_equal(1, cs.removals.length)  
    assert_equal(2, cs.additions.length)
    s = cs.removals[0]
    assert_equal("http://www.example.org", s.subject)
    assert_equal("http://www.example.org/ns/predicate", s.predicate)
    assert_equal("Title", s.object)
    s = cs.additions[0]
    assert_equal("http://www.example.org", s.subject)
    assert_equal("http://www.example.org/ns/resource", s.predicate)
    assert_equal("http://www.example.org/page", s.object)
    s = cs.additions[1]
    assert_equal("http://www.example.org", s.subject)
    assert_equal("http://www.example.org/ns/literal", s.predicate)
    assert_equal("Title", s.object)
    
  end
          
  def test_create_statements
      statements = Pho::Update::ChangesetBuilder.create_statements( JSON.parse(SINGLE_TRIPLE_RESOURCE) )
      assert_not_nil(statements)
      assert(1, statements.length)
   
      s = statements[0]
      
      assert_equal("http://www.example.org", s.subject)
      assert_equal("http://www.example.org/ns/predicate", s.predicate)
      assert_equal("http://www.example.org/page", s.object)
      
  end

  def test_create_statements2
    statements = Pho::Update::ChangesetBuilder.create_statements( JSON.parse(TWO_TRIPLES) )
    assert_not_nil(statements)
    assert(2, statements.length)        
  end
  
  def test_batch_changeset
    changesets = Pho::Update::ChangesetBuilder.build_batch(JSON.parse( TWO_TRIPLES ), JSON.parse( SOME_TRIPLES ) )
    assert_equal(2, changesets.length)
    first_uri_changes = changesets[0]
    assert_equal("http://www.example.org", first_uri_changes.subject_of_change)
    assert_equal(nil, first_uri_changes.creator_name)  
    assert_equal(nil, first_uri_changes.change_reason)
    removals = first_uri_changes.removals
    assert_equal(1, removals.length)
    assert_equal("http://www.example.org/ns/literal", removals[0].predicate)
    additions = first_uri_changes.additions
    assert_equal(1, additions.length)
    assert_equal("http://www.example.org/ns/property", additions[0].predicate)
    
    second_uri_changes = changesets[1]
    assert_equal("http://www.example.org/other", second_uri_changes.subject_of_change)
    assert_equal(nil, second_uri_changes.creator_name)  
    assert_equal(nil, second_uri_changes.change_reason)
    removals = second_uri_changes.removals
    assert_equal(0, removals.length)
    additions = second_uri_changes.additions
    assert_equal(1, additions.length)
    assert_equal("http://www.example.org/ns/property", additions[0].predicate)
    
  end
  
  def test_batch_changeset_with_change_description
    changesets = Pho::Update::ChangesetBuilder.build_batch(JSON.parse( TWO_TRIPLES ), JSON.parse( SOME_TRIPLES ), "Bob Bobson", "Because I can" )
    assert_equal(2, changesets.length)
    first_uri_changes = changesets[0]
    assert_equal("http://www.example.org", first_uri_changes.subject_of_change)
    assert_equal("Bob Bobson", first_uri_changes.creator_name)  
    assert_equal("Because I can", first_uri_changes.change_reason)
    
  end
  
  def test_batch_changeset_with_list
    coll_hash = Pho::ResourceHash::Converter.parse_rdfxml(COLLECTION)
    short_coll_hash = Pho::ResourceHash::Converter.parse_rdfxml(SHORT_COLLECTION)
    changesets = Pho::Update::ChangesetBuilder.build_batch(coll_hash, short_coll_hash, "Bob Bobson", "Because I can" )
    #2 because we've updated the head and tail of the list
    assert_equal(2, changesets.length)
    
    changesets = Pho::Update::ChangesetBuilder.build_batch(short_coll_hash, coll_hash, "Bob Bobson", "Because I can" )
    #2 because we've updated the head and tail of the list
    assert_equal(2, changesets.length)    
  end

#  def test_batch_changeset_with_sequence
#    hash = Pho::ResourceHash::Converter.parse_rdfxml(SEQUENCE, "http://www.example.com")
#    puts hash.inspect()
#  end
    
                
end