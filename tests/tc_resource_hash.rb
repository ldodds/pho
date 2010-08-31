$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'pho'
require 'test/unit'
require 'mocha'
require 'rexml/document'
require 'uri'

class ResourceHashTest < Test::Unit::TestCase
  SINGLE_TRIPLE_RESOURCE = <<-EOL
  {
    "http://www.example.org" : {
      "http://www.example.org/ns/resource" : [ { "value" : "http://www.example.org/page", "type" : "uri" } ]
    }
  }
  EOL

  SINGLE_TRIPLE_RESOURCE2 = <<-EOL
  {
    "http://www.example.org" : {
      "http://www.example.org/ns/resource" : [ { "value" : "http://www.example.org/other-page", "type" : "uri" } ]
    }
  }
  EOL
    
  SINGLE_TRIPLE_LITERAL = <<-EOL
  {
    "http://www.example.org" : {
      "http://www.example.org/ns/literal" : [ { "value" : "Title", "type" : "literal" } ]
    }
  }
  EOL

  SINGLE_TRIPLE_LITERAL2 = <<-EOL
  {
    "http://www.example.org" : {
      "http://www.example.org/ns/literal" : [ { "value" : "Other Title", "type" : "literal" } ]
    }
  }
  EOL

    
  SINGLE_TRIPLE_DIFF_TYPE = <<-EOL
  {
    "http://www.example.org" : {
      "http://www.example.org/ns/literal" : [ { "value" : "http://www.example.com", "type" : "uri" } ]
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

  REPEATED_TRIPLES = <<-EOL
  {
    "http://www.example.org" : {
      "http://www.example.org/ns/literal" : [ { "value" : "Title", "type" : "literal" }, { "value" : "Other Title", "type" : "literal" } ]        
    }
  }
  EOL

  SINGLE_TRIPLE_LITERAL_ENGLISH = <<-EOL
  {
    "http://www.example.org" : {
      "http://www.example.org/ns/literal" : [ { "value" : "English", "type" : "literal", "lang" : "en" } ]
    }
  }
  EOL

  SINGLE_TRIPLE_LITERAL_FRENCH = <<-EOL
  {
    "http://www.example.org" : {
      "http://www.example.org/ns/literal" : [ { "value" : "French", "type" : "literal", "lang" : "fr" } ]
    }
  }
  EOL

  SINGLE_TYPED_TRIPLE_INT = <<-EOL
  {
    "http://www.example.org" : {
      "http://www.example.org/ns/literal" : [ { "value" : "1", "type" : "literal", "datatype" : "http://www.w3.org/2001/XMLSchema#int" } ]
    }
  }
  EOL

  SINGLE_TYPED_TRIPLE_FLOAT = <<-EOL
  {
    "http://www.example.org" : {
      "http://www.example.org/ns/literal" : [ { "value" : "2.5", "type" : "literal", "datatype" : "http://www.w3.org/2001/XMLSchema#float" } ]
    }
  }
  EOL
  
            
  def test_minus_with_iso_graphs()
  
    difference = Pho::ResourceHash::SetAlgebra.minus( JSON.parse(SINGLE_TRIPLE_RESOURCE), JSON.parse(SINGLE_TRIPLE_RESOURCE) )
    assert_not_nil(difference)        
    assert_equal(0, difference.keys.length)
                
  end
    
  def test_minus_with_single_resource_value_change()
  
    difference = Pho::ResourceHash::SetAlgebra.minus( JSON.parse(SINGLE_TRIPLE_RESOURCE), JSON.parse(SINGLE_TRIPLE_RESOURCE2) )
    assert_not_nil(difference)    
    assert_equal(1, difference.keys.length)    
    assert_equal( "http://www.example.org/page",
      difference["http://www.example.org"]["http://www.example.org/ns/resource"][0]["value"] )

    #reverse
          
    difference = Pho::ResourceHash::SetAlgebra.minus( JSON.parse(SINGLE_TRIPLE_RESOURCE2), JSON.parse(SINGLE_TRIPLE_RESOURCE) )
    assert_not_nil(difference)    
    assert_equal(1, difference.keys.length)    
    assert_equal( "http://www.example.org/other-page",
      difference["http://www.example.org"]["http://www.example.org/ns/resource"][0]["value"] )
            
  end

  def test_minus_with_single_literal_value_change()
  
    difference = Pho::ResourceHash::SetAlgebra.minus( JSON.parse(SINGLE_TRIPLE_LITERAL), JSON.parse(SINGLE_TRIPLE_LITERAL2) )
    assert_not_nil(difference)    
    assert_equal(1, difference.keys.length)    
    assert_equal( "Title",
      difference["http://www.example.org"]["http://www.example.org/ns/literal"][0]["value"] )

    #reverse          
    difference = Pho::ResourceHash::SetAlgebra.minus( JSON.parse(SINGLE_TRIPLE_LITERAL2), JSON.parse(SINGLE_TRIPLE_LITERAL) )
    assert_not_nil(difference)    
    assert_equal(1, difference.keys.length)    
    assert_equal( "Other Title",
      difference["http://www.example.org"]["http://www.example.org/ns/literal"][0]["value"] )
            
  end
  
  def test_minus_with_different_typed_predicate_values()
  
    difference = Pho::ResourceHash::SetAlgebra.minus( JSON.parse(SINGLE_TRIPLE_LITERAL), JSON.parse(SINGLE_TRIPLE_DIFF_TYPE) )
    assert_not_nil(difference)    
    assert_equal(1, difference.keys.length)    
    assert_equal( "Title",
      difference["http://www.example.org"]["http://www.example.org/ns/literal"][0]["value"] )

    #reverse
    difference = Pho::ResourceHash::SetAlgebra.minus( JSON.parse(SINGLE_TRIPLE_DIFF_TYPE), JSON.parse(SINGLE_TRIPLE_LITERAL) )
    assert_not_nil(difference)    
    assert_equal(1, difference.keys.length)    
    assert_equal( "http://www.example.com",
      difference["http://www.example.org"]["http://www.example.org/ns/literal"][0]["value"] )
            
  end

  def test_minus_with_different_size_graphs()
  
    difference = Pho::ResourceHash::SetAlgebra.minus( JSON.parse(SINGLE_TRIPLE_RESOURCE), JSON.parse(TWO_TRIPLES) )
    assert_not_nil(difference)    
    assert_equal(0, difference.keys.length)    

    #reverse
    difference = Pho::ResourceHash::SetAlgebra.minus( JSON.parse(TWO_TRIPLES), JSON.parse(SINGLE_TRIPLE_RESOURCE) )
    assert_not_nil(difference)    
    assert_equal(1, difference.keys.length)    
    assert_equal( "Title",
      difference["http://www.example.org"]["http://www.example.org/ns/literal"][0]["value"] )
            
  end      

  def test_minus_with_repeated_properties()
  
    difference = Pho::ResourceHash::SetAlgebra.minus( JSON.parse(SINGLE_TRIPLE_LITERAL), JSON.parse(REPEATED_TRIPLES) )
    assert_not_nil(difference)    
    assert_equal(0, difference.keys.length)    

    #reverse
    difference = Pho::ResourceHash::SetAlgebra.minus( JSON.parse(REPEATED_TRIPLES), JSON.parse(SINGLE_TRIPLE_LITERAL) )
    assert_not_nil(difference)    
    assert_equal(1, difference.keys.length)    
    assert_equal( "Other Title",
      difference["http://www.example.org"]["http://www.example.org/ns/literal"][0]["value"] )
            
  end      
  
  def test_minus_with_language_qualified_literals()
    
    difference = Pho::ResourceHash::SetAlgebra.minus( JSON.parse(SINGLE_TRIPLE_LITERAL), JSON.parse(SINGLE_TRIPLE_LITERAL) )
    assert_not_nil(difference)    
    assert_equal(0, difference.keys.length)    

    difference = Pho::ResourceHash::SetAlgebra.minus( JSON.parse(SINGLE_TRIPLE_LITERAL_ENGLISH), JSON.parse(SINGLE_TRIPLE_LITERAL_ENGLISH) )
    assert_not_nil(difference)    
    assert_equal(0, difference.keys.length)
    
    difference = Pho::ResourceHash::SetAlgebra.minus( JSON.parse(SINGLE_TRIPLE_LITERAL), JSON.parse(SINGLE_TRIPLE_LITERAL_ENGLISH) )
    assert_not_nil(difference)    
    assert_equal(1, difference.keys.length)
    assert_equal( "Title",
      difference["http://www.example.org"]["http://www.example.org/ns/literal"][0]["value"] )

    #reverse no lang and english
    difference = Pho::ResourceHash::SetAlgebra.minus( JSON.parse(SINGLE_TRIPLE_LITERAL_ENGLISH), JSON.parse(SINGLE_TRIPLE_LITERAL) )
    assert_not_nil(difference)    
    assert_equal(1, difference.keys.length)
    assert_equal( "English",
      difference["http://www.example.org"]["http://www.example.org/ns/literal"][0]["value"] )
    assert_equal( "en",
      difference["http://www.example.org"]["http://www.example.org/ns/literal"][0]["lang"] )

    difference = Pho::ResourceHash::SetAlgebra.minus( JSON.parse(SINGLE_TRIPLE_LITERAL_ENGLISH), JSON.parse(SINGLE_TRIPLE_LITERAL_FRENCH) )
    assert_not_nil(difference)    
    assert_equal(1, difference.keys.length)
    assert_equal( "English",
      difference["http://www.example.org"]["http://www.example.org/ns/literal"][0]["value"] )
    assert_equal( "en",
      difference["http://www.example.org"]["http://www.example.org/ns/literal"][0]["lang"] )

    #reverse no lang and english
    difference = Pho::ResourceHash::SetAlgebra.minus( JSON.parse(SINGLE_TRIPLE_LITERAL_FRENCH), JSON.parse(SINGLE_TRIPLE_LITERAL_ENGLISH) )
    assert_not_nil(difference)    
    assert_equal(1, difference.keys.length)
    assert_equal( "French",
      difference["http://www.example.org"]["http://www.example.org/ns/literal"][0]["value"] )
    assert_equal( "fr",
      difference["http://www.example.org"]["http://www.example.org/ns/literal"][0]["lang"] )
                            
  end        

  def test_minus_with_typed_literals()
    
    difference = Pho::ResourceHash::SetAlgebra.minus( JSON.parse(SINGLE_TYPED_TRIPLE_INT), JSON.parse(SINGLE_TYPED_TRIPLE_INT) )
    assert_not_nil(difference)    
    assert_equal(0, difference.keys.length)
    
    difference = Pho::ResourceHash::SetAlgebra.minus( JSON.parse(SINGLE_TRIPLE_LITERAL), JSON.parse(SINGLE_TYPED_TRIPLE_INT) )
    assert_not_nil(difference)    
    assert_equal(1, difference.keys.length)
    assert_equal( "Title",
      difference["http://www.example.org"]["http://www.example.org/ns/literal"][0]["value"] )

    #reverse no type and int
    difference = Pho::ResourceHash::SetAlgebra.minus( JSON.parse(SINGLE_TYPED_TRIPLE_INT), JSON.parse(SINGLE_TRIPLE_LITERAL) )
    assert_not_nil(difference)    
    assert_equal(1, difference.keys.length)
    assert_equal( "1",
      difference["http://www.example.org"]["http://www.example.org/ns/literal"][0]["value"] )
    assert_equal( "http://www.w3.org/2001/XMLSchema#int",
      difference["http://www.example.org"]["http://www.example.org/ns/literal"][0]["datatype"] )

    difference = Pho::ResourceHash::SetAlgebra.minus( JSON.parse(SINGLE_TYPED_TRIPLE_INT), JSON.parse(SINGLE_TYPED_TRIPLE_FLOAT) )
    assert_not_nil(difference)    
    assert_equal(1, difference.keys.length)
    assert_equal( "1",
      difference["http://www.example.org"]["http://www.example.org/ns/literal"][0]["value"] )
    assert_equal( "http://www.w3.org/2001/XMLSchema#int",
      difference["http://www.example.org"]["http://www.example.org/ns/literal"][0]["datatype"] )
      
    #reverse float and int
    difference = Pho::ResourceHash::SetAlgebra.minus( JSON.parse(SINGLE_TYPED_TRIPLE_FLOAT), JSON.parse(SINGLE_TYPED_TRIPLE_INT) )
    assert_not_nil(difference)    
    assert_equal(1, difference.keys.length)
    assert_equal( "2.5",
      difference["http://www.example.org"]["http://www.example.org/ns/literal"][0]["value"] )
    assert_equal( "http://www.w3.org/2001/XMLSchema#float",
      difference["http://www.example.org"]["http://www.example.org/ns/literal"][0]["datatype"] )
                                  
  end    
end