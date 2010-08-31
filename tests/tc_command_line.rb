$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'pho'
require 'test/unit'
require 'mocha'

class CommandLineTest < Test::Unit::TestCase
  
  TEST_FPMAP = <<-EOL
  {
    "http:\/\/api.talis.com\/stores\/testing\/config\/fpmaps\/1#description" : {
      "http:\/\/schemas.talis.com\/2006\/frame\/schema#property" : [ { "value" : "http:\/\/purl.org\/dc\/elements\/1.1\/description", "type" : "uri" } ],
      "http:\/\/schemas.talis.com\/2006\/frame\/schema#name" : [ { "value" : "description", "type" : "literal" } ]
    },
    "http:\/\/api.talis.com\/stores\/testing\/config\/fpmaps\/1" : {
      "http:\/\/www.w3.org\/2000\/01\/rdf-schema#label" : [ { "value" : "default field\/predicate map", "type" : "literal" } ],
      "http:\/\/www.w3.org\/1999\/02\/22-rdf-syntax-ns#type" : [ { "value" : "http:\/\/schemas.talis.com\/2006\/bigfoot\/configuration#FieldPredicateMap", "type" : "uri" } ],
      "http:\/\/schemas.talis.com\/2006\/frame\/schema#mappedDatatypeProperty" : [ 
        { "value" : "http:\/\/api.talis.com\/stores\/testing\/config\/fpmaps\/1#name", "type" : "uri" },
        { "value" : "http:\/\/api.talis.com\/stores\/testing\/config\/fpmaps\/1#title", "type" : "uri" },
        { "value" : "http:\/\/api.talis.com\/stores\/testing\/config\/fpmaps\/1#description", "type" : "uri" }
      ]
    },
    "http:\/\/api.talis.com\/stores\/testing\/config\/fpmaps\/1#title" : {
      "http:\/\/schemas.talis.com\/2006\/frame\/schema#property" : [ { "value" : "http:\/\/purl.org\/dc\/elements\/1.1\/title", "type" : "uri" } ],
      "http:\/\/schemas.talis.com\/2006\/frame\/schema#name" : [ { "value" : "title", "type" : "literal" } ]
    },
    "http:\/\/api.talis.com\/stores\/testing\/config\/fpmaps\/1#name" : {
      "http:\/\/schemas.talis.com\/2006\/frame\/schema#property" : [ { "value" : "http:\/\/xmlns.com\/foaf\/0.1\/name", "type" : "uri" } ],
      "http:\/\/schemas.talis.com\/2006\/frame\/schema#name" : [ { "value" : "name", "type" : "literal" } ]
    }
  }  
