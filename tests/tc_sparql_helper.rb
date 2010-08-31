$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'pho'
require 'test/unit'
require 'mocha'

class SparqlHelperTest < Test::Unit::TestCase
  
  SELECT_QUERY = <<-EOL
  SELECT ?name WHERE { ?s rdfs:label ?name. }
  EOL

  ASK_QUERY = <<-EOL
  ASK WHERE { ?s rdfs:label "Something". }
  EOL
      
  DESCRIBE_QUERY = <<-EOL
  DESCRIBE <http://www.example.org>
  EOL
  
  CONSTRUCT_QUERY = <<-EOL
  CONSTRUCT { ?s ?p ?o. } WHERE { ?s ?p ?o. } 
  EOL
  
  RESULTS = <<-EOL
  {  
   "head": {  "vars": [ "name" ]  } ,  
    
   "results": {    
        "bindings": [     
            {  "name": { "type": "literal" , "value": "Apollo 11 Command and Service Module (CSM)" }
            } ,     
           {   "name": { "type": "literal" , "value": "Apollo 11 SIVB" }
           } ,      
           {   "name": { "type": "literal" , "value": "Apollo 11 Lunar Module / EASEP" }
           }    
        ]  
    }
  }  
  EOL
  
  RESULTS_NO_BINDING = <<-EOL
  {  
   "head": {  "vars": [ "name" ]  } ,  
    
   "results": {    
        "bindings": [     
           { } ,     
           {   "name": { "type": "literal" , "value": "Apollo 11 SIVB" }
           }   
        ]  
    }
  }  
  EOL
    
  ASK_RESULTS = <<-EOL
  {    
    "head": {},
    "boolean": "true"
  }
  EOL

  RDF_JSON_RESULTS = <<-EOL
  {
    "http://www.example.org" : {
      "http://www.example.org/ns/resource" : [ { "value" : "http://www.example.org/page", "type" : "uri" } ]
    }
  }
  EOL
      
  RDF_JSON = <<-EOL
  {  
   "head": {  "vars": [ "name" ]  } ,  
    
   "results": {    
        "bindings": [     
            {  "name": { "type": "literal" , "value": "Apollo 11 Command and Service Module (CSM)" },
               "uri": { "type": "uri" , "value": "http://nasa.dataincubator.org/spacecraft/12345" },
               "mass": { "type": "literal" , "value": "5000.5", "datatype" : "http://www.w3.org/2001/XMLSchema#float" }
            } ,     
           {   "name": { "type": "literal" , "value": "Apollo 11 SIVB" },
               "uri": { "type": "uri" , "value": "http://nasa.dataincubator.org/spacecraft/12345" }
           }    
        ]  
    }
  }  
  EOL
    
  def test_apply_initial_bindings
      query = "SELECT ?p ?o WHERE { ?s ?p ?o }"
      values = { "s" => "<http://www.example.org>" }
        
      bound = Pho::Sparql::SparqlHelper.apply_initial_bindings(query, values)
      assert_not_nil(bound)
      assert_equal( "SELECT ?p ?o WHERE { <http://www.example.org> ?p ?o }", bound )   
  end

  def test_apply_initial_bindings_with_dollars
      query = "SELECT $p $o WHERE { $s $p $o }"
      values = { "s" => "<http://www.example.org>" }
        
      bound = Pho::Sparql::SparqlHelper.apply_initial_bindings(query, values)
      assert_not_nil(bound)
      assert_equal( "SELECT $p $o WHERE { <http://www.example.org> $p $o }", bound )   
  end
  
  def test_apply_initial_bindings_with_literal
      query = "SELECT ?s WHERE { ?s ?p ?o }"
      values = { "o" => "'some value'" }
        
      bound = Pho::Sparql::SparqlHelper.apply_initial_bindings(query, values)
      assert_not_nil(bound)
      assert_equal( "SELECT ?s WHERE { ?s ?p 'some value' }", bound )   
  end   

  def test_select
      mc = mock()
      mc.expects(:select).with(SELECT_QUERY, Pho::Sparql::SPARQL_RESULTS_JSON).returns(
        HTTP::Message.new_response(RESULTS) )
      json = Pho::Sparql::SparqlHelper.select(SELECT_QUERY, mc)
      assert_not_nil(json)
      assert_equal("name", json["head"]["vars"][0])       
  end

  def test_failed_select
      mc = mock()
      resp = HTTP::Message.new_response("Error")
      resp.status = 500
      mc.expects(:select).with(SELECT_QUERY, Pho::Sparql::SPARQL_RESULTS_JSON).returns( resp )
      assert_raises RuntimeError do
        json = Pho::Sparql::SparqlHelper.select(SELECT_QUERY, mc)
      end
  end
  
  def test_ask
      mc = mock()
      mc.expects(:select).with(ASK_QUERY, Pho::Sparql::SPARQL_RESULTS_JSON).returns(
        HTTP::Message.new_response(ASK_RESULTS) )
      assert_equal( true,  Pho::Sparql::SparqlHelper.ask(ASK_QUERY, mc) )       
  end

  def test_select_values
      mc = mock()
      mc.expects(:select).with(SELECT_QUERY, Pho::Sparql::SPARQL_RESULTS_JSON).returns(
        HTTP::Message.new_response(RESULTS) )
      results = Pho::Sparql::SparqlHelper.select_values(SELECT_QUERY, mc)
      assert_not_nil( results )
      assert_equal( 3, results.length )
  end        

  def test_select_values_with_empty_binding
      mc = mock()
      mc.expects(:select).with(SELECT_QUERY, Pho::Sparql::SPARQL_RESULTS_JSON).returns(
        HTTP::Message.new_response(RESULTS_NO_BINDING) )
      results = Pho::Sparql::SparqlHelper.select_values(SELECT_QUERY, mc)
      assert_not_nil( results )
      assert_equal( 1 , results.length )
  end
    
  def test_select_single_value
      mc = mock()
      mc.expects(:select).with(SELECT_QUERY, Pho::Sparql::SPARQL_RESULTS_JSON).returns(
        HTTP::Message.new_response(RESULTS) )
      result = Pho::Sparql::SparqlHelper.select_single_value(SELECT_QUERY, mc)
      assert_equal( "Apollo 11 Command and Service Module (CSM)", result  )
  end        

  def test_describe_to_resource_hash
      mc = mock()
      mc.expects(:describe).with(DESCRIBE_QUERY, "application/json").returns( HTTP::Message.new_response(RDF_JSON_RESULTS) )
      result = Pho::Sparql::SparqlHelper.describe_to_resource_hash(DESCRIBE_QUERY, mc)
      assert_not_nil(result)
      assert_not_nil(result["http://www.example.org"])         
  end

  def test_failed_describe
      mc = mock()
      resp = HTTP::Message.new_response("Error")
      resp.status = 500
      mc.expects(:describe).with(DESCRIBE_QUERY, "application/json").returns( resp )
      assert_raises RuntimeError do
        Pho::Sparql::SparqlHelper.describe_to_resource_hash(DESCRIBE_QUERY, mc)
      end
  end
      
  def test_construct_to_resource_hash
      mc = mock()
      mc.expects(:construct).with(CONSTRUCT_QUERY, "application/json").returns( HTTP::Message.new_response(RDF_JSON_RESULTS) )
      result = Pho::Sparql::SparqlHelper.construct_to_resource_hash(CONSTRUCT_QUERY, mc)
      assert_not_nil(result)
      assert_not_nil(result["http://www.example.org"])         
  end  
  
  def test_failed_construct
      mc = mock()
      resp = HTTP::Message.new_response("Error")
      resp.status = 500
      mc.expects(:construct).with(CONSTRUCT_QUERY, "application/json").returns( resp )
      assert_raises RuntimeError do
        Pho::Sparql::SparqlHelper.construct_to_resource_hash(CONSTRUCT_QUERY, mc)
      end
  end
  
  def test_multi_describe
      uris = []
      uris << "http://www.example.org"
      uris << "http://www.example.com"         
      mc = mock()
      mc.expects(:multi_describe).with(uris, "application/json").returns( 
        HTTP::Message.new_response(RDF_JSON_RESULTS) )
        
      result = Pho::Sparql::SparqlHelper.multi_describe(uris, mc)
      assert_not_nil(result)
      assert_not_nil(result["http://www.example.org"])         
  end
     
  def test_binding_to_hash
      json = JSON.parse(RDF_JSON)
      binding = json["results"]["bindings"][0]
      
      hash = Pho::Sparql::SparqlHelper.result_to_query_binding(binding)
      assert_equal(3, hash.size)
      assert_equal("\"Apollo 11 Command and Service Module (CSM)\"", hash["name"])
      assert_equal("<http://nasa.dataincubator.org/spacecraft/12345>", hash["uri"])
      assert_equal("\"5000.5\"^^http://www.w3.org/2001/XMLSchema#float", hash["mass"])        
  end
  
  def test_results_to_bindings
      json = JSON.parse(RDF_JSON)           
      bindings = Pho::Sparql::SparqlHelper.results_to_query_bindings(json)
      assert_equal(2, bindings.size)
      hash = bindings[0]
      assert_equal("\"Apollo 11 Command and Service Module (CSM)\"", hash["name"])
      assert_equal("<http://nasa.dataincubator.org/spacecraft/12345>", hash["uri"])
      assert_equal("\"5000.5\"^^http://www.w3.org/2001/XMLSchema#float", hash["mass"])        
  end    

  def test_describe_uri
      mc = mock()
      mc.expects(:describe_uri).with("http://www.example.org", "application/json", :cbd).returns( HTTP::Message.new_response(RDF_JSON_RESULTS) )
      result = Pho::Sparql::SparqlHelper.describe_uri("http://www.example.org", mc)
      assert_not_nil(result)
      assert_not_nil(result["http://www.example.org"])         
  end  

  def test_describe_uri_with_type
      mc = mock()
      mc.expects(:describe_uri).with("http://www.example.org", "application/json", :slcbd).returns( HTTP::Message.new_response(RDF_JSON_RESULTS) )
      result = Pho::Sparql::SparqlHelper.describe_uri("http://www.example.org", mc, :slcbd)
      assert_not_nil(result)
      assert_not_nil(result["http://www.example.org"])         
  end        

  def test_exists
      mc = mock()
      mc.expects(:select).with("ASK { <http://www.example.org> ?p ?o }", Pho::Sparql::SPARQL_RESULTS_JSON).returns(
        HTTP::Message.new_response(ASK_RESULTS) )  
      result = Pho::Sparql::SparqlHelper.exists("http://www.example.org", mc)
      assert_equal( true, result )
      
  end
    
end
