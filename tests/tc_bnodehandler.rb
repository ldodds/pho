$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'pho'
require 'test/unit'
require 'mocha'

class BNodeRewritingHandlerTest < Test::Unit::TestCase
  
  def test_uris_are_not_changed()
    handler = Pho::FileManagement::BNodeRewritingHandler.new("http://example.org")
    
    subject = RDF::URI.new("http://example.org/subject")
    object = RDF::URI.new("http://example.org/object")
    
    statement = RDF::Statement.new(subject, RDF::RDFS.label, object)
    
    handled = handler.handle(statement)
    
    assert_equal( statement.subject, handled.subject)
    assert_equal( statement.predicate, handled.predicate)
    assert_equal( statement.object, handled.object)
    
  end
  
  def test_uri_assignment()
    handler = Pho::FileManagement::BNodeRewritingHandler.new("http://example.org")
    
    subject = RDF::Node.new
    object = RDF::Node.new
    
    statement = RDF::Statement.new(subject, RDF::RDFS.label, object)    
    handled = handler.handle(statement)
    
    assert_equal(statement.predicate, handled.predicate)
    assert_equal(false, handled.subject.anonymous?)
    assert_equal(false, handled.object.anonymous?)
    assert_equal("http://example.org/#{Digest::MD5.hexdigest( subject.id )}", 
      handled.subject.to_s)
    assert_equal("http://example.org/#{Digest::MD5.hexdigest( object.id )}", 
      handled.object.to_s)    
    
  end
end