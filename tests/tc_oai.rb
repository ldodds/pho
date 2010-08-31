$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'pho'
require 'test/unit'
require 'mocha'
require 'rexml/document'
require 'date'
class OAITest < Test::Unit::TestCase

NO_RECORDS = <<-EOL
  <OAI-PMH xmlns="http://www.openarchives.org/OAI/2.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
   xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/ http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd">
   <responseDate>2010-04-04T14:33:00Z</responseDate>
   <request from="2010-04-04T14:33:00Z" metadataPrefix="oai_dc" verb="ListRecords">http://api.talis.com/stores/ldodds-dev2/services/oai-pmh</request>
   <error code="noRecordsMatch">No matching records were found</error></OAI-PMH>
EOL

LIST_RECORDS = <<-EOL 
  <OAI-PMH xmlns="http://www.openarchives.org/OAI/2.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/ http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd">
  <responseDate>2010-03-19T13:02:14Z</responseDate>
  <request from="2010-03-19T13:02:14Z" metadataPrefix="oai_dc" verb="ListRecords">http://api.talis.com/stores/ldodds-dev1/services/oai-pmh</request>
  <ListRecords>
  <record><header><identifier>http://www.example.org</identifier><datestamp>2010-03-19T12:57:06Z</datestamp></header>
  <metadata><oai_dc:dc xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/">
  <dc:identifier>http://www.example.org</dc:identifier></oai_dc:dc></metadata>
  </record>
  <record><header><identifier>http://api.talis.com/stores/ldodds-dev1/items/atom.xml</identifier><datestamp>2010-03-19T12:57:10Z</datestamp></header>
  <metadata><oai_dc:dc xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/">
  <dc:identifier>http://api.talis.com/stores/ldodds-dev1/items/atom.xml</dc:identifier></oai_dc:dc></metadata>
  </record>  
  </ListRecords></OAI-PMH> 
EOL

LIST_RECORDS_WITH_TOKEN = <<-EOL 
    <OAI-PMH xmlns="http://www.openarchives.org/OAI/2.0/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/ http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd">
    <responseDate>2010-03-19T13:02:14Z</responseDate>
    <request from="2010-03-19T13:02:14Z" metadataPrefix="oai_dc" verb="ListRecords">http://api.talis.com/stores/ldodds-dev1/services/oai-pmh</request>
    <ListRecords>
    <record><header><identifier>http://www.example.org</identifier><datestamp>2010-03-19T12:57:06Z</datestamp></header>
    <metadata><oai_dc:dc xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/">
    <dc:identifier>http://www.example.org</dc:identifier></oai_dc:dc></metadata>
    </record>
    <record><header><identifier>http://api.talis.com/stores/ldodds-dev1/items/atom.xml</identifier><datestamp>2010-03-19T12:57:10Z</datestamp></header>
    <metadata><oai_dc:dc xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/">
    <dc:identifier>http://api.talis.com/stores/ldodds-dev1/items/atom.xml</dc:identifier></oai_dc:dc></metadata>
    </record>
    <resumptionToken completeListSize="6151294" cursor="0">b2FpX2RjfDEwMHwxOTcwLTAxLTAxVDAwOjAwOjAwWnwyMDEwLTA0LTA0VDEzOjU0OjMyWg==</resumptionToken>  
    </ListRecords></OAI-PMH> 