EOL
  
  TEST_QP = <<-EOL
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
    @opts = {}
    @opts["username"] = "tester"
    @opts["password"] = "pass"
    @opts["store"] = "testing"
    
  end
  
  def teardown
  end
  
  def test_fpmap()
    mc = mock()
    mc.expects(:build_uri).returns( "http://api.talis.com/stores/testing/config/fpmaps/1" )
    mc.expects(:get_field_predicate_map).returns( HTTP::Message.new_response(TEST_FPMAP) )
    
    s = StringIO.new()
    cmdline = Pho::CommandLine.new(@opts, {}, mc)
    cmdline.fpmap(s)
    
    lines = s.string().split("\n")
    assert_equal("description -> http://purl.org/dc/elements/1.1/description", lines[0])
    assert_equal("name -> http://xmlns.com/foaf/0.1/name", lines[1])
    assert_equal("title -> http://purl.org/dc/elements/1.1/title", lines[2])
  end

  def test_fpmap_raw()
    mc = mock()
    mc.expects(:get_field_predicate_map).returns( HTTP::Message.new_response(TEST_FPMAP) )
    
    s = StringIO.new()
    @opts["raw"] = ""
    cmdline = Pho::CommandLine.new(@opts, {}, mc)
    cmdline.fpmap(s)
    assert_equal(TEST_FPMAP, s.string)    
  end
  
  def test_queryprofile_raw()
    mc = mock()
    mc.expects(:get_query_profile).returns( HTTP::Message.new_response(TEST_QP) )
    
    s = StringIO.new()
    @opts["raw"] = ""    
    cmdline = Pho::CommandLine.new(@opts, {}, mc )
    cmdline.queryprofile(s)
    assert_equal(TEST_QP, s.string)      
  end
  
  def test_queryprofile()
    mc = mock()
    mc.expects(:build_uri).returns( "http://api.talis.com/stores/testing/config/queryprofiles/1" )
    mc.expects(:get_query_profile).returns( HTTP::Message.new_response(TEST_QP) )
    
    s = StringIO.new()
    cmdline = Pho::CommandLine.new(@opts,  {}, mc)
    cmdline.queryprofile(s)
    
    lines = s.string().split("\n")
    assert_equal("name -> 2.0", lines[0])
    assert_equal("nick -> 1.0", lines[1])  
  end

  def test_username()
    opts = {}
    env = {}
    
    assert_raise RuntimeError do
      cmdline = Pho::CommandLine.new(opts, env, mock())      end
        
    opts["username"] = "tester"
    opts["password"] = "pass"
    cmdline = Pho::CommandLine.new(opts, env, mock())
    assert_equal("tester", cmdline.username)
    
    opts = {}
    opts["password"] = "pass"
    env["TALIS_USER"] = "tester"
    cmdline = Pho::CommandLine.new(opts, env, mock())
    assert_equal("tester", cmdline.username)
    
    opts["username"] = "override"
    cmdline = Pho::CommandLine.new(opts, env, mock())
    assert_equal("override", cmdline.username)    
  end

  def test_password()
    opts = {}
    env = {}
    
    opts["username"] = "tester"
    assert_raise RuntimeError do
     cmdline = Pho::CommandLine.new(opts, env, mock())
    end
        
    opts["password"] = "pass"
    cmdline = Pho::CommandLine.new(opts, env, mock())
    assert_equal("pass", cmdline.password)
    
    opts = {}
    opts["username"] = "tester"
    env["TALIS_PASS"] = "pass"
    cmdline = Pho::CommandLine.new(opts, env, mock())
    assert_equal("pass", cmdline.password)
    
    opts["password"] = "override"
    cmdline = Pho::CommandLine.new(opts, env, mock())
    assert_equal("override", cmdline.password)    
   end
   
   def test_store()
     opts = {}
     env = {}
     opts["username"] = "tester"
     opts["password"] = "pass"
     cmdline = Pho::CommandLine.new(opts, env, mock())
     assert_equal(nil, cmdline.storename)
     
     opts["store"] = "http://api.talis.com/stores/testing"
     cmdline = Pho::CommandLine.new(opts, env, mock())
     assert_equal("http://api.talis.com/stores/testing", cmdline.storename)

     opts["store"] = "testing"
     cmdline = Pho::CommandLine.new(opts, env, mock())
     assert_equal("http://api.talis.com/stores/testing", cmdline.storename)
     
     opts = {}
     opts["username"] = "tester"
     opts["password"] = "pass"
     env["TALIS_STORE"] = "http://api.talis.com/stores/testing"
     cmdline = Pho::CommandLine.new(opts, env, mock())
     assert_equal("http://api.talis.com/stores/testing", cmdline.storename)
    
     env["TALIS_STORE"] = "testing"
     cmdline = Pho::CommandLine.new(opts, env, mock())
     assert_equal("http://api.talis.com/stores/testing", cmdline.storename)
     
     opts["store"] = "override"
     cmdline = Pho::CommandLine.new(opts, env, mock())
     assert_equal("http://api.talis.com/stores/override", cmdline.storename)

   end

   def test_add_mapping()
      mc = mock()
      mc.expects(:build_uri).with("/config/fpmaps/1").returns( "http://api.talis.com/stores/testing/config/fpmaps/1" )
      mc.expects(:get_field_predicate_map).returns( HTTP::Message.new_response(TEST_FPMAP) )
      mc.expects(:build_uri).with("/config/fpmaps/1#test").returns( "http://api.talis.com/stores/testing/config/fpmaps/1#test" )
      mc.expects(:put_field_predicate_map).returns( HTTP::Message.new_response("") )
      
      @opts["field"] = "test"
      @opts["predicate"] = "http://www.example.org/test"
      
      s = StringIO.new()
      cmdline = Pho::CommandLine.new(@opts, {}, mc)
      cmdline.add_mapping(s)
      assert_equal("FieldPredicate map successfully updated\n", s.string)      
   end
   
   def test_add_weight()
      mc = mock()
      mc.expects(:build_uri).with("/config/queryprofiles/1").returns( "http://api.talis.com/stores/testing/config/queryprofiles/1")
      mc.expects(:get_query_profile).returns( HTTP::Message.new_response(TEST_QP) )
      mc.expects(:build_uri).with("/config/queryprofiles/1#test").returns("http://api.talis.com/stores/testing/config/queryprofiles/1#test" )
      mc.expects(:put_query_profile).returns( HTTP::Message.new_response("") )
      
      @opts["field"] = "test"
      @opts["weight"] = "10.0"
      
      s = StringIO.new()
      cmdline = Pho::CommandLine.new(@opts, {}, mc)
      cmdline.add_weight(s)
      assert_equal("QueryProfile successfully updated\n", s.string)     
   end
   
end
