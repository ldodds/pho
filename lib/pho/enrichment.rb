module Pho
    
  #Enrichment module. Provides classes and mixins for enriching data held in Platform stores using
  #external SPARQL endpoints and services
  module Enrichment
    
    class StoreEnricher
      
      attr_reader :store
      attr_reader :sparql_client
      
      #Constructor
      #
      #store:: the store containing resource(s) to enrich
      #sparql_client:: SparqlClient object to be used as client for retrieving enrichments
      def initialize(store, sparql_client)
          @store = store
          @sparql_client = sparql_client  
      end

      #Enrich a store against itself
      #
      #For the common case where a store needs to be enriched against itself by inferring new 
      #data from old using a CONSTRUCT query
      #
      #store:: the store to be updated
      #query:: the SPARQL CONSTRUCT query to be used to infer the new data
      def StoreEnricher.infer(store, query, &block)
        enricher = StoreEnricher.new( store, store.sparql_client() )
        return enricher.merge( query, &block )
      end 
            
      #Execute the provided query against the configured SPARQL endpoint and store the results in 
      #the Platform Store
      #
      #query:: the SPARQL CONSTRUCT or DESCRIBE query to execute
      def merge(query)
        resp = @sparql_client.query( query, "application/rdf+xml" )
        if resp.status != 200
           raise "Unable to execute query. Response: #{resp.status} #{resp.reason} #{resp.content}"  
        end
        data = resp.content
        resp = @store.store_data( data )
        if block_given?
          yield resp, data
        end
        
        return resp        
      end
      
      #TODO: optimize POSTs back to the Platform, to deal with large number of resources, e.g. batching
      #TODO: the locator query needs to be run with a LIMIT/OFFSET for large stores
      
      #Enrich a store with data extracted from a SPARQL endpoint.
      #
      #The locator_query is used to find resources in the Platform Store that should be enriched. The query
      #should be a SPARQL SELECT query that returns the data to be used to parameterize the enrichment_query.
      #
      #For each query result, the enrichment_query will be submitted to the configured SPARQL endpoint, after 
      #first interpolating the string, providing the query result bindings as parameters. (See SparqlHelper.apply_initial_bindings 
      #and SparqlHelper.results_to_query_bindings 
      #
      #If successful, the result of each enrichment query will then be pushed back into the Platform Store by 
      #posting the results of the query to the metabox. Enrichment queries should therefore be CONSTRUCT or 
      #DESCRIBE queries. The SPARQL protocol request will be sent with an Accept header of application/rdf+xml
      #
      #The method supports a callback object that can be provided as an optional parameter to the query. If provided then 
      #then object should respond to either or both of the following methods:
      #  pre_process(rdf_xml)
      #  post_process(resp, rdf_xml)
      #The first of these is invoked after each enrichment query has been executed on the configured SPARQL endpoint. It is 
      #intended to support additional filtering or annotation. If the +pre_process+ method returns nil, then no data will be written 
      #to the store, otherwise the return value is substituted instead of the original value.
      #
      #The second callback method, +post_process+ is called after data has been written to the store and provides access to the 
      #response from the store, and the RDF/XML data that had been attempted to be stored. As the request may have been un-successful, 
      #code should check the status on the HTTPMessage parameter.
      #
      #  class MyCallback
      #     def pre_process(rdf)
      #       if !should_store?(rdf)
      #         return nil  
      #       end 
      #       return rdf
      #     end
      #     def post_process(resp, rdf)
      #       puts "Store returned #{resp.status} when storing: #{rdf}"
      #     end
      #  end
      #  callback = MyCallback.new()
      #  enricher.enrich("SELECT ?item WHERE { ?item a ex:Class } LIMIT 10", "DESCRIBE ?item", callback)
      #
      #The callback support is primarily intended to support filtering and notification of activities. For simple logging purposes, the 
      #method also supports a block parameter. This is invoked after each enrichment query, and each store response. The block can 
      #receive two values: the first is a symbol (either +:query+ or +:store+) indicating the source of the response, and the response
      #object itself. E.g:
      #
      #  enricher.enrich("SELECT ?item WHERE { ?item a ex:Class } LIMIT 10", "DESCRIBE ?item") do |source, resp|
      #    if source == :query
      #      puts "Enrichment query returned #{resp.status}"
      #    else
      #      puts "Store returned #{resp.status} when storing data"
      #    end 
      #  end
      #
      #locator_query:: query to locate resources to be enriched
      #enrichment_query:: query to be used to enrich the resource
      #callback:: optional callback object
      def enrich(locator_query, enrichment_query, callback=nil)
          results = Pho::Sparql::SparqlHelper.select(locator_query, @store.sparql_client() )
          bindings = Pho::Sparql::SparqlHelper.results_to_query_bindings(results)
          bindings.each do |binding|
            bound_query = Pho::Sparql::SparqlHelper.apply_initial_bindings(enrichment_query, binding)

            #TODO counting numbers of requests and responses?
            query_response = @sparql_client.query(bound_query, "application/rdf+xml")           
            
            if block_given?
              yield :query, query_response
            end
            
            if query_response.status == 200                            
              result = query_response.content              
              if callback != nil && callback.respond_to?(:pre_process)
                result = callback.pre_process(result)
              end
                                 
              if result != nil                
                store_response = @store.store_data( result )                
                if callback != nil && callback.respond_to?(:post_process)
                  callback.post_process(store_response, result)
                end
                
                if block_given?
                  yield :store, store_response
                end                
              end
              
            end
          #end each binding
          end
      end
      
    end
    
  end
end