EOL
  
  def test_request
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/services/oai-pmh", {"verb" => "ListRecords", "metadataPrefix" => "oai_dc"} ).returns(
      HTTP::Message.new_response(LIST_RECORDS))
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    response = store.list_records()
    assert_equal(LIST_RECORDS, response.content)         
  end    
  
  def test_parse_no_records
    results = Pho::OAI::Records.parse(NO_RECORDS)
    assert_nil(results)    
  end
  
  def test_request_with_from
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/services/oai-pmh", {"verb" => "ListRecords", "metadataPrefix" => "oai_dc", "from" => "2010-03-19T13:02:14Z"} ).returns(
      HTTP::Message.new_response(LIST_RECORDS))
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    response = store.list_records("2010-03-19T13:02:14Z")
    assert_equal(LIST_RECORDS, response.content)         

    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/services/oai-pmh", {"verb" => "ListRecords", "metadataPrefix" => "oai_dc", "from" => "2010-03-19T13:02:14Z"} ).returns(
      HTTP::Message.new_response(LIST_RECORDS))
        
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    response = store.list_records(DateTime.parse("2010-03-19T13:02:14Z"))
    assert_equal(LIST_RECORDS, response.content)       
  end 

  def test_request_with_to
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/services/oai-pmh", {"verb" => "ListRecords", "metadataPrefix" => "oai_dc", "until" => "2010-03-19T13:02:14Z"} ).returns(
      HTTP::Message.new_response(LIST_RECORDS))
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    response = store.list_records(nil, "2010-03-19T13:02:14Z")
    assert_equal(LIST_RECORDS, response.content)         

    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/services/oai-pmh", {"verb" => "ListRecords", "metadataPrefix" => "oai_dc", "until" => "2010-03-19T13:02:14Z"} ).returns(
      HTTP::Message.new_response(LIST_RECORDS))
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    response = store.list_records(nil, DateTime.parse("2010-03-19T13:02:14Z"))  
    assert_equal(LIST_RECORDS, response.content)               
  end
        
  def test_request_with_token
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/services/oai-pmh", {"verb" => "ListRecords", "metadataPrefix" => "oai_dc", "resumptionToken" => "abc"} ).returns(
      HTTP::Message.new_response(LIST_RECORDS))
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
    response = store.list_records(nil, nil, "abc")
    assert_equal(LIST_RECORDS, response.content)         
  end
    
  def test_parse
  
    results = Pho::OAI::Records.parse(LIST_RECORDS)
    assert_not_nil(results)
    assert_equal(2010, results.from.year)
    assert_equal(3, results.from.month)
    assert_equal(nil, results.to)
    assert_equal(2, results.records.size)  
    assert_equal("http://www.example.org", results.records[0].identifier)    
    assert_equal(2010, results.records[0].datestamp.year)
    assert_equal("http://api.talis.com/stores/ldodds-dev1/items/atom.xml", results.records[1].identifier)
    assert_equal(2010, results.records[1].datestamp.year)
  end
  
  def test_parse_with_token
  
    results = Pho::OAI::Records.parse(LIST_RECORDS_WITH_TOKEN)
    assert_not_nil(results)
    assert_equal(6151294, results.list_size)
    assert_equal(0, results.cursor)
    assert_equal("b2FpX2RjfDEwMHwxOTcwLTAxLTAxVDAwOjAwOjAwWnwyMDEwLTA0LTA0VDEzOjU0OjMyWg==", results.resumption_token)
  end  
  
  def test_statistics_last_updated
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/services/oai-pmh", {"verb" => "ListRecords", "metadataPrefix" => "oai_dc"} ).returns(
      HTTP::Message.new_response(LIST_RECORDS))
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)

    updated = Pho::OAI::Statistics.last_updated(store)    
    assert_equal(DateTime.parse("2010-03-19T12:57:06Z"), updated)    
  end

  def test_statistics_num_entities
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/services/oai-pmh", {"verb" => "ListRecords", "metadataPrefix" => "oai_dc"} ).returns(
      HTTP::Message.new_response(LIST_RECORDS))
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
  
    size = Pho::OAI::Statistics.num_of_entities(store)    
    assert_equal(2, size)    
  end    

  def test_statistics_num_entities_with_resumption
    mc = mock()
    mc.expects(:set_auth)
    mc.expects(:get).with("http://api.talis.com/stores/testing/services/oai-pmh", {"verb" => "ListRecords", "metadataPrefix" => "oai_dc"} ).returns(
      HTTP::Message.new_response(LIST_RECORDS_WITH_TOKEN))
    
    store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass", mc)
  
    size = Pho::OAI::Statistics.num_of_entities(store)    
    assert_equal(6151294, size)    
  end  

end
