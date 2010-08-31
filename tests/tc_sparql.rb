$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'pho'
require 'test/unit'
require 'mocha'

class SparqlTest < Test::Unit::TestCase
  
  def test_simple_store_sparql
  
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/services/sparql", {"query" => "SPARQL"}, {"Accept" => "application/rdf+xml"} ).returns(
      HTTP::Message.new_response("RESULTS"))
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    response = store.sparql("SPARQL", "application/rdf+xml")
    assert_equal("RESULTS", response.content)      
  end

  def test_simple_multisparql
  
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/services/multisparql", {"query" => "SPARQL"}, {"Accept" => "application/rdf+xml"} ).returns(
      HTTP::Message.new_response("RESULTS"))
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    response = store.sparql("SPARQL", "application/rdf+xml", :multisparql)
    assert_equal("RESULTS", response.content)      
  end
    
  def test_store_sparql_with_mimetype
  
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/services/sparql", {"query" => "SPARQL"}, {"Accept" => "application/sparql-results+json"} ).returns(
      HTTP::Message.new_response("RESULTS"))
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    response = store.sparql("SPARQL", "application/sparql-results+json")
    assert_equal("RESULTS", response.content)      
  end    
  
  def test_store_sparql_ask
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/services/sparql", {"query" => "SPARQL"}, {"Accept" => "application/sparql-results+xml"} ).returns(
      HTTP::Message.new_response("RESULTS"))
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    response = store.sparql_ask("SPARQL")
    assert_equal("RESULTS", response.content)          
  end
  
  def test_store_sparql_select
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/services/sparql", {"query" => "SPARQL"}, {"Accept" => "application/sparql-results+xml"} ).returns(
      HTTP::Message.new_response("RESULTS"))
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    response = store.sparql_select("SPARQL")
    assert_equal("RESULTS", response.content)          
  end  
  
  def test_store_sparql_construct
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/services/sparql", {"query" => "SPARQL"}, {"Accept" => "application/rdf+xml"} ).returns(
      HTTP::Message.new_response("RESULTS"))
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    response = store.sparql_construct("SPARQL")
    assert_equal("RESULTS", response.content)          
  end  

  def test_store_sparql_describe
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/services/sparql", {"query" => "SPARQL"}, {"Accept" => "application/rdf+xml"} ).returns(
      HTTP::Message.new_response("RESULTS"))
    
    store = Pho::Store.new("http://api.talis.com/stores/testing/", "user", "pass", mc)
    response = store.sparql_describe("SPARQL")
    assert_equal("RESULTS", response.content)          
  end
  
  def test_get_store_sparql_client
    store = Pho::Store.new("http://api.talis.com/stores/testing/", "user", "pass")
    sparql_client = store.sparql_client()
    assert_equal( true,  sparql_client.supports_rdf_json )    
    assert_equal( true, sparql_client.supports_sparql_json )
  end
  
  def test_simple_query
    
    mc = mock()
    mc.expects(:get).with("http://www.example.org/sparql", {"query" => "SPARQL"}, {})
    
    sparql_client = Pho::Sparql::SparqlClient.new("http://www.example.org/sparql", mc)
    sparql_client.query("SPARQL")
        
  end

  def test_query_with_default_graph

    mc = mock()
    mc.expects(:get).with("http://www.example.org/sparql", {"query" => "SPARQL", "default-graph-uri" => ["http://www.example.com"]}, {})
    
    sparql_client = Pho::Sparql::SparqlClient.new("http://www.example.org/sparql", mc)
    sparql_client.add_default_graph("http://www.example.com")
    sparql_client.query("SPARQL")
        
  end

  def test_query_with_named_graph

    mc = mock()
    mc.expects(:get).with("http://www.example.org/sparql", {"query" => "SPARQL", "named-graph-uri" => ["http://www.example.com"]}, {})
    
    sparql_client = Pho::Sparql::SparqlClient.new("http://www.example.org/sparql", mc)
    sparql_client.add_named_graph("http://www.example.com")
    sparql_client.query("SPARQL")
        
  end
  
  def test_query_with_both_graphs

    mc = mock()
    mc.expects(:get).with("http://www.example.org/sparql", {"query" => "SPARQL", "named-graph-uri" => ["http://www.example.com"], "default-graph-uri" => ["http://www.example.org"]}, {})
    
    sparql_client = Pho::Sparql::SparqlClient.new("http://www.example.org/sparql", mc)
    sparql_client.add_named_graph("http://www.example.com")
    sparql_client.add_default_graph("http://www.example.org")
    sparql_client.query("SPARQL")
        
  end
            
  def test_sparql_with_mimetype
    mc = mock()
    mc.expects(:get).with("http://www.example.org/sparql", {"query" => "SPARQL"}, {"Accept" => "application/sparql-results+xml"})
    
    sparql_client = Pho::Sparql::SparqlClient.new("http://www.example.org/sparql", mc)
    sparql_client.query("SPARQL", "application/sparql-results+xml")
     
  end

  def test_sparql_with_output_parameter
    mc = mock()
    mc.expects(:get).with("http://www.example.org/sparql", {"query" => "SPARQL", "output" => "json"}, {})
    
    sparql_client = Pho::Sparql::SparqlClient.new("http://www.example.org/sparql", mc)
    sparql_client.output_parameter_name="output"
    sparql_client.query("SPARQL", "json")
     
  end
      
  def test_store_sparql_client_overrides_describe_uri
    
    mc = mock()
    mc.expects(:describe).with("http://www.example.org", "application/rdf+xml")    
    
    sparql_client = Pho::StoreSparqlClient.new(mc, "http://api.talis.com/stores/testing/services/sparql")
    resp = sparql_client.describe_uri("http://www.example.org")
     
  end
    
  def test_ask
    mc = mock()
    mc.expects(:get).with("http://api.talis.com/stores/testing/services/sparql", {"query" => "SPARQL"}, {"Accept" => "application/sparql-results+xml"} ).returns(
      HTTP::Message.new_response("RESULTS"))
    
    client = Pho::Sparql::SparqlClient.new("http://api.talis.com/stores/testing/services/sparql", mc)
    response = client.ask("SPARQL")
    assert_equal("RESULTS", response.content)          
  end
  
  def test_store_sparql_select
    mc = mock()
    mc.expects(:get).with("http://api.talis.com/stores/testing/services/sparql", {"query" => "SPARQL"}, {"Accept" => "application/sparql-results+xml"} ).returns(
      HTTP::Message.new_response("RESULTS"))
    
    client = Pho::Sparql::SparqlClient.new("http://api.talis.com/stores/testing/services/sparql", mc)
    response = client.select("SPARQL")
    assert_equal("RESULTS", response.content)          
  end  
      
  def test_construct
    mc = mock()
    mc.expects(:get).with("http://api.talis.com/stores/testing/services/sparql", {"query" => "SPARQL"}, {"Accept" => "application/rdf+xml"} ).returns(
      HTTP::Message.new_response("RESULTS"))
    
    client = Pho::Sparql::SparqlClient.new("http://api.talis.com/stores/testing/services/sparql", mc)
    response = client.construct("SPARQL")
    assert_equal("RESULTS", response.content)          
  end  

  def test_describe
    mc = mock()
    mc.expects(:get).with("http://api.talis.com/stores/testing/services/sparql", {"query" => "SPARQL"}, {"Accept" => "application/rdf+xml"} ).returns(
      HTTP::Message.new_response("RESULTS"))
    
    client = Pho::Sparql::SparqlClient.new("http://api.talis.com/stores/testing/services/sparql", mc)
    response = client.describe("SPARQL")
    assert_equal("RESULTS", response.content)          
  end
  
  def test_multi_describe
    mc = mock()
    mc.expects(:get).with("http://api.talis.com/stores/testing/services/sparql", 
      {"query" => "DESCRIBE <http://www.example.org> <http://www.example.com>"}, 
        {"Accept" => "application/rdf+xml"} ).returns( HTTP::Message.new_response("RESULTS"))

    client = Pho::Sparql::SparqlClient.new("http://api.talis.com/stores/testing/services/sparql", mc)
    uris = []
    uris << "http://www.example.org"
    uris << "http://www.example.com"
    response = client.multi_describe(uris)
    assert_equal("RESULTS", response.content)
                            
  end
 
  def test_describe_uri
    mc = mock()
    mc.expects(:get).with("http://api.talis.com/stores/testing/services/sparql", {"query" => "DESCRIBE <http://www.example.org>"}, {"Accept" => "application/rdf+xml"} ).returns(
      HTTP::Message.new_response("RESULTS"))
    
    client = Pho::Sparql::SparqlClient.new("http://api.talis.com/stores/testing/services/sparql", mc)
    response = client.describe_uri("http://www.example.org")
    assert_equal("RESULTS", response.content)
  end

  def test_describe_uri_using_cbd
    mc = mock()
    mc.expects(:get).with("http://api.talis.com/stores/testing/services/sparql", {"query" => "DESCRIBE <http://www.example.org>"}, {"Accept" => "application/rdf+xml"} ).returns(
      HTTP::Message.new_response("RESULTS"))
    
    client = Pho::Sparql::SparqlClient.new("http://api.talis.com/stores/testing/services/sparql", mc)
    response = client.describe_uri("http://www.example.org", "application/rdf+xml", :cbd)
    assert_equal("RESULTS", response.content)
  end

  def test_describe_uri_using_lcbd
    mc = mock()
    mc.expects(:get).with("http://api.talis.com/stores/testing/services/sparql", anything, {"Accept" => "application/rdf+xml"} ).returns(
      HTTP::Message.new_response("RESULTS"))
    
    client = Pho::Sparql::SparqlClient.new("http://api.talis.com/stores/testing/services/sparql", mc)
    response = client.describe_uri("http://www.example.org", "application/rdf+xml", :lcbd)
    assert_equal("RESULTS", response.content)
  end  

  def test_describe_uri_using_scbd
    mc = mock()
    mc.expects(:get).with("http://api.talis.com/stores/testing/services/sparql", anything, {"Accept" => "application/rdf+xml"} ).returns(
      HTTP::Message.new_response("RESULTS"))
    
    client = Pho::Sparql::SparqlClient.new("http://api.talis.com/stores/testing/services/sparql", mc)
    response = client.describe_uri("http://www.example.org", "application/rdf+xml", :scbd)
    assert_equal("RESULTS", response.content)
  end  
          
  def test_describe_uri_using_slcbd
    mc = mock()
    mc.expects(:get).with("http://api.talis.com/stores/testing/services/sparql", anything, {"Accept" => "application/rdf+xml"} ).returns(
      HTTP::Message.new_response("RESULTS"))
    
    client = Pho::Sparql::SparqlClient.new("http://api.talis.com/stores/testing/services/sparql", mc)
    response = client.describe_uri("http://www.example.org", "application/rdf+xml", :slcbd)
    assert_equal("RESULTS", response.content)
  end  

  def test_describe_uri_using_unknown
    mc = mock()
        
    client = Pho::Sparql::SparqlClient.new("http://api.talis.com/stores/testing/services/sparql", mc)
    assert_raises RuntimeError do
        response = client.describe_uri("http://www.example.org", "application/rdf+xml", :unknown)
    end
    
  end  
    
end