module Pho

  require 'pho/sparql'
  
#TODO:
#
# Conditional deletions
# If-Modified-Since support
# Robustness in uri fetching
# Etag Testing
  
  # The Store class acts as a lightweight client interface to the Talis Platform API  
  # (http://n2.talis.com/wiki/Platform_API). The class provides methods for interacting 
  # with each of the core platform services, e.g. retrieving and storing RDF, performing
  # searches, SPARQL queries, etc. 
  # 
  # == Usage
  # 
  #   store = Pho::Store.new("http://api.talis.com/stores/testing", "user", "pass")
  #   store.store_file( File.new("/tmp/example.rdf") )
  #   store.store_url( "http://www.example.org/example.rdf" )
  #   store.describe( "http://www.example.org/thing" )
  #   store.reset
  #
  # == Examples
  #
  # See the examples directory in the distribution 
  class Store
  
    #Retrieve the HTTPClient instance being used by this object
    attr_reader :client
    #Retrieve the admin username configured in this instance
    attr_reader :username
    #Retrieve the base uri of this store
    attr_reader :storeuri
    #Name of store
    attr_reader :name
    
    # Create an instance of the store class
    #
    # storeuri::  base uri for the Platform store to be accessed
    # username::  admin username, may be nil
    # password::  admin password, may be nil
    # client::  an instance of HTTPClient
    def initialize(storeuri, username=nil, password=nil, client = HTTPClient.new() )
      @storeuri = storeuri.chomp("/")
      @name = storeuri.split("/").last
      @username = username
      @password = password
      @client = client
      set_credentials(username, password) if username or password
    end
    
    # Set credentials that this store will use when carrying out authorization
    #
    # username:: admin username
    # password:: admin password    
    def set_credentials(username, password)
      @client.set_auth(@storeuri, username, password)
    end
    
    # Build a request uri, by concatenating it with the base uri of the store
    # uri:: relative URI to store service, e.g. "/service/sparql"
    def build_uri(uri)
      if (uri.start_with?(@storeuri))
        return uri
      end
      if uri.start_with?("/")
        return @storeuri + uri
      else
        return @storeuri + "/" + uri
      end
    end
    
    #############
    # METABOX
    #############
    
    # Store some RDF in the Metabox associated with this store. Default is to store the 
    # data in the metabox, but a private graph name can also be specified.
    
    # data:: a String containing the data to store
    # graph_name:: name of a private graph in which to store the data. E.g. "1" or "private". Resolves to /meta/graphs/graph_name
    # format:: mimetype of RDF serialization
    def store_data(data, graph_name=nil, format="application/rdf+xml")
      u = nil
      if graph_name == nil
        u = build_uri("/meta")
      else 
        u = build_uri("/meta/graphs/#{graph_name}")  
      end
      
      if format == "text/plain"
        format = "text/turtle"
      end
      
      content_type = {"Content-Type"=> format }
      response = @client.post(u, data, content_type )
      return response
    end    
    
    # Store the contents of a File (or any IO stream) in the Metabox associated with this store
    # The client does not support streaming submissions of data, so the stream will be fully read before data is submitted to the platform
    # file:: an IO object  
    # graph_name:: name of a private graph in which to store teh data. E.g. "1" or "private". Resolves to /meta/graphs/graph_name
    # format:: mimetype of RDF serialization
    def store_file(file, graph_name=nil, format="application/rdf+xml")      
      data = file.read()
      file.close()
      return store_data(data, graph_name, format)
    end
    
    # Retrieve RDF data from the specified URL and store it in the Store Metabox
    #
    # An Accept header of "application/rdf+xml" will be sent in the request to support retrieval of RDF from
    # URLs that support Content Negotiation.
    #
    # NOTE: Currently this method doesn't properly handle base uris of retrieved data. i.e. the data isn't parsed
    # and there is no way to pass a base uri to the Platform. Be warned!
    #
    # The default is to store the data in the Metabox. But a private graph name can also be specified
    # u:: the url of the data
    # parameters:: a Hash of url parameters to pass when requesting data from the specified URL
    # graph_name:: name of a private graph in which to store the data. E.g. "1" or "private". Resolves to /meta/graphs/graph_name    
    def store_url(u, parameters=nil, graph_name=nil)
      
      headers = ACCEPT_RDF.clone()
      dataresp = @client.get(u, parameters, headers )
      
      #TODO make this more robust
      if dataresp.status != 200
          throw  
      end
      
      return store_data(dataresp.content, graph_name)
      
    end
  
    # Retrieve an RDF description of a specific URI. The default behaviour will be to retrieve an RDF/XML document, but other formats can be 
    # requested, as supported by the Talis Platform. E.g. application/json 
    #
    # uri:: the URI of the resource to describe
    # format:: the preferred response format
    # etags:: an instance of the Pho::Etags class to support conditional GETs
    # if_match:: specify true to retrieve data only if the version matches a known ETag, false to perform a Conditional GET
    #
    # Note that this method is different from sparql_describe in that it is intended to be used to generate a description of 
    # a single URI, using an separated service exposed by the Platform. This service is optimised for retrieval of descriptions for 
    # single resources and supports HTTP caching and conditional retrieval. The sparql_describe method should be used to submit
    # more complex DESCRIBE queries to the Platform, e.g. to generate descriptions of resources matching a particular graph pattern. 
    def describe(uri, format="application/rdf+xml", etags=nil, if_match=false)
      u = self.build_uri("/meta")
      headers = {"Accept" => format}
      headers = configure_headers_for_conditional_get("#{u}?about=#{uri}", headers, etags, if_match)
      response = @client.get(u, {"about" => uri}, headers )
      record_etags("#{u}?about=#{uri}", etags, response)        
      return response
    end

    # Submit a Changeset to the Platform to update the metabox
    #
    # Default behaviour is to update the metabox with an unversioned name
    # However using the optional parameters, changes can be made versioned, and
    # can also be submitted to private graphs.
    #
    # rdf:: the RDF/XML describing the changes
    # versioned:: true or false to indicate this is a versioned change
    # graph_name:: name of private graph to update instead of metabox
    def submit_changeset(rdf, versioned=false, graph_name=nil)
      uri = "/meta"
      if graph_name != nil
        uri = uri + "/graphs/#{graph_name}"
      end
      uri = uri + "/changesets" if versioned
                
      u = self.build_uri( uri )
      headers = {"Content-Type" => "application/vnd.talis.changeset+xml"}
      response = @client.post(u, rdf, headers)
      return response
    end  
    
    #############
    # SERVICES
    #############
    
    #Retrieve a SparqlClient object for interacting with the endpoint for this store
    #
    # multisparql:: optional, set to true to retrieve client for multisparql endpoint
    def sparql_client(multisparql=false)
      if multisparql
        u = self.build_uri("/services/multisparql")
      else
        u = self.build_uri("/services/sparql")    
      end
      
      sparql_client = StoreSparqlClient.new(self, u, @client)
      sparql_client.supports_rdf_json = true
      sparql_client.supports_sparql_json = true
      
      return sparql_client      
    end
    
    #Perform a SPARQL DESCRIBE query.
    #
    # query:: the SPARQL query
    # format:: the preferred response format
    def sparql_describe(query, format="application/rdf+xml", multisparql=false)
      return sparql(query, format, multisparql)
    end

    #Perform a SPARQL CONSTRUCT query.
    #
    # query:: the SPARQL query
    # format:: the preferred response format        
    def sparql_construct(query, format="application/rdf+xml", multisparql=false)
      return sparql(query, format, multisparql)
    end
    
    #Perform a SPARQL ASK query.
    #
    # query:: the SPARQL query
    # format:: the preferred response format    
    def sparql_ask(query, format="application/sparql-results+xml", multisparql=false)
      return sparql(query, format, multisparql)
    end
    
    #Perform a SPARQL SELECT query.
    #
    # query:: the SPARQL query
    # format:: the preferred response format    
    def sparql_select(query, format="application/sparql-results+xml", multisparql=false)
      return sparql(query, format, multisparql)
    end
    
    #Perform a SPARQL query
    #
    # query:: the SPARQL query
    # format:: the preferred response format
    # multisparql:: use default sparql service or multisparql service
    def sparql(query, format=nil, multisparql=false)
      return sparql_client(multisparql).query(query, format)              
    end    
    
    # Search the Metabox indexes.
    #
    # query:: the query to perform. See XXXX for query syntax
    # params:: additional query parameters (see below)
    #
    # The _params_ hash can contain the following values:
    # * *max*: The maximum number of results to return (default is 10)
    # * *offset*: Offset into the query results (for paging; default is 0)
    # * *sort*: ordered list of fields to be used when applying sorting    
    # * *xsl-uri*: URL of an XSLT transform to be applied to the results, transforming the default RSS 1.0 results format into an alternative representation    
    # * *content-type*: when applying an XSLT transform, the content type to use when returning the results
    #
    # Any additional entries in the _params_ hash will be passed through to the Platform. 
    # These parameters will only be used when an XSLT transformation is being applied, in which case they 
    # will be provided as parameters to the stylesheet. 
    def search(query, params=nil)
      u = self.build_uri("/items")
      search_params = get_search_params(u, query, params)
      response = @client.get(u, search_params)
      return response
      
    end
    
    # Perform a facetted search against the Metabox indexes.
    #
    # query:: the query to perform. See XXXX for query syntax
    # facets:: an ordered list of facets to be used
    # params:: additional query parameters (see below)
    #
    # The _params_ hash can contain the following values:
    # * *top*: the maximum number of results to return for each facet
    # * *output*: the preferred response format, can be html or xml (the default)
    def facet(query, facets, params=nil)
      if facets == nil or facets.empty?
        #todo
        throw
      end
      u = self.build_uri("/services/facet")      
      search_params = get_search_params(u, query, params)
      search_params["fields"] = facets.join(",")
      response = @client.get(u, search_params)
      return response                             
    end
        
    def get_search_params(u, query, params)
      if params != nil
        search_params = params.clone()
      else
        search_params = Hash.new  
      end
      search_params["query"] = query
      return search_params      
    end
    
    # Augment an RSS feed that can be retrieved from the specified URL, against data in this store
    #
    # uri:: the URL for the RSS 1.0 feed
    def augment_uri(uri)
      u = self.build_uri("/services/augment")
      response = @client.get(u, {"data-uri" => uri})
      return response          
    end
    
    # Augment an RSS feed against data int this store by POSTing it to the Platform
    #
    # data:: a String containing the RSS feed
    def augment(data)
      u = self.build_uri("/services/augment")
      response = @client.post(u, data, {"Content-Type" => "application/rss+xml"})
      return response
    end
        
    #Added appropriate http header for conditional get requests
    def configure_headers_for_conditional_get(u, headers, etags, if_match)
      if etags != nil && etags.has_tag?(u)
         if if_match
           headers["If-Match"] = etags.get(u)  
         else
           headers["If-None-Match"] = etags.get(u)
         end                  
      end
      return headers      
    end
            
    def record_etags(u, etags, response)
      if (etags != nil && response.status = 200)        
        etags.add_from_response(u, response)  
      end      
    end
   
    
    #############
    # CONTENTBOX
    #############
        
    # Store an item in the Contentbox for this store
    #
    # f:: a File or other IO object from which data will be read
    # mimetype:: the mimetype of the object to record in the Platform
    # uri:: the URI at which to store the item (relative to base uri for the store). If nil, then a URI will be assigned by the Platform
    #
    # When a _uri_ is not specified, then the Platform will return a 201 Created response with a Location header containing the URI of the 
    # newly stored item. If a URI is specified then a successful request will result in a 200 OK response.
    def upload_item(f, mimetype, uri=nil)
      data = f.read()
      f.close()
      headers = {"Content-Type" => mimetype}
      
      if uri == nil
        u = self.build_uri("/items")        
        response = @client.post(u, data, headers)
      else
        if !uri.start_with?(@storeuri)
          if uri.start_with?("/")
            uri = build_uri("/items#{uri}")
          else  
            uri = build_uri("/items/#{uri}")
          end
          
        end
        response = @client.put(uri, data, headers)
      end      
      return response
    end
   
    # Delete an item from the Contentbox in this Store
    # uri:: the URL of the item, can be relative
    # TODO: conditional deletes
    def delete_item(uri)
      if !uri.start_with?(@storeuri)
        uri = build_uri(uri)
      end
      return @client.delete(uri)
    end    
    
    # Get an item from the Contebtbox. 
    # uri:: the URL of the item, can be relative.
    # 
    # If the provided URL of the item is not in the Contentbox, then the response will be a redirect to the 
    # RDF description of this item, as available from the Metabox.
    #
    # TODO: document etags, redirects
    def get_item(uri, etags=nil, if_match=false)
      u = self.build_uri(uri)
      headers = Hash.new
      headers = configure_headers_for_conditional_get("#{u}", headers, etags, if_match)      
      response = @client.get(u, nil, headers)
      record_etags("#{u}", etags, response)
      return response
    end
    
    #############
    # JOBS
    #############
    
    #Retrieve metadata about a single job. Use Job.read_from_store as a convenience function
    #which will return a fully-populated Job object
    #
    #uri:: the uri of the job to retrieve
    def get_job(uri)
      u = self.build_uri(uri)
      response = @client.get(u, nil, ACCEPT_RDF)
      return response
    end  
    
    #Retrieve metadata about the Scheduled Jobs Collection from the store
    def get_jobs()
      u = self.build_uri("/jobs")
      response = @client.get(u, nil, ACCEPT_RDF)
      return response
    end
    
    #Submit a job to the platform.
    #
    #data:: RDF/XML representing the job request. See methods on Jobs class          
    def submit_job(data)
        u = build_uri("/jobs")
        response = @client.post(u, data, RDF_XML )
        return response          
    end
    
    #############
    # ADMIN
    #############
    
    def get_status()
      u = build_uri("/config/access-status")
      response = @client.get(u, nil, ACCEPT_JSON )
      return response
    end
   
    # Retrieve the list of snapshots for this store
    #
    # Currently the response will contain an HTML document. Use Snapshot.parse to turn this into
    # a Snapshot object
    def get_snapshots()
      u = build_uri("/snapshots")
      response = @client.get(u, nil, ACCEPT_RDF)
      return response      
    end              

    #############
    # OAI
    #############
    
    def list_records(from=nil, to=nil, resumption_token=nil)      
      u = build_uri("/services/oai-pmh")
      params = {"verb" => "ListRecords", "metadataPrefix" => "oai_dc"}
      if from != nil
        params["from"] = from.strftime("%Y-%m-%dT%H:%M:%SZ") if from.respond_to? :strftime
        params["from"] = from.to_s if !from.respond_to? :strftime
      end
      if to != nil
        params["until"] = to.strftime("%Y-%m-%dT%H:%M:%SZ") if to.respond_to? :strftime
        params["until"] = to.to_s if !to.respond_to? :strftime
      end
      params["resumptionToken"] = resumption_token if resumption_token != nil
      response = @client.get(u, params)
      return response
    end
        
    #############
    # CONFIG
    #############
   
    #Read the field predicate map configuration for this store. The config can be requested in any 
    #format supported by the platform, but the default will return JSON. See FieldPredicateMap.read_from_store 
    #for a convenient way to quickly create a FieldPredicateMap object based on a specific stores's configuration.
    #
    #output:: mimetype to use in request     
    def get_field_predicate_map(output=ACCEPT_JSON)
      u = build_uri("/config/fpmaps/1")
      response = @client.get(u, nil, output)
      return response                  
    end
    
    #Update/replace the current Field Predicate map configuration in the store. Assumes that the provided 
    #data is valid RDF/XML. Use FieldPredicateMap.upload as a convenience function
    #
    #data:: a string containing an RDF/XML document 
    def put_field_predicate_map(data)
      u = build_uri("/config/fpmaps/1")
      headers = {"Content-Type" => "application/rdf+xml"}
      return @client.put(u, data, headers)           
    end
    
    #Read the query profile configuration for this store. The config can be requested in any 
    #format supported by the platform, but the default will return JSON. See QueryProfile.read_from_store 
    #for a convenient way to quickly create a QueryProfile object based on a specific stores's configuration.
    #
    #output:: mimetype to use in request     
    def get_query_profile(output=ACCEPT_JSON)
      u = build_uri("/config/queryprofiles/1")
      response = @client.get(u, nil, output)
      return response                  
    end

    #Update/replace the current Query Profile configuration in the store. Assumes that the provided 
    #data is valid RDF/XML. Use QueryProfile.upload as a convenience function
    #
    #data:: a string containing an RDF/XML document 
    def put_query_profile(data)
      u = build_uri("/config/queryprofiles/1")
      headers = {"Content-Type" => "application/rdf+xml"}
      return @client.put(u, data, headers)           
    end        
    
  end

  class StoreSparqlClient < Pho::Sparql::SparqlClient
     
    def initialize(store, endpoint, client=HTTPClient.new() )
      super(endpoint, client)
      @store = store
    end

    #Override default behaviour to use the Stores Describe service instead
    #when requesting CBDs        
    def describe_uri(uri, format="application/rdf+xml", type=:cbd)
      if type == :cbd
        return @store.describe(uri, format)
      else
        return super
      end
    end
    
  end
  
end