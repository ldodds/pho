$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'pho'
require 'test/unit'
require 'mocha'

class EnrichmentTest < Test::Unit::TestCase
  
  RDFXML = <<-EOL 
  <rdf:RDF xmlns:rdf      = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
           xmlns:ex       = "http://www.example.org/ns/">
  
    <rdf:Description rdf:about="http://www.example.org">
      <ex:resource rdf:resource="http://www.example.org/page"/>
    </rdf:Description>
    
  </rdf:RDF>    
  EOL

  def test_merge()
    
    query = "DESCRIBE <http://www.example.org>"
    mock_store = mock()
    mock_store.expects(:store_data).with(RDFXML).returns( HTTP::Message.new_response("OK") )
    
    mc = mock()
    mc.expects(:query).with( query, "application/rdf+xml" ).returns( HTTP::Message.new_response(RDFXML) )
    
    enricher = Pho::Enrichment::StoreEnricher.new(mock_store, mc)
    resp = enricher.merge(query) 
    assert_not_nil(resp)

  end

  def test_merge_with_block()
    
    query = "DESCRIBE <http://www.example.org>"
    mock_store = mock()
    mock_store.expects(:store_data).with(RDFXML).returns( HTTP::Message.new_response("OK") )
    
    mc = mock()
    mc.expects(:query).with( query, "application/rdf+xml" ).returns( HTTP::Message.new_response(RDFXML) )
    
    enricher = Pho::Enrichment::StoreEnricher.new(mock_store, mc)
    resp = enricher.merge(query) do |resp, data|
      assert_equal( 200, resp.status )
      assert_equal( RDFXML, data)
    end 
    
    assert_not_nil(resp)

  end
    
  def test_merge_with_failed_query()
    
    query = "DESCRIBE <http://www.example.org>"
    mock_store = mock()
    
    mc = mock()
    msg = HTTP::Message.new_response("Error")
    msg.status = 500
    mc.expects(:query).with( query, "application/rdf+xml" ).returns( msg )
    
    enricher = Pho::Enrichment::StoreEnricher.new(mock_store, mc)
    assert_raises RuntimeError do        
        results = enricher.merge(query)
    end

  end
  
  def test_merge_with_failed_store()
    
    query = "DESCRIBE <http://www.example.org>"
    mock_store = mock()
    msg = HTTP::Message.new_response("Error")
    msg.status = 500    
    mock_store.expects(:store_data).with(RDFXML).returns( msg )
    
    mc = mock()
    mc.expects(:query).with( query, "application/rdf+xml" ).returns( HTTP::Message.new_response(RDFXML) )
    
    enricher = Pho::Enrichment::StoreEnricher.new(mock_store, mc)
    resp = enricher.merge(query) 
    assert_equal(500, resp.status)
    
  end
  
  def test_infer()
    query = "CONSTRUCT { ?s ex:foo ?o } WHERE { ?s ex:bar ?o }"
        
    mc = mock()
    mc.expects(:query).with( query, "application/rdf+xml" ).returns( HTTP::Message.new_response(RDFXML) )

    mock_store = mock()
    mock_store.expects(:sparql_client).returns(mc)
    mock_store.expects(:store_data).with(RDFXML).returns( HTTP::Message.new_response("OK") )
       
    resp = Pho::Enrichment::StoreEnricher.infer(mock_store, query) 
    assert_not_nil(resp)

  end  

  def test_infer_with_block()
    query = "CONSTRUCT { ?s ex:foo ?o } WHERE { ?s ex:bar ?o }"
        
    mc = mock()
    mc.expects(:query).with( query, "application/rdf+xml" ).returns( HTTP::Message.new_response(RDFXML) )

    mock_store = mock()
    mock_store.expects(:sparql_client).returns(mc)
    mock_store.expects(:store_data).with(RDFXML).returns( HTTP::Message.new_response("OK") )
       
    resp = Pho::Enrichment::StoreEnricher.infer(mock_store, query) do |resp, data|
        assert_equal(200, resp.status)
        assert_equal(RDFXML, data)      
    end 
    
    assert_not_nil(resp)

  end        
end