$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'pho'
require 'test/unit'
require 'mocha'
require 'rexml/document'

class FacetTest < Test::Unit::TestCase

  RESULTS = <<-EOL
  <facet-results xmlns="http://schemas.talis.com/2007/facet-results#">
    <head>
      <query>austen</query>
      <fields>title,author,publisher</fields>
    </head>
  <fields>
    <field name="title">
      <term number="19" search-uri="http://api.talis.com/stores/testing/items?query=austen+title:%22Pride+and+prejudice%22">Pride and prejudice</term>
      <term number="12" search-uri="http://api.talis.com/stores/testing/items?query=austen+title:%22Emma%22">Emma</term>
      <term number="9" search-uri="http://api.talis.com/stores/testing/items?query=austen+title:%22Northanger+Abbey%22">Northanger Abbey</term>
      <term number="8" search-uri="http://api.talis.com/stores/testing/items?query=austen+title:%22Mansfield+Park%22">Mansfield Park</term>
    </field>
    <field name="publisher"/>
  
  <field name="author">
    <term number="91" search-uri="http://api.talis.com/stores/testing/items?query=austen+author:%22Austen,+Jane%22">Austen, Jane</term>
    <term number="6" search-uri="http://api.talis.com/stores/testing/items?query=austen+author:%22Jane+Austen+Society.%22">Jane Austen Society.</term>
    <term number="3" search-uri="http://api.talis.com/stores/testing/items?query=austen+author:%22Evans,+J.+M.+(Jessie+Maud)%22">Evans, J. M. (Jessie Maud)</term>
    <term number="3" search-uri="http://api.talis.com/stores/testing/items?query=austen+author:%22Chapman,+R.+W.+(Robert+William)%22">Chapman, R. W. (Robert William)</term>
  </field>

  </fields>
    
  </facet-results>  
EOL

    def test_parse
      
      results = Pho::Facet::Results.parse(RESULTS)
      
      assert_equal("austen", results.query)
      assert_equal("title,author,publisher", results.fields)
      assert_equal(3, results.facets.size)
      
      assert_equal(4, results.facets["title"].length)
      assert_expected_term(results.facets["title"][0], 
        19, "http://api.talis.com/stores/testing/items?query=austen+title:%22Pride+and+prejudice%22", "Pride and prejudice")
      assert_expected_term(results.facets["title"][1], 
        12, "http://api.talis.com/stores/testing/items?query=austen+title:%22Emma%22", "Emma")
      assert_expected_term(results.facets["title"][2], 
        9, "http://api.talis.com/stores/testing/items?query=austen+title:%22Northanger+Abbey%22", "Northanger Abbey")              
      assert_expected_term(results.facets["title"][3], 
        8, "http://api.talis.com/stores/testing/items?query=austen+title:%22Mansfield+Park%22", "Mansfield Park")              
                      
      assert_equal(0, results.facets["publisher"].length)
                  
      assert_equal(4, results.facets["author"].length)
      assert_expected_term(results.facets["author"][0], 
        91, "http://api.talis.com/stores/testing/items?query=austen+author:%22Austen,+Jane%22", "Austen, Jane")
      assert_expected_term(results.facets["author"][1], 
        6, "http://api.talis.com/stores/testing/items?query=austen+author:%22Jane+Austen+Society.%22", "Jane Austen Society.")
      assert_expected_term(results.facets["author"][2], 
        3, "http://api.talis.com/stores/testing/items?query=austen+author:%22Evans,+J.+M.+(Jessie+Maud)%22", "Evans, J. M. (Jessie Maud)")
      assert_expected_term(results.facets["author"][3], 
        3, "http://api.talis.com/stores/testing/items?query=austen+author:%22Chapman,+R.+W.+(Robert+William)%22", "Chapman, R. W. (Robert William)")
      
    end
   
    def test_read_from_store
      mc = mock()
      mc.expects(:set_auth)
      mc.expects(:get).with("http://api.talis.com/stores/testing/services/facet", 
        {"query" => "austen", "fields" => "title,author,publisher", "output" => "xml"}, nil).returns(
        HTTP::Message.new_response(RESULTS))
      
      store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
      
      results = Pho::Facet::Results.read_from_store(store, "austen", ["title", "author", "publisher"]) 

      assert_not_nil(results)
      assert_equal("austen", results.query)
      assert_equal("title,author,publisher", results.fields)
      assert_equal(3, results.facets.size)
        
    end   
    
    def assert_expected_term(term, hits, search_uri, value)
      assert_equal(hits, term.hits)
      assert_equal(search_uri, term.search_uri)
      assert_equal(value, term.value)
    end
end