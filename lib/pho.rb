require 'rubygems'
require 'httpclient'
require 'json'
require 'yaml'
require 'date'
require 'rexml/document'
require 'md5'

#RDF.rb
require 'rdf'
require 'rdf/json'
#this requires raptor parser
require 'rdf/raptor'

require 'pho/etags'
require 'pho/store'
require 'pho/snapshot'
require 'pho/field_predicate_map'
require 'pho/query_profile'
require 'pho/status'
require 'pho/facet'
require 'pho/job'
require 'pho/file_management'
require 'pho/rdf_collection'
require 'pho/file_manager'
require 'pho/resource_hash'
require 'pho/changeset_builder'
require 'pho/changeset'
require 'pho/sparql'
require 'pho/enrichment'
require 'pho/command_line'
require 'pho/oai'
require 'pho/converter'

if RUBY_VERSION < "1.8.7"
  class String
    def start_with?(prefix)
      self.index(prefix) == 0
    end      
  end
end

module Pho

  ACCEPT_RDF = {"Accept" => "application/rdf+xml"}.freeze   
  ACCEPT_JSON = { "Accept" => "application/json" }.freeze
  
  RDF_XML = {"Content-Type"=>"application/rdf+xml"}.freeze
  TURTLE = {"Content-Type"=>"text/turtle"}.freeze
  NTRIPLES = {"Content-Type"=>"text/plain"}.freeze
    
  class Namespaces

    CONFIG = "http://schemas.talis.com/2006/bigfoot/configuration#"
    FRAME = "http://schemas.talis.com/2006/frame/schema#"
    FACET = "http://schemas.talis.com/2007/facet-results#"
    RDF = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    RDFS = "http://www.w3.org/2000/01/rdf-schema#"
    DC = "http://purl.org/dc/elements/1.1/"
    DC_TERMS = "http://purl.org/dc/terms/"
    CHANGESET = "http://purl.org/vocab/changeset/schema#"
    
    MAPPING = {
      "bf" => CONFIG,
      "frm" => FRAME,
      "rdf" => RDF,
      "rdfs" => RDFS,
      "dc" => DC,
      "dcterms" => DC_TERMS,
      "cs" => CHANGESET  
    }
    
  end

end
