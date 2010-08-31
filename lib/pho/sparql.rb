module Pho

  #Module providing a SPARQL client library, support for parsing SPARQL query responses into Ruby objects
  #and other useful behaviour  
  module Sparql

    SPARQL_RESULTS_XML = "application/sparql-results+xml"
    SPARQL_RESULTS_JSON = "application/sparql-results+json"
    
    #Includes all statements along both in-bound and out-bound arc paths
    #
    #See http://n2.talis.com/wiki/Bounded_Descriptions_in_RDF   
    SYMMETRIC_BOUNDED_DESCRIPTION = <<-EOL
    CONSTRUCT {?uri ?p ?o . ?s ?p2 ?uri .} WHERE { {?uri ?p ?o .} UNION {?s ?p2 ?uri .} }
    EOL
    
    #Similar to Concise Bounded Description but includes labels for referenced resources
    #
    #See http://n2.talis.com/wiki/Bounded_Descriptions_in_RDF    
    LABELLED_BOUNDED_DESCRIPTION = <<-EOL
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#> 
    CONSTRUCT {
       ?uri ?p ?o . 
       ?o rdfs:label ?label . 
       ?o rdfs:comment ?comment . 
       ?o <http://www.w3.org/2004/02/skos/core#prefLabel> ?plabel . 
       ?o rdfs:seeAlso ?seealso.
    } WHERE {
      ?uri ?p ?o . 
      OPTIONAL { 
        ?o rdfs:label ?label .
      } 
      OPTIONAL {
        ?o <http://www.w3.org/2004/02/skos/core#prefLabel> ?plabel . 
      } 
      OPTIONAL {
        ?o rdfs:comment ?comment . 
      } 
      OPTIONAL { 
        ?o rdfs:seeAlso ?seealso.
      }
    }    
    EOL

    #Derived from both the Symmetric and Labelled Bounded Descriptions. Includes all in-bound
    #and out-bound arc paths, with labels for any referenced resources.
    #
    #See http://n2.talis.com/wiki/Bounded_Descriptions_in_RDF    
    SYMMETRIC_LABELLED_BOUNDED_DESCRIPTION = <<-EOL
    PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#> 
    CONSTRUCT {
      ?uri ?p ?o . 
      ?o rdfs:label ?label . 
      ?o rdfs:comment ?comment . 
      ?o rdfs:seeAlso ?seealso. 
      ?s ?p2 ?uri . 
      ?s rdfs:label ?label . 
      ?s rdfs:comment ?comment . 
      ?s rdfs:seeAlso ?seealso.
    } WHERE { 
      { ?uri ?p ?o . 
        OPTIONAL { 
          ?o rdfs:label ?label .
        } 
        OPTIONAL {
          ?o rdfs:comment ?comment .
        } 
        OPTIONAL {
          ?o rdfs:seeAlso ?seealso.
        } 
      } 
      UNION {
        ?s ?p2 ?uri . 
        OPTIONAL {
          ?s rdfs:label ?label .
        } 
        OPTIONAL {
          ?s rdfs:comment ?comment .
        } 
        OPTIONAL {
          ?s rdfs:seeAlso ?seealso.
        } 
      } 
    }    
    EOL

    DESCRIPTIONS = {
      :cbd => "DESCRIBE ?uri",
      :scbd => SYMMETRIC_BOUNDED_DESCRIPTION,
      :lcbd => LABELLED_BOUNDED_DESCRIPTION,
      :slcbd => SYMMETRIC_LABELLED_BOUNDED_DESCRIPTION
    }      
    
    #A simple SPARQL client that handles the basic HTTP traffic
    class SparqlClient
      
        #URI of the endpoint
        attr_reader :endpoint
        #HTTPClient object
        attr_reader :client
        #Name of output parameter to use to control response format. If set then this parameter is added
        #to the query string, rather than using Content Negotiation        
        attr_accessor :output_parameter_name
        attr_reader :graphs
        attr_reader :named_graphs      
        
        #Configures whether the remote endpoint supports the RDF-in-JSON specification for serializing
        #RDF graphs as JSON. Will default to false.
        attr_accessor :supports_rdf_json
        #Configures whether the remote endpoint supports SPARQL JSON Results format
        #Will default to true.        
        attr_accessor :supports_sparql_json
                
        #Initialize a client for a specific endpoint
        #
        #endpoint:: uri of the SPARQL endpoint
        #client:: optionally, a reference to an existing HTTPClient object instance
        def initialize(endpoint, client=HTTPClient.new() )
         @endpoint = endpoint
         @graphs = nil
         @named_graphs = nil
         @client = client
         @output_parameter_name = nil
         @supports_rdf_json = false
         @supports_sparql_json = true
        end 
        
        #Add a default graph. This will be added as a default graph in the request protocol
        def add_default_graph(graph_uri)
          if @graphs == nil
             @graphs = []
          end  
          @graphs << graph_uri
        end

        #Add a named graph. This will be added as a named graph in the request protocol
        def add_named_graph(graph_uri)
          if @named_graphs == nil
            @named_graphs = []
          end  
          @named_graphs << graph_uri
        end
                      
        #Perform a sparql query
        #
        #sparql:: a valid SPARQL query
        #format:: specific a request format. Usually a media-type, but may be a name for a type, if not using Conneg
        #graphs:: an array of default graphs
        #named_graphs:: an array of named graphs
        def query(sparql, format=nil, graphs=nil, named_graphs=nil)
          
          params = {}
          params["query"] = sparql
          
          if graphs != nil
            params["default-graph-uri"] = graphs
          elsif @graphs != nil
            params["default-graph-uri"] = @graphs
          end          

          if named_graphs != nil
            params["named-graph-uri"] = named_graphs
          elsif @named_graphs != nil
            params["named-graph-uri"] = @named_graphs
          end
          
          headers = {}
          if format != nil
            
            if @output_parameter_name != nil
              params[@output_parameter_name] = format
            else 
              headers["Accept"] = format  
            end
            
          end
          
          return @client.get( @endpoint, params, headers )
        end
        
        #Describe a uri, optionally specifying a form of bounded description
        #
        #uri:: the uri to describe
        #format:: mimetype for results
        #type:: symbol indicating type of description, i.e. +:cbd+, +:scbd+, +:lcbd+, or +:slcbd+
        def describe_uri(uri, format="application/rdf+xml", type=:cbd)
          template = Pho::Sparql::DESCRIPTIONS[type]
          if template == nil
            raise "Unknown description type"
          end
          query = Pho::Sparql::SparqlHelper.apply_initial_bindings(template, {"uri" => "<#{uri}>"} )
          return describe(query, format)
        end
        
        #Perform a SPARQL DESCRIBE query.
        #
        #query:: the SPARQL query
        #format:: the preferred response format
        def describe(query, format="application/rdf+xml")
          return query(query, format)
        end

        #DESCRIBE multiple resources in a single query. The provided array should contain
        #the uris that are to be described
        #
        #This will generate a query like:
        # DESCRIBE <http://www.example.org> <http://www.example.com> ...
        #
        #uris:: list of the uris to be described
        #format:: the preferred response format. Default is RDF/XML
        def multi_describe(uris, format="application/rdf+xml")
          query = "DESCRIBE " + uris.map {|u| "<#{u}>" }.join(" ")
          return query(query, format)
        end
              
        #Perform a SPARQL CONSTRUCT query.
        #
        #query:: the SPARQL query
        #format:: the preferred response format        
        def construct(query, format="application/rdf+xml")
          return query(query, format)
        end
        
        #Perform a SPARQL ASK query.
        #
        #query:: the SPARQL query
        #format:: the preferred response format    
        def ask(query, format=Pho::Sparql::SPARQL_RESULTS_XML)
          return query(query, format)
        end
        
        #Perform a SPARQL SELECT query.
        #
        #query:: the SPARQL query
        #format:: the preferred response format    
        def select(query, format=Pho::Sparql::SPARQL_RESULTS_XML)
          return query(query, format)
        end
        
    end
   
    #Simple helper class for manipulating and executing SPARQL queries and manipulating the results
    class SparqlHelper
        VARIABLE_MATCHER = /(\?|\$)([a-zA-Z]+)/
        
        #Apply some initial bindings to parameters in a query
        #
        #The keys in the values hash are used to replace variables in a query
        #The values are supplied as is, allowing them to be provided as URIs, or typed literals
        #according to Turtle syntax.
        #
        #Any keys in the hash that are not in the query are ignored. Any variables not found
        #in the hash remain unbound.
        #
        #query:: the query whose initial bindings are to be set
        #values:: hash of query name to value
        def SparqlHelper.apply_initial_bindings(query, bindings={})
            copy = query.clone()
            copy.gsub!(VARIABLE_MATCHER) do |pattern|
              key = $2
              if bindings.has_key?(key)
                bindings[key].to_s
              else
                pattern
              end              
            end            
            return copy  
        end
        
        #Convert a SPARQL query result binding into a hash suitable for passing
        #to the apply_initial_bindings method.
        #
        #The result param is assumed to be a Ruby hash that reflects the structure of 
        #a binding in a SELECT query result (i.e. the result of parsing the <tt>application/sparql-results+json</tt> 
        #format and extracting an specific result binding.
        #
        #The method is intended to be used to support cases where an initial select query is 
        #performed to extract some variables that can later be plugged into a subsequent 
        #query
        #
        #result:: hash conforming to structure of a <tt>binding</tt> in the SPARQL JSON format
        def SparqlHelper.result_to_query_binding(result)
          hash = {}
          result.each_pair do |key, value|
            if value["type"] == "uri"
              hash[key] = "<#{value["value"]}>"
            elsif (value["type"] == "literal" && !value.has_key?("datatype"))
              hash[key] = "\"#{value["value"]}\""
            elsif (value["type"] == "literal" && value.has_key?("datatype"))
              hash[key] = "\"#{value["value"]}\"^^#{value["datatype"]}"             
            else
              #do nothing for bnodes
            end
          end
          return hash
        end
        
        #Convert Ruby hash structured according to SPARQL JSON format
        #into an array of hashes by calling result_to_query_binding on each binding
        #into the results.
        #
        #E.g:
        #<tt>results = Pho::Sparql::SparqlHelper.select(query, sparql_client)</tt>
        #<tt>bindings = Pho::Sparql::SparqlHelper.results_to_query_bindings(results)</tt>
        #
        #results:: hash conforming to SPARQL SELECT structure
        def SparqlHelper.results_to_query_bindings(results)
          bindings = []
          
          results["results"]["bindings"].each do |result|
            bindings << result_to_query_binding(result)
          end
          return bindings
        end              
        
        #Perform a simple SELECT query on an endpoint.
        #Will request the results using the SPARQL JSON results format, and parse the
        #resulting JSON results. The result will therefore be a simple ruby hash of the results
        #
        #An error will be raised if the response is HTTP OK.
        #
        #query:: the SPARQL SELECT query
        #sparql_client:: a configured SparqlClient object
        def SparqlHelper.select(query, sparql_client)
          #TODO: test whether endpoint supports json, and if not, switch to parsing XML
          resp = sparql_client.select(query, Pho::Sparql::SPARQL_RESULTS_JSON)
          if resp.status != 200
            raise "Error performing sparql query: #{resp.status} #{resp.reason}\n#{resp.content}"
          end
          return JSON.parse( resp.content )
        end
    
        #Performs an ASK query on an endpoint, returing a boolean true/false response
        #
        #Will request the results using the SPARQL JSON results format, parse the
        #resulting JSON results, and extract the true/false response.
        #
        #query:: the SPARQL SELECT query
        #sparql_client:: a configured SparqlClient object
        def SparqlHelper.ask(query, sparql_client)
          json = SparqlHelper.select(query, sparql_client)
          return json["boolean"] == "true"
        end
    
        #Performs an ASK query on the SPARQL endpoint to test whether there are any statements
        #in the triple store about the specified uri.
        #
        #uri:: the uri to test for
        #sparql_client:: a configured SparqlClient object
        def SparqlHelper.exists(uri, sparql_client)
           return SparqlHelper.ask("ASK { <#{uri}> ?p ?o }", sparql_client)  
        end
        
        #Perform a simple SELECT query on an endpoint and return a simple array of values
        #
        #Will request the results using the SPARQL JSON results format, and parse the
        #resulting JSON results. The assumption is that the SELECT query contains a single "column" 
        #of values, which will be returned as an array 
        #
        #Note this will lose any type information, only the value of the bindings are returned 
        #
        #Also note that if row has an empty binding for the selected variable, then this row will
        #be dropped from the resulting array
        #
        #query:: the SPARQL SELECT query
        #sparql_client:: a configured SparqlClient object
        def SparqlHelper.select_values(query, sparql_client)
           results = SparqlHelper.select(query, sparql_client)
           v = results["head"]["vars"][0];
           values = [];
           results["results"]["bindings"].each do |binding|
             values << binding[v]["value"] if binding[v]
           end
           return values           
        end

        #Perform a simple SELECT query on an endpoint and return a single result
        #
        #Will request the results using the SPARQL JSON results format, and parse the
        #resulting JSON results. The assumption is that the SELECT query returns a single
        #value (i.e single variable, with single binding)
        #
        #Note this will lose any type information, only the value of the binding is returned 
        #
        #query:: the SPARQL SELECT query
        #sparql_client:: a configured SparqlClient object                
        def SparqlHelper.select_single_value(query, sparql_client)
          results = SparqlHelper.select(query, sparql_client)
          v = results["head"]["vars"][0];
          return results["results"]["bindings"][0][v]["value"]           
        end
        
        #Perform a SPARQL CONSTRUCT query against an endpoint, requesting the results in JSON 
        #
        #Will request the results as application/json (with the expectation that it returns RDF_JSON), 
        #and parses the resulting JSON document.
        #
        #query:: the SPARQL SELECT query
        #sparql_client:: a configured SparqlClient object                        
        def SparqlHelper.construct_to_resource_hash(query, sparql_client)
          #TODO: test whether endpoint supports json, and if not, switch to parsing XML
          resp = sparql_client.construct(query, "application/json")
          if resp.status != 200
            raise "Error performing sparql query: #{resp.status} #{resp.reason}\n#{resp.content}"
          end
          return Pho::ResourceHash::Converter.parse_json( resp.content )          
        end

        #Perform a SPARQL DESCRIBE query against an endpoint, requesting the results in JSON 
        #
        #Will request the results as application/json (with the expectation that it returns RDF_JSON), 
        #and parses the resulting JSON document.
        #
        #query:: the SPARQL SELECT query
        #sparql_client:: a configured SparqlClient object                                
        def SparqlHelper.describe_to_resource_hash(query, sparql_client)
          #TODO: test whether endpoint supports json, and if not, switch to parsing XML
          resp = sparql_client.describe(query, "application/json")
          if resp.status != 200
            raise "Error performing sparql query: #{resp.status} #{resp.reason}\n#{resp.content}"
          end
          return Pho::ResourceHash::Converter.parse_json( resp.content )          
        end
        
        #DESCRIBE multiple resources in a single SPARQL request
        #
        #uris:: an array of URIs
        #sparql_client:: a configured SparqlClient objec                        
        def SparqlHelper.multi_describe(uris, sparql_client)
          #TODO: test whether endpoint supports json, and if not, switch to parsing XML
          resp = sparql_client.multi_describe(uris, "application/json")
          if resp.status != 200
            raise "Error performing sparql query: #{resp.status} #{resp.reason}\n#{resp.content}"
          end
          return Pho::ResourceHash::Converter.parse_json( resp.content )                    
        end
   
        #Describe a single URI using one of several forms of Bounded Description
        #See SparqlClient.describe_uri
        #
        #uri:: resource to describe
        #sparql_client:: configured SPARQL client
        #type:: form of bounded description to generate
        def SparqlHelper.describe_uri(uri, sparql_client, type=:cbd)
          #TODO: test whether endpoint supports json, and if not, switch to parsing XML
          resp = sparql_client.describe_uri(uri, "application/json", type)
          if resp.status != 200
            raise "Error performing sparql query: #{resp.status} #{resp.reason}\n#{resp.content}"
          end
          return Pho::ResourceHash::Converter.parse_json( resp.content )                              
        end
    end     
        
  end
  
